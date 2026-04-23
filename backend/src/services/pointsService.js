const db = require('../config/database');
const redis = require('../config/redis');

const RARITY_BASE_POINTS = {
  common: 10,
  uncommon: 25,
  rare: 75,
  epic: 200,
  legendary: 500,
};

/**
 * Calculate points for a sighting and award them to the user.
 * Returns { pointsAwarded, multipliers }.
 */
async function calculateAndAwardPoints(userId, animal, sightingId, capturedAt) {
  const captureDate = new Date(capturedAt);
  const hour = captureDate.getUTCHours();

  let basePoints = animal.base_points || RARITY_BASE_POINTS[animal.rarity] || 10;
  const multipliers = [];

  // Fetch previous catches of this species by this user
  const catchRes = await db.query(
    'SELECT total_catches FROM user_collection WHERE user_id = $1 AND animal_id = $2',
    [userId, animal.id]
  );
  const previousCatches = catchRes.rows[0]?.total_catches || 0;

  // First time catching species: 2x
  if (previousCatches === 0) {
    multipliers.push({ type: 'first_catch', factor: 2.0 });
  }

  // Point decay: -20% after 10th catch of same species
  if (previousCatches >= 10) {
    multipliers.push({ type: 'species_decay', factor: 0.8 });
  }

  // Night sighting (8pm–5am UTC)
  if (hour >= 20 || hour < 5) {
    multipliers.push({ type: 'night_sighting', factor: 1.2 });
  }

  // Daily first catch: 1.5x — check if user has a sighting today already
  const todayStart = new Date(captureDate);
  todayStart.setUTCHours(0, 0, 0, 0);
  const todayEnd = new Date(todayStart);
  todayEnd.setUTCDate(todayEnd.getUTCDate() + 1);

  const dailyCatchRes = await db.query(
    `SELECT id FROM sightings
     WHERE user_id = $1
       AND captured_at >= $2
       AND captured_at < $3
       AND id != $4
     LIMIT 1`,
    [userId, todayStart.toISOString(), todayEnd.toISOString(), sightingId]
  );
  if (dailyCatchRes.rows.length === 0) {
    multipliers.push({ type: 'daily_first', factor: 1.5 });
  }

  // Apply all multipliers
  const totalFactor = multipliers.reduce((acc, m) => acc * m.factor, 1.0);
  const pointsAwarded = Math.round(basePoints * totalFactor);

  // Update sighting record
  await db.query(
    'UPDATE sightings SET points_awarded = $1, multipliers_applied = $2 WHERE id = $3',
    [pointsAwarded, JSON.stringify(multipliers), sightingId]
  );

  // Update user points
  await db.query(
    'UPDATE users SET total_points = total_points + $1, weekly_points = weekly_points + $1 WHERE id = $2',
    [pointsAwarded, userId]
  );

  // Update Redis leaderboard sorted sets
  try {
    const userRes = await db.query('SELECT username, country_code, region FROM users WHERE id = $1', [userId]);
    const user = userRes.rows[0];
    if (user) {
      const weekKey = getWeekKey();
      const globalKey = `leaderboard:weekly:global:${weekKey}`;
      await redis.zincrby(globalKey, pointsAwarded, userId);
      if (user.country_code) {
        await redis.zincrby(`leaderboard:weekly:country:${user.country_code}:${weekKey}`, pointsAwarded, userId);
      }
      if (user.region) {
        await redis.zincrby(`leaderboard:weekly:region:${user.region}:${weekKey}`, pointsAwarded, userId);
      }
      // Set expiry on weekly keys — 14 days
      await redis.expire(globalKey, 14 * 24 * 3600);
    }
  } catch (redisErr) {
    console.error('Redis leaderboard update failed:', redisErr.message);
  }

  return { pointsAwarded, multipliers };
}

/**
 * Update user's streak based on today's activity.
 */
async function updateStreak(userId, captureDate) {
  const today = new Date(captureDate);
  today.setUTCHours(0, 0, 0, 0);

  const userRes = await db.query(
    'SELECT current_streak, longest_streak, last_active_date FROM users WHERE id = $1',
    [userId]
  );
  const user = userRes.rows[0];
  if (!user) return;

  const lastActive = user.last_active_date ? new Date(user.last_active_date) : null;
  let newStreak = user.current_streak || 0;

  if (lastActive) {
    const lastActiveDay = new Date(lastActive);
    lastActiveDay.setUTCHours(0, 0, 0, 0);
    const diffDays = Math.round((today - lastActiveDay) / 86400000);

    if (diffDays === 0) {
      // Same day — no change
      return;
    } else if (diffDays === 1) {
      // Consecutive day
      newStreak += 1;
    } else {
      // Streak broken
      newStreak = 1;
    }
  } else {
    newStreak = 1;
  }

  const longestStreak = Math.max(newStreak, user.longest_streak || 0);

  await db.query(
    'UPDATE users SET current_streak = $1, longest_streak = $2, last_active_date = $3 WHERE id = $4',
    [newStreak, longestStreak, today.toISOString().split('T')[0], userId]
  );

  return newStreak;
}

function getWeekKey() {
  const now = new Date();
  const day = now.getUTCDay();
  const diff = now.getUTCDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(now.setUTCDate(diff));
  return monday.toISOString().split('T')[0];
}

module.exports = { calculateAndAwardPoints, updateStreak, RARITY_BASE_POINTS };
