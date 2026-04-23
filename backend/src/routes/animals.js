const express = require('express');
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/animals — paginated list with optional filters
router.get('/', authenticate, async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;
    const { category, rarity } = req.query;

    const conditions = [];
    const values = [];
    let idx = 1;

    if (category) {
      conditions.push(`lower(category) = lower($${idx++})`);
      values.push(category);
    }
    if (rarity) {
      conditions.push(`rarity = $${idx++}`);
      values.push(rarity);
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const [dataRes, countRes] = await Promise.all([
      db.query(
        `SELECT * FROM animals ${where} ORDER BY rarity, common_name LIMIT $${idx++} OFFSET $${idx++}`,
        [...values, limit, offset]
      ),
      db.query(`SELECT COUNT(*) FROM animals ${where}`, values),
    ]);

    const total = parseInt(countRes.rows[0].count, 10);
    return res.json({
      success: true,
      data: {
        animals: dataRes.rows,
        pagination: { page, limit, total, pages: Math.ceil(total / limit) },
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/animals/search?q=
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ success: false, error: 'Query must be at least 2 characters' });
    }
    const term = `%${q.trim().toLowerCase()}%`;
    const result = await db.query(
      `SELECT * FROM animals
       WHERE lower(common_name) LIKE $1
          OR lower(scientific_name) LIKE $1
          OR lower(category) LIKE $1
       ORDER BY common_name
       LIMIT 50`,
      [term]
    );
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/animals/nearby?lat=&lng=
router.get('/nearby', authenticate, async (req, res, next) => {
  try {
    const { lat, lng } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ success: false, error: 'lat and lng are required' });
    }

    // Determine country/region from recent sightings near that location
    // For MVP: return animals whose typical_regions include common South Asia regions
    // or animals seen in recent nearby sightings
    const latF = parseFloat(lat);
    const lngF = parseFloat(lng);
    const latDelta = 5; // ~500 km bounding box
    const lngDelta = 5;

    // Get animals recently spotted nearby
    const recentRes = await db.query(
      `SELECT DISTINCT a.* FROM animals a
       JOIN sightings s ON s.animal_id = a.id
       WHERE s.latitude BETWEEN $1 AND $2
         AND s.longitude BETWEEN $3 AND $4
         AND s.is_flagged = FALSE
         AND s.captured_at > NOW() - INTERVAL '30 days'
       LIMIT 30`,
      [latF - latDelta, latF + latDelta, lngF - lngDelta, lngF + lngDelta]
    );

    // If no nearby sightings, return a general selection
    let animals = recentRes.rows;
    if (animals.length < 10) {
      const fallbackRes = await db.query(
        `SELECT * FROM animals ORDER BY RANDOM() LIMIT 20`
      );
      const existingIds = new Set(animals.map((a) => a.id));
      const extra = fallbackRes.rows.filter((a) => !existingIds.has(a.id));
      animals = [...animals, ...extra].slice(0, 30);
    }

    return res.json({ success: true, data: animals });
  } catch (err) {
    next(err);
  }
});

// GET /api/animals/:id
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM animals WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Animal not found' });
    }
    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
