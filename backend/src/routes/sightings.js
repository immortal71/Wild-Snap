const express = require('express');
const multer = require('multer');
const sharp = require('sharp');
const db = require('../config/database');
const redis = require('../config/redis');
const { authenticate } = require('../middleware/auth');
const { identifyPhoto, matchAnimalFromSuggestions } = require('../services/aiService');
const { calculateAndAwardPoints, updateStreak } = require('../services/pointsService');
const { checkAndAwardAchievements } = require('../services/achievementService');
const { storeFile, deleteFile } = require('../services/storageService');

const router = express.Router();
const MAX_SUBMISSIONS_PER_DAY = parseInt(process.env.MAX_PHOTO_SUBMISSIONS_PER_DAY, 10) || 50;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter(req, file, cb) {
    if (!file.mimetype.startsWith('image/')) {
      return cb(Object.assign(new Error('Only image files are allowed'), { status: 400 }));
    }
    cb(null, true);
  },
});

/**
 * Haversine distance in km between two lat/lng points.
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Check daily rate limit for photo submissions.
 */
async function checkRateLimit(userId) {
  const key = `rate:sightings:${userId}:${new Date().toISOString().split('T')[0]}`;
  const count = await redis.incr(key);
  if (count === 1) {
    await redis.expire(key, 86400);
  }
  return count;
}

/**
 * Anti-cheat: velocity check — if user's last sighting was >1000 km away in <1 hour, reject.
 */
async function velocityCheck(userId, lat, lng, capturedAt) {
  const lastRes = await db.query(
    `SELECT latitude, longitude, captured_at FROM sightings
     WHERE user_id = $1
     ORDER BY captured_at DESC
     LIMIT 1`,
    [userId]
  );
  if (lastRes.rows.length === 0) return true;

  const last = lastRes.rows[0];
  if (!last.latitude || !last.longitude) return true;

  const distKm = haversineKm(
    parseFloat(last.latitude),
    parseFloat(last.longitude),
    parseFloat(lat),
    parseFloat(lng)
  );
  const timeDiffMs = new Date(capturedAt) - new Date(last.captured_at);
  const timeDiffHrs = timeDiffMs / 3600000;

  if (timeDiffHrs < 1 && distKm > 1000) {
    return false;
  }
  return true;
}

/**
 * Core logic: process a single sighting upload.
 */
