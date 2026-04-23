const express = require('express');
const db = require('../config/database');
const redis = require('../config/redis');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

/**
 * Fetch leaderboard from Redis sorted set + enrich with user data.
 * @param {string} key - Redis key
 * @param {number} limit
 * @returns {Promise<Array>}
 */
async function getLeaderboardFromRedis(key, limit = 100) {
  const entries = await redis.zrevrange(key, 0, limit - 1, 'WITHSCORES');
  if (!entries || entries.length === 0) return [];

  const leaderboard = [];
  for (let i = 0; i < entries.length; i += 2) {
    leaderboard.push({ user_id: entries[i], points: parseInt(entries[i + 1], 10) });
  }

  if (leaderboard.length === 0) return [];

  const userIds = leaderboard.map((e) => e.user_id);
  const placeholders = userIds.map((_, idx) => `$${idx + 1}`).join(',');
  const usersRes = await db.query(
    `SELECT id, username, avatar_url, country_code, region FROM users WHERE id IN (${placeholders})`,
    userIds
  );
  const usersMap = Object.fromEntries(usersRes.rows.map((u) => [u.id, u]));

  return leaderboard
    .map((entry, idx) => ({
      rank: idx + 1,
      ...entry,
      user: usersMap[entry.user_id] || null,
    }))
    .filter((e) => e.user !== null);
}

/**
 * Fetch leaderboard directly from DB (alltime or fallback).
 */
