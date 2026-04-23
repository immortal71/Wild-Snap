const db = require('../config/database');

const ACHIEVEMENT_KEYS = {
  FIRST_CATCH: 'first_catch',
  CATCH_10: 'catch_10',
  CATCH_100: 'catch_100',
  FIRST_RARE: 'first_rare',
  FIRST_EPIC: 'first_epic',
  FIRST_LEGENDARY: 'first_legendary',
  STREAK_7: 'streak_7',
  STREAK_30: 'streak_30',
};

const ACHIEVEMENT_DEFINITIONS = [
  {
    key: ACHIEVEMENT_KEYS.FIRST_CATCH,
    name: 'First Catch!',
    description: 'Photograph your first wild animal.',
    points_reward: 50,
    condition_type: 'total_sightings',
    condition_value: { count: 1 },
  },
  {
    key: ACHIEVEMENT_KEYS.CATCH_10,
    name: 'Budding Naturalist',
    description: 'Log 10 wildlife sightings.',
    points_reward: 100,
    condition_type: 'total_sightings',
    condition_value: { count: 10 },
  },
  {
    key: ACHIEVEMENT_KEYS.CATCH_100,
    name: 'Wildlife Expert',
    description: 'Log 100 wildlife sightings.',
    points_reward: 500,
    condition_type: 'total_sightings',
    condition_value: { count: 100 },
  },
  {
    key: ACHIEVEMENT_KEYS.FIRST_RARE,
    name: 'Rare Find',
    description: 'Photograph your first rare species.',
    points_reward: 150,
    condition_type: 'rarity_catch',
    condition_value: { rarity: 'rare' },
  },
  {
    key: ACHIEVEMENT_KEYS.FIRST_EPIC,
    name: 'Epic Encounter',
    description: 'Photograph your first epic species.',
    points_reward: 300,
    condition_type: 'rarity_catch',
    condition_value: { rarity: 'epic' },
  },
  {
    key: ACHIEVEMENT_KEYS.FIRST_LEGENDARY,
    name: 'Legend in the Making',
    description: 'Photograph your first legendary species.',
    points_reward: 1000,
    condition_type: 'rarity_catch',
    condition_value: { rarity: 'legendary' },
  },
  {
    key: ACHIEVEMENT_KEYS.STREAK_7,
    name: '7-Day Streak',
    description: 'Maintain a 7-day consecutive activity streak.',
    points_reward: 200,
    condition_type: 'streak',
    condition_value: { days: 7 },
  },
  {
    key: ACHIEVEMENT_KEYS.STREAK_30,
    name: '30-Day Streak',
    description: 'Maintain a 30-day consecutive activity streak.',
    points_reward: 1000,
    condition_type: 'streak',
    condition_value: { days: 30 },
  },
];

/**
 * Seed achievements into the DB if they don't exist.
 */
async function seedAchievements() {
  for (const def of ACHIEVEMENT_DEFINITIONS) {
    await db.query(
      `INSERT INTO achievements (key, name, description, points_reward, condition_type, condition_value)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (key) DO NOTHING`,
      [def.key, def.name, def.description, def.points_reward, def.condition_type, JSON.stringify(def.condition_value)]
    );
  }
}

/**
 * Check and award any newly earned achievements after a sighting.
 * @param {string} userId
 * @param {Object} animal - the identified animal row
 * @param {number} currentStreak
 * @returns {Promise<Array>} newly earned achievements
 */
async function checkAndAwardAchievements(userId, animal, currentStreak) {
  const newlyEarned = [];

  // Fetch achievements the user hasn't earned yet
  const pendingRes = await db.query(
    `SELECT a.* FROM achievements a
     WHERE NOT EXISTS (
       SELECT 1 FROM user_achievements ua
       WHERE ua.user_id = $1 AND ua.achievement_id = a.id
     )`,
    [userId]
  );
  const pending = pendingRes.rows;
  if (pending.length === 0) return newlyEarned;

  // Gather stats
  const statsRes = await db.query(
    `SELECT
       COUNT(*) AS total_sightings,
       COUNT(DISTINCT animal_id) AS unique_species
     FROM sightings
     WHERE user_id = $1`,
    [userId]
  );
  const stats = statsRes.rows[0];
  const totalSightings = parseInt(stats.total_sightings, 10);

  for (const achievement of pending) {
    let earned = false;

    switch (achievement.condition_type) {
      case 'total_sightings': {
        const required = achievement.condition_value?.count || 0;
        earned = totalSightings >= required;
        break;
      }
      case 'rarity_catch': {
        const requiredRarity = achievement.condition_value?.rarity;
        if (animal && animal.rarity === requiredRarity) {
          // Check if this is the first time catching this rarity
          const rarityRes = await db.query(
            `SELECT s.id FROM sightings s
             JOIN animals a ON s.animal_id = a.id
             WHERE s.user_id = $1 AND a.rarity = $2
             LIMIT 1`,
            [userId, requiredRarity]
          );
          earned = rarityRes.rows.length >= 1;
        }
        break;
      }
      case 'streak': {
        const requiredDays = achievement.condition_value?.days || 0;
        earned = (currentStreak || 0) >= requiredDays;
        break;
      }
    }

    if (earned) {
      try {
        await db.query(
          'INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [userId, achievement.id]
        );
        // Award bonus points
        if (achievement.points_reward > 0) {
          await db.query(
            'UPDATE users SET total_points = total_points + $1, weekly_points = weekly_points + $1 WHERE id = $2',
            [achievement.points_reward, userId]
          );
        }
        newlyEarned.push(achievement);
      } catch (err) {
        console.error('Achievement insert error:', err.message);
      }
    }
  }

  return newlyEarned;
}

module.exports = { checkAndAwardAchievements, seedAchievements, ACHIEVEMENT_DEFINITIONS };