async function processSighting(userId, fileBuffer, filename, mimetype, body) {
  const { lat, lng, altitude_m, compass_bearing, captured_at, offline_queued = false } = body;

  const capturedAt = captured_at || new Date().toISOString();

  // Velocity check
  if (lat && lng) {
    const valid = await velocityCheck(userId, lat, lng, capturedAt);
    if (!valid) {
      throw Object.assign(new Error('Location data failed velocity check — possible GPS spoofing'), { status: 422 });
    }
  }

  // Generate thumbnail with sharp
  let thumbnailBuffer;
  try {
    thumbnailBuffer = await sharp(fileBuffer).resize(400, 400, { fit: 'inside' }).jpeg({ quality: 70 }).toBuffer();
  } catch (e) {
    thumbnailBuffer = fileBuffer;
  }

  // Store original and thumbnail
  const [photoUrl, thumbnailUrl] = await Promise.all([
    storeFile(fileBuffer, filename, mimetype, 'sightings'),
    storeFile(thumbnailBuffer, `thumb_${filename}`, 'image/jpeg', 'sightings'),
  ]);

  // AI identification
  const { topResult, status: aiStatus, suggestions, rawResponse } = await identifyPhoto(fileBuffer, filename);
  const aiConfidence = topResult ? topResult.score : 0;

  // Match to our animals DB
  let animal = null;
  if (suggestions.length > 0) {
    animal = await matchAnimalFromSuggestions(suggestions, db.query.bind(db));
  }

  // Insert sighting
  const sightingRes = await db.query(
    `INSERT INTO sightings
       (user_id, animal_id, photo_url, thumbnail_url, latitude, longitude,
        altitude_m, compass_bearing, captured_at, ai_confidence, ai_raw_response,
        offline_queued, sync_status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'synced')
     RETURNING *`,
    [
      userId,
      animal?.id || null,
      photoUrl,
      thumbnailUrl,
      lat || null,
      lng || null,
      altitude_m ? parseInt(altitude_m) : null,
      compass_bearing ? parseInt(compass_bearing) : null,
      capturedAt,
      aiConfidence,
      rawResponse ? JSON.stringify(rawResponse) : null,
      offline_queued === true || offline_queued === 'true',
    ]
  );
  const sighting = sightingRes.rows[0];

  let pointsAwarded = 0;
  let multipliers = [];
  let newAchievements = [];
  let currentStreak = 0;

  if (animal) {
    // Award points
    const pointsResult = await calculateAndAwardPoints(userId, animal, sighting.id, capturedAt);
    pointsAwarded = pointsResult.pointsAwarded;
    multipliers = pointsResult.multipliers;

    // Update user collection
    await db.query(
      `INSERT INTO user_collection (user_id, animal_id, first_caught_at, total_catches, best_photo_sighting_id)
       VALUES ($1, $2, $3, 1, $4)
       ON CONFLICT (user_id, animal_id) DO UPDATE
         SET total_catches = user_collection.total_catches + 1,
             best_photo_sighting_id = CASE
               WHEN (SELECT ai_confidence FROM sightings WHERE id = EXCLUDED.best_photo_sighting_id) >
                    (SELECT ai_confidence FROM sightings WHERE id = user_collection.best_photo_sighting_id)
               THEN EXCLUDED.best_photo_sighting_id
               ELSE user_collection.best_photo_sighting_id
             END`,
      [userId, animal.id, capturedAt, sighting.id]
    );

    // Update streak
    currentStreak = await updateStreak(userId, capturedAt) || 0;

    // Check achievements
    newAchievements = await checkAndAwardAchievements(userId, animal, currentStreak);
  }

  return {
    sighting: { ...sighting, points_awarded: pointsAwarded, multipliers_applied: multipliers },
    animal,
    ai: { status: aiStatus, confidence: aiConfidence, suggestions: suggestions.slice(0, 5) },
    points_awarded: pointsAwarded,
    multipliers,
    new_achievements: newAchievements,
    streak: currentStreak,
  };
}

// POST /api/sightings
router.post('/', authenticate, upload.single('photo'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'photo file is required' });
    }

    const submissionCount = await checkRateLimit(req.user.id);
    if (submissionCount > MAX_SUBMISSIONS_PER_DAY) {
      return res.status(429).json({
        success: false,
        error: `Daily photo submission limit of ${MAX_SUBMISSIONS_PER_DAY} reached`,
      });
    }

    const result = await processSighting(
      req.user.id,
      req.file.buffer,
      req.file.originalname,
      req.file.mimetype,
      req.body
    );

    return res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

// GET /api/sightings/nearby
router.get('/nearby', authenticate, async (req, res, next) => {
  try {
    const { lat, lng, radius_km = 10 } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ success: false, error: 'lat and lng are required' });
    }

    const radius = parseFloat(radius_km);
    const latF = parseFloat(lat);
    const lngF = parseFloat(lng);

    // Bounding box approximation then exact Haversine filter
    const latDelta = radius / 111.0;
    const lngDelta = radius / (111.0 * Math.cos((latF * Math.PI) / 180));

    const result = await db.query(
      `SELECT s.*, a.common_name, a.rarity, a.scientific_name,
              u.username, u.avatar_url
       FROM sightings s
       LEFT JOIN animals a ON s.animal_id = a.id
       JOIN users u ON s.user_id = u.id
       WHERE s.latitude BETWEEN $1 AND $2
         AND s.longitude BETWEEN $3 AND $4
         AND s.is_flagged = FALSE
       ORDER BY s.captured_at DESC
       LIMIT 100`,
      [latF - latDelta, latF + latDelta, lngF - lngDelta, lngF + lngDelta]
    );

    // Exact distance filter
    const filtered = result.rows.filter((r) => {
      if (!r.latitude || !r.longitude) return false;
      return haversineKm(latF, lngF, parseFloat(r.latitude), parseFloat(r.longitude)) <= radius;
    });

    return res.json({ success: true, data: filtered });
  } catch (err) {
    next(err);
  }
});