async function getLeaderboardFromDB({ scope, scopeValue, period, limit = 100 }) {
  let orderColumn = period === 'alltime' ? 'total_points' : 'weekly_points';
  const conditions = [];
  const values = [];
  let idx = 1;

  if (scope === 'country' && scopeValue) {
    conditions.push(`country_code = $${idx++}`);
    values.push(scopeValue);
  } else if (scope === 'region' && scopeValue) {
    conditions.push(`region = $${idx++}`);
    values.push(scopeValue);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  values.push(limit);

  const result = await db.query(
    `SELECT id, username, avatar_url, country_code, region, total_points, weekly_points,
            ROW_NUMBER() OVER (ORDER BY ${orderColumn} DESC) AS rank
     FROM users
     ${where}
     ORDER BY ${orderColumn} DESC
     LIMIT $${idx}`,
    values
  );

  return result.rows.map((u) => ({
    rank: parseInt(u.rank, 10),
    user_id: u.id,
    points: parseInt(period === 'alltime' ? u.total_points : u.weekly_points, 10),
    user: {
      id: u.id,
      username: u.username,
      avatar_url: u.avatar_url,
      country_code: u.country_code,
      region: u.region,
    },
  }));
}

// GET /api/leaderboard/global?period=weekly|alltime
router.get('/global', authenticate, async (req, res, next) => {
  try {
    const period = req.query.period === 'alltime' ? 'alltime' : 'weekly';

    let leaderboard;
    if (period === 'weekly') {
      leaderboard = await getLeaderboardFromRedis('leaderboard:weekly:global');
      if (leaderboard.length === 0) {
        leaderboard = await getLeaderboardFromDB({ period: 'weekly', limit: 100 });
      }
    } else {
      leaderboard = await getLeaderboardFromDB({ period: 'alltime', limit: 100 });
    }

    return res.json({ success: true, data: { period, leaderboard } });
  } catch (err) {
    next(err);
  }
});

// GET /api/leaderboard/country/:code
router.get('/country/:code', authenticate, async (req, res, next) => {
  try {
    const code = req.params.code.toUpperCase();
    const period = req.query.period === 'alltime' ? 'alltime' : 'weekly';

    let leaderboard;
    if (period === 'weekly') {
      leaderboard = await getLeaderboardFromRedis(`leaderboard:weekly:country:${code}`);
      if (leaderboard.length === 0) {
        leaderboard = await getLeaderboardFromDB({ scope: 'country', scopeValue: code, period: 'weekly' });
      }
    } else {
      leaderboard = await getLeaderboardFromDB({ scope: 'country', scopeValue: code, period: 'alltime' });
    }

    return res.json({ success: true, data: { period, country_code: code, leaderboard } });
  } catch (err) {
    next(err);
  }
});

// GET /api/leaderboard/region/:name
router.get('/region/:name', authenticate, async (req, res, next) => {
  try {
    const regionName = req.params.name;
    const period = req.query.period === 'alltime' ? 'alltime' : 'weekly';

    let leaderboard;
    if (period === 'weekly') {
      leaderboard = await getLeaderboardFromRedis(`leaderboard:weekly:region:${regionName}`);
      if (leaderboard.length === 0) {
        leaderboard = await getLeaderboardFromDB({ scope: 'region', scopeValue: regionName, period: 'weekly' });
      }
    } else {
      leaderboard = await getLeaderboardFromDB({ scope: 'region', scopeValue: regionName, period: 'alltime' });
    }

    return res.json({ success: true, data: { period, region: regionName, leaderboard } });
  } catch (err) {
    next(err);
  }
});

// GET /api/leaderboard/friends
router.get('/friends', authenticate, async (req, res, next) => {
  try {
    const period = req.query.period === 'alltime' ? 'alltime' : 'weekly';
    const orderColumn = period === 'alltime' ? 'u.total_points' : 'u.weekly_points';

    const result = await db.query(
      `SELECT u.id, u.username, u.avatar_url, u.country_code, u.region,
              u.total_points, u.weekly_points,
              ROW_NUMBER() OVER (ORDER BY ${orderColumn} DESC) AS rank
       FROM follows f
       JOIN users u ON f.following_id = u.id
       WHERE f.follower_id = $1
       UNION ALL
       SELECT u.id, u.username, u.avatar_url, u.country_code, u.region,
              u.total_points, u.weekly_points,
              0 AS rank
       FROM users u
       WHERE u.id = $1
       ORDER BY ${period === 'alltime' ? 'total_points' : 'weekly_points'} DESC
       LIMIT 100`,
      [req.user.id]
    );

    // Re-rank after union
    const ranked = result.rows.map((u, idx) => ({
      rank: idx + 1,
      user_id: u.id,
      points: parseInt(period === 'alltime' ? u.total_points : u.weekly_points, 10),
      user: {
        id: u.id,
        username: u.username,
        avatar_url: u.avatar_url,
        country_code: u.country_code,
        region: u.region,
      },
    }));

    return res.json({ success: true, data: { period, leaderboard: ranked } });
  } catch (err) {
    next(err);
  }
});

// GET /api/leaderboard/me/rank
router.get('/me/rank', authenticate, async (req, res, next) => {
  try {
    const userRes = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    const user = userRes.rows[0];
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    // Global weekly rank from Redis
    let weeklyRank = null;
    try {
      const redisRank = await redis.zrevrank('leaderboard:weekly:global', req.user.id);
      weeklyRank = redisRank !== null ? redisRank + 1 : null;
    } catch (_) {}

    // Fallback from DB
    if (weeklyRank === null) {
      const rankRes = await db.query(
        `SELECT COUNT(*) + 1 AS rank FROM users WHERE weekly_points > $1`,
        [user.weekly_points]
      );
      weeklyRank = parseInt(rankRes.rows[0].rank, 10);
    }

    const alltimeRankRes = await db.query(
      `SELECT COUNT(*) + 1 AS rank FROM users WHERE total_points > $1`,
      [user.total_points]
    );
    const alltimeRank = parseInt(alltimeRankRes.rows[0].rank, 10);

    // Country rank
    let countryRank = null;
    if (user.country_code) {
      const cRankRes = await db.query(
        `SELECT COUNT(*) + 1 AS rank FROM users WHERE country_code = $1 AND total_points > $2`,
        [user.country_code, user.total_points]
      );
      countryRank = parseInt(cRankRes.rows[0].rank, 10);
    }

    return res.json({
      success: true,
      data: {
        weekly_rank: weeklyRank,
        alltime_rank: alltimeRank,
        country_rank: countryRank,
        weekly_points: user.weekly_points,
        total_points: user.total_points,
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
