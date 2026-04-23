/**
 * FCM Push Notification Service
 *
 * Requires firebase-admin to be installed and FIREBASE_SERVICE_ACCOUNT_JSON
 * environment variable to be set (JSON string of the service account key).
 *
 * All send* functions fail silently so that notification errors never break
 * the main request flow.
 */

let messaging = null;

function initFirebase() {
  if (messaging) return messaging;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) return null;

  try {
    const admin = require('firebase-admin');
    if (admin.apps.length === 0) {
      const serviceAccount = JSON.parse(serviceAccountJson);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    messaging = admin.messaging();
    return messaging;
  } catch (err) {
    console.warn('Firebase Admin init failed (push notifications disabled):', err.message);
    return null;
  }
}

/**
 * Send a push notification to a single FCM token.
 * @param {string} fcmToken
 * @param {string} title
 * @param {string} body
 * @param {Object} [data] - optional key/value string payload
 */
async function sendPush(fcmToken, title, body, data = {}) {
  const msg = initFirebase();
  if (!msg || !fcmToken) return;

  try {
    await msg.send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.warn('FCM send failed:', err.message);
  }
}

/**
 * Send to multiple tokens in a single batch (up to 500).
 */
async function sendMulticast(fcmTokens, title, body, data = {}) {
  const msg = initFirebase();
  if (!msg || !fcmTokens || fcmTokens.length === 0) return;

  const validTokens = fcmTokens.filter(Boolean);
  if (validTokens.length === 0) return;

  try {
    await msg.sendEachForMulticast({
      tokens: validTokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.warn('FCM multicast failed:', err.message);
  }
}

// ── Notification helpers ──────────────────────────────────────────────────────

async function notifyRareAnimalNearby(fcmToken, animalName, distanceKm) {
  await sendPush(
    fcmToken,
    '🔴 Rare Animal Nearby!',
    `A ${animalName} was spotted ${distanceKm.toFixed(1)} km from you!`,
    { type: 'rare_nearby', animal_name: animalName }
  );
}

async function notifyDailyChallenge(fcmToken, challengeTitle) {
  await sendPush(
    fcmToken,
    '🌿 Daily Challenge',
    challengeTitle,
    { type: 'daily_challenge' }
  );
}

async function notifyLeaderboardOvertaken(fcmToken, overtakerUsername, newRank) {
  await sendPush(
    fcmToken,
    '⚔️ You\'ve been overtaken!',
    `${overtakerUsername} just passed you! You\'re now #${newRank}`,
    { type: 'leaderboard_overtaken', new_rank: String(newRank) }
  );
}

async function notifyWeeklyReset(fcmTokens) {
  await sendMulticast(
    fcmTokens,
    '🏁 New Week Starts Now!',
    'Leaderboard has reset. Go catch something rare!',
    { type: 'weekly_reset' }
  );
}

async function notifySyncComplete(fcmToken, photoCount, pointsEarned) {
  await sendPush(
    fcmToken,
    '✅ Photos Synced!',
    `${photoCount} photo${photoCount !== 1 ? 's' : ''} synced. You earned ${pointsEarned} points!`,
    { type: 'sync_complete', photo_count: String(photoCount), points_earned: String(pointsEarned) }
  );
}

module.exports = {
  sendPush,
  sendMulticast,
  notifyRareAnimalNearby,
  notifyDailyChallenge,
  notifyLeaderboardOvertaken,
  notifyWeeklyReset,
  notifySyncComplete,
};
