const express = require('express');
const multer = require('multer');
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');
const { storeFile } = require('../services/storageService');
const { createError } = require('../middleware/errorHandler');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB for avatars
  fileFilter(req, file, cb) {
    if (!file.mimetype.startsWith('image/')) {
      return cb(createError(400, 'Only image files are allowed'));
    }
    cb(null, true);
  },
});

function sanitizeUser(user) {
  const { password_hash, ...safe } = user;
  return safe;
}

// GET /api/users/me
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    const user = result.rows[0];
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    return res.json({ success: true, data: sanitizeUser(user) });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/users/me
router.patch('/me', authenticate, upload.single('avatar'), async (req, res, next) => {
  try {
    const { username, country_code, region } = req.body;
    const updates = [];
    const values = [];
    let idx = 1;

    if (username !== undefined) {
      if (username.length < 3 || username.length > 30) {
        return res.status(400).json({ success: false, error: 'Username must be 3–30 characters' });
      }
      if (!/^[a-zA-Z0-9_]+$/.test(username)) {
        return res.status(400).json({ success: false, error: 'Username may only contain letters, numbers and underscores' });
      }
      updates.push(`username = $${idx++}`);
      values.push(username.toLowerCase());
    }

    if (country_code !== undefined) {
      if (country_code && !/^[A-Z]{2}$/.test(country_code.toUpperCase())) {
        return res.status(400).json({ success: false, error: 'country_code must be a 2-letter ISO code' });
      }
      updates.push(`country_code = $${idx++}`);
      values.push(country_code ? country_code.toUpperCase() : null);
    }

    if (region !== undefined) {
      updates.push(`region = $${idx++}`);
      values.push(region || null);
    }

    if (req.file) {
      const avatarUrl = await storeFile(req.file.buffer, req.file.originalname, req.file.mimetype, 'avatars');
      updates.push(`avatar_url = $${idx++}`);
      values.push(avatarUrl);
    }

    if (updates.length === 0) {
      return res.status(400).json({ success: false, error: 'No valid fields to update' });
    }

    values.push(req.user.id);
    const result = await db.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );

    return res.json({ success: true, data: sanitizeUser(result.rows[0]) });
  } catch (err) {
    next(err);
  }
});

// GET /api/users/:username — public profile
router.get('/:username', async (req, res, next) => {
  try {
    const result = await db.query(
      'SELECT id, username, avatar_url, country_code, region, total_points, weekly_points, current_streak, longest_streak, created_at FROM users WHERE lower(username) = lower($1)',
      [req.params.username]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/users/:id/collection
router.get('/:id/collection', authenticate, async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT uc.*, a.common_name, a.scientific_name, a.rarity, a.category,
              a.base_points, a.description, a.silhouette_url, a.reference_image_url,
              s.photo_url AS best_photo_url
       FROM user_collection uc
       JOIN animals a ON uc.animal_id = a.id
       LEFT JOIN sightings s ON uc.best_photo_sighting_id = s.id
       WHERE uc.user_id = $1
       ORDER BY uc.first_caught_at DESC
       LIMIT $2 OFFSET $3`,
      [req.params.id, limit, offset]
    );

    const countRes = await db.query('SELECT COUNT(*) FROM user_collection WHERE user_id = $1', [req.params.id]);
    const total = parseInt(countRes.rows[0].count, 10);

    return res.json({
      success: true,
      data: {
        collection: result.rows,
        pagination: { page, limit, total, pages: Math.ceil(total / limit) },
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/users/:id/achievements
router.get('/:id/achievements', authenticate, async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT a.*, ua.earned_at
       FROM achievements a
       LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = $1
       ORDER BY ua.earned_at DESC NULLS LAST, a.name`,
      [req.params.id]
    );
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/users/:id/sightings
router.get('/:id/sightings', authenticate, async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT s.*, a.common_name, a.scientific_name, a.rarity
       FROM sightings s
       LEFT JOIN animals a ON s.animal_id = a.id
       WHERE s.user_id = $1
       ORDER BY s.captured_at DESC
       LIMIT $2 OFFSET $3`,
      [req.params.id, limit, offset]
    );

    const countRes = await db.query('SELECT COUNT(*) FROM sightings WHERE user_id = $1', [req.params.id]);
    const total = parseInt(countRes.rows[0].count, 10);

    return res.json({
      success: true,
      data: {
        sightings: result.rows,
        pagination: { page, limit, total, pages: Math.ceil(total / limit) },
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
