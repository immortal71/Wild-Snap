const express = require('express');
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/challenges/active — return currently active challenges with user progress
router.get('/active', authenticate, async (req, res, next) => {
  try {
    const now = new Date().toISOString();
    const result = await db.query(
      `SELECT c.*,
              uc.progress,
              uc.completed,
              uc.completed_at
       FROM challenges c
       LEFT JOIN user_challenges uc
         ON uc.challenge_id = c.id AND uc.user_id = $1
       WHERE c.is_active = TRUE
         AND c.starts_at <= $2
         AND c.ends_at >= $2
       ORDER BY c.ends_at ASC`,
      [req.user.id, now]
    );

    return res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/challenges/:id — single challenge with user progress
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT c.*,
              uc.progress,
              uc.completed,
              uc.completed_at
       FROM challenges c
       LEFT JOIN user_challenges uc
         ON uc.challenge_id = c.id AND uc.user_id = $1
       WHERE c.id = $2`,
      [req.user.id, req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Challenge not found' });
    }

    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/challenges/:id/progress — increment progress after a qualifying sighting
// Called internally by the sightings route; also exposed so clients can trigger a sync.
router.post('/:id/progress', authenticate, async (req, res, next) => {
  try {
    const challengeRes = await db.query(
      `SELECT * FROM challenges WHERE id = $1 AND is_active = TRUE AND starts_at <= NOW() AND ends_at >= NOW()`,
      [req.params.id]
    );
    const challenge = challengeRes.rows[0];
    if (!challenge) {
      return res.status(404).json({ success: false, error: 'Active challenge not found' });
    }

    // Upsert progress row
    const upsertRes = await db.query(
      `INSERT INTO user_challenges (user_id, challenge_id, progress, completed)
       VALUES ($1, $2, 1, FALSE)
       ON CONFLICT (user_id, challenge_id) DO UPDATE
         SET progress = CASE
           WHEN user_challenges.completed THEN user_challenges.progress
           ELSE user_challenges.progress + 1
         END
       RETURNING *`,
      [req.user.id, challenge.id]
    );
    const uc = upsertRes.rows[0];

    // Check completion
    let justCompleted = false;
    if (!uc.completed && uc.progress >= challenge.required_count) {
      await db.query(
        `UPDATE user_challenges SET completed = TRUE, completed_at = NOW()
         WHERE user_id = $1 AND challenge_id = $2`,
        [req.user.id, challenge.id]
      );
      // Award bonus points
      if (challenge.bonus_points > 0) {
        await db.query(
          'UPDATE users SET total_points = total_points + $1, weekly_points = weekly_points + $1 WHERE id = $2',
          [challenge.bonus_points, req.user.id]
        );
      }
      justCompleted = true;
    }

    return res.json({
      success: true,
      data: {
        challenge_id: challenge.id,
        progress: uc.progress,
        required_count: challenge.required_count,
        completed: justCompleted || uc.completed,
        bonus_points_awarded: justCompleted ? challenge.bonus_points : 0,
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