// GET /api/sightings/:id
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT s.*, a.common_name, a.scientific_name, a.rarity, a.description,
              a.habitat, a.base_points, u.username, u.avatar_url
       FROM sightings s
       LEFT JOIN animals a ON s.animal_id = a.id
       JOIN users u ON s.user_id = u.id
       WHERE s.id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Sighting not found' });
    }
    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/sightings/:id
router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    const sightingRes = await db.query('SELECT * FROM sightings WHERE id = $1', [req.params.id]);
    const sighting = sightingRes.rows[0];

    if (!sighting) {
      return res.status(404).json({ success: false, error: 'Sighting not found' });
    }
    if (sighting.user_id !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Not authorized to delete this sighting' });
    }

    // Remove photo files
    if (sighting.photo_url) await deleteFile(sighting.photo_url);
    if (sighting.thumbnail_url) await deleteFile(sighting.thumbnail_url);

    await db.query('DELETE FROM sightings WHERE id = $1', [req.params.id]);

    return res.json({ success: true, data: { message: 'Sighting deleted' } });
  } catch (err) {
    next(err);
  }
});

// POST /api/sightings/:id/flag
router.post('/:id/flag', authenticate, async (req, res, next) => {
  try {
    const result = await db.query(
      'UPDATE sightings SET is_flagged = TRUE WHERE id = $1 RETURNING id',
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Sighting not found' });
    }
    return res.json({ success: true, data: { message: 'Sighting flagged for review' } });
  } catch (err) {
    next(err);
  }
});

// POST /api/sightings/sync — batch offline queue
router.post('/sync', authenticate, async (req, res, next) => {
  try {
    const { items } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, error: 'items array is required' });
    }
    if (items.length > 20) {
      return res.status(400).json({ success: false, error: 'Maximum 20 items per sync batch' });
    }

    const submissionCount = await checkRateLimit(req.user.id);
    if (submissionCount + items.length > MAX_SUBMISSIONS_PER_DAY) {
      return res.status(429).json({
        success: false,
        error: `Batch would exceed daily limit of ${MAX_SUBMISSIONS_PER_DAY} submissions`,
      });
    }

    const results = [];
    for (const item of items) {
      try {
        const { photo, lat, lng, captured_at } = item;
        if (!photo) {
          results.push({ success: false, error: 'photo is required' });
          continue;
        }

        // Accept base64 or URL
        let fileBuffer;
        let filename = 'offline_photo.jpg';
        let mimetype = 'image/jpeg';

        if (photo.startsWith('data:')) {
          const matches = photo.match(/^data:([^;]+);base64,(.+)$/);
          if (!matches) {
            results.push({ success: false, error: 'Invalid base64 photo format' });
            continue;
          }
          mimetype = matches[1];
          fileBuffer = Buffer.from(matches[2], 'base64');
        } else if (photo.startsWith('http')) {
          const axios = require('axios');
          const imgRes = await axios.get(photo, { responseType: 'arraybuffer', timeout: 15000 });
          fileBuffer = Buffer.from(imgRes.data);
          mimetype = imgRes.headers['content-type'] || 'image/jpeg';
        } else {
          // Assume raw base64
          fileBuffer = Buffer.from(photo, 'base64');
        }

        const result = await processSighting(req.user.id, fileBuffer, filename, mimetype, {
          lat, lng, captured_at, offline_queued: true,
        });
        results.push({ success: true, data: result });
      } catch (itemErr) {
        results.push({ success: false, error: itemErr.message });
      }
    }

    return res.json({ success: true, data: { results } });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
