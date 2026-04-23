require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const app = require('./app');
const db = require('./config/database');
const redis = require('./config/redis');
const { seedAchievements } = require('./services/achievementService');

const PORT = parseInt(process.env.PORT, 10) || 3000;

/**
 * Weekly leaderboard reset — runs every Monday at 00:00 UTC.
 * 1. Snapshots the current weekly leaderboard into leaderboard_snapshots.
 * 2. Resets users.weekly_points to 0.
 * 3. Deletes all leaderboard:weekly:* Redis keys for the closed week.
 *
 * Implemented as an in-process interval for the MVP. In production, replace
 * with a dedicated cron service (e.g. pg_cron, Railway Cron Jobs) so the
 * reset is not tied to server restarts.
 */
function scheduleWeeklyReset() {
  const MONDAY = 1; // getUTCDay() index for Monday

  function msUntilNextMonday() {
    const now = new Date();
    const daysUntilMonday = (7 - now.getUTCDay() + MONDAY) % 7 || 7;
    const next = new Date(Date.UTC(
      now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysUntilMonday,
      0, 0, 0, 0,
    ));
    return next - now;
  }

  async function doReset() {
    const weekStart = new Date();
    weekStart.setUTCDate(weekStart.getUTCDate() - 7);
    weekStart.setUTCHours(0, 0, 0, 0);
    const weekStartStr = weekStart.toISOString().slice(0, 10);

    try {
      // Snapshot global weekly leaderboard
      const users = await db.query(
        'SELECT id, weekly_points, (SELECT COUNT(*) FROM sightings WHERE user_id = users.id AND submitted_at >= $1) AS catches FROM users WHERE weekly_points > 0 ORDER BY weekly_points DESC',
        [weekStart.toISOString()]
      );

      if (users.rows.length > 0) {
        const values = users.rows.map((u, idx) =>
          `('${u.id}', '${weekStartStr}', ${idx + 1}, ${u.weekly_points}, ${u.catches}, 'global', 'global')`
        ).join(',');
        await db.query(
          `INSERT INTO leaderboard_snapshots (user_id, week_start, rank, points, catches, scope, scope_value) VALUES ${values} ON CONFLICT DO NOTHING`
        );
      }

      // Reset weekly_points in Postgres
      await db.query('UPDATE users SET weekly_points = 0');

      // Delete weekly Redis keys
      const keys = await redis.keys(`leaderboard:weekly:*:${weekStartStr}`);
      if (keys.length > 0) {
        await redis.del(...keys);
      }

      console.log(`Weekly leaderboard reset complete (week starting ${weekStartStr}, ${users.rows.length} users snapshotted)`);
    } catch (err) {
      console.error('Weekly leaderboard reset failed:', err.message);
    }

    // Schedule next reset
    setTimeout(doReset, msUntilNextMonday());
  }

  // Schedule first reset
  setTimeout(doReset, msUntilNextMonday());
  console.log(`Weekly leaderboard reset scheduled (next: ${new Date(Date.now() + msUntilNextMonday()).toUTCString()})`);
}

async function start() {
  // Verify DB connection
  try {
    await db.query('SELECT 1');
    console.log('PostgreSQL connected');
  } catch (err) {
    console.error('PostgreSQL connection failed:', err.message);
    process.exit(1);
  }

  // Connect Redis
  try {
    await redis.connect();
  } catch (err) {
    console.warn('Redis connection failed (non-fatal):', err.message);
  }

  // Ensure achievements exist
  try {
    await seedAchievements();
    console.log('Achievements seeded');
  } catch (err) {
    console.warn('Achievement seeding failed:', err.message);
  }

  scheduleWeeklyReset();

  app.listen(PORT, () => {
    console.log(`WildSnap API running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
  });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received — shutting down gracefully');
  await redis.quit();
  await db.pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  await redis.quit();
  await db.pool.end();
  process.exit(0);
});

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
