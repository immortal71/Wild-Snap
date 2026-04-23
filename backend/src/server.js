require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const app = require('./app');
const db = require('./config/database');
const redis = require('./config/redis');
const { seedAchievements } = require('./services/achievementService');

const PORT = parseInt(process.env.PORT, 10) || 3000;

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
