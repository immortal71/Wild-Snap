const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const axios = require('axios');
const db = require('../config/database');
const redis = require('../config/redis');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
const SALT_ROUNDS = 12;
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '30d';
const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 3600;

function generateTokens(user) {
  const payload = { sub: user.id, username: user.username, email: user.email };
  const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: ACCESS_TOKEN_TTL });
  const refreshToken = jwt.sign({ sub: user.id }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: REFRESH_TOKEN_TTL,
  });
  return { token, refreshToken };
}

function sanitizeUser(user) {
  const { password_hash, ...safe } = user;
  return safe;
}

// POST /api/auth/register
router.post('/register', async (req, res, next) => {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ success: false, error: 'username, email and password are required' });
    }
    if (username.length < 3 || username.length > 30) {
      return res.status(400).json({ success: false, error: 'Username must be 3–30 characters' });
    }
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return res.status(400).json({ success: false, error: 'Username may only contain letters, numbers and underscores' });
    }
    if (password.length < 8) {
      return res.status(400).json({ success: false, error: 'Password must be at least 8 characters' });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await db.query(
      `INSERT INTO users (username, email, password_hash)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [username.toLowerCase(), email.toLowerCase(), passwordHash]
    );

    const user = result.rows[0];
    const { token, refreshToken } = generateTokens(user);

    await redis.set(`refresh:${user.id}`, refreshToken, 'EX', REFRESH_TOKEN_TTL_SECONDS);

    return res.status(201).json({ success: true, data: { token, refreshToken, user: sanitizeUser(user) } });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'email and password are required' });
    }

    const result = await db.query('SELECT * FROM users WHERE lower(email) = lower($1)', [email]);
    const user = result.rows[0];

    if (!user || !user.password_hash) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    const { token, refreshToken } = generateTokens(user);
    await redis.set(`refresh:${user.id}`, refreshToken, 'EX', REFRESH_TOKEN_TTL_SECONDS);

    return res.json({ success: true, data: { token, refreshToken, user: sanitizeUser(user) } });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/google
router.post('/google', async (req, res, next) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ success: false, error: 'idToken is required' });
    }

    // Verify token with Google
    let googlePayload;
    try {
      const verifyRes = await axios.get(
        'https://oauth2.googleapis.com/tokeninfo',
        { params: { id_token: idToken }, timeout: 10000 }
      );
      googlePayload = verifyRes.data;
    } catch (err) {
      return res.status(401).json({ success: false, error: 'Invalid Google token' });
    }

    const { email, name, picture, sub: googleId } = googlePayload;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Google token missing email' });
    }

    // Upsert user
    let userRes = await db.query('SELECT * FROM users WHERE lower(email) = lower($1)', [email]);
    let user = userRes.rows[0];

    if (!user) {
      const baseUsername = (name || email.split('@')[0])
        .replace(/[^a-zA-Z0-9_]/g, '_')
        .slice(0, 25)
        .toLowerCase();
      let username = baseUsername;
      let suffix = 1;
      while (true) {
        const exists = await db.query('SELECT id FROM users WHERE username = $1', [username]);
        if (exists.rows.length === 0) break;
        username = `${baseUsername}${suffix++}`;
      }

      const insertRes = await db.query(
        `INSERT INTO users (username, email, avatar_url)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [username, email.toLowerCase(), picture || null]
      );
      user = insertRes.rows[0];
    }

    const { token, refreshToken } = generateTokens(user);
    await redis.set(`refresh:${user.id}`, refreshToken, 'EX', REFRESH_TOKEN_TTL_SECONDS);

    return res.json({ success: true, data: { token, refreshToken, user: sanitizeUser(user) } });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/apple
router.post('/apple', async (req, res, next) => {
  try {
    const { identityToken, fullName } = req.body;
    if (!identityToken) {
      return res.status(400).json({ success: false, error: 'identityToken is required' });
    }

    // Verify the Apple identity token using Apple's public keys
    let applePayload;
    try {
      // Fetch Apple's public keys
      const keysRes = await axios.get('https://appleid.apple.com/auth/keys', { timeout: 10000 });
      const keys = keysRes.data.keys;

      // Decode the token header to find the right key
      const headerB64 = identityToken.split('.')[0]; // JWT header (base64url-encoded)
      const header = JSON.parse(Buffer.from(headerB64, 'base64url').toString());

      const matchingKey = keys.find((k) => k.kid === header.kid);
      if (!matchingKey) {
        return res.status(401).json({ success: false, error: 'Apple public key not found' });
      }

      // Convert JWK to PEM using crypto
      const publicKey = crypto.createPublicKey({ key: matchingKey, format: 'jwk' });
      const pemKey = publicKey.export({ type: 'spki', format: 'pem' });

      applePayload = jwt.verify(identityToken, pemKey, {
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com',
      });
    } catch (err) {
      return res.status(401).json({ success: false, error: 'Invalid Apple identity token' });
    }

    const { sub: appleUserId, email } = applePayload;
    if (!appleUserId) {
      return res.status(400).json({ success: false, error: 'Apple token missing user identifier' });
    }

    // Upsert user — Apple may not return email on repeat sign-ins
    let userRes = email
      ? await db.query('SELECT * FROM users WHERE lower(email) = lower($1)', [email])
      : { rows: [] };
    let user = userRes.rows[0];

    if (!user) {
      // Derive a username from fullName or email or appleUserId
      const nameParts = fullName
        ? [fullName.givenName, fullName.familyName].filter(Boolean).join(' ')
        : null;
      const baseUsername = (nameParts || (email ? email.split('@')[0] : appleUserId))
        .replace(/[^a-zA-Z0-9_]/g, '_')
        .slice(0, 25)
        .toLowerCase();
      let username = baseUsername;
      let suffix = 1;
      while (true) {
        const exists = await db.query('SELECT id FROM users WHERE username = $1', [username]);
        if (exists.rows.length === 0) break;
        username = `${baseUsername}${suffix++}`;
      }

      const insertRes = await db.query(
        `INSERT INTO users (username, email)
         VALUES ($1, $2)
         RETURNING *`,
        [username, email ? email.toLowerCase() : null]
      );
      user = insertRes.rows[0];
    }

    const { token, refreshToken } = generateTokens(user);
    await redis.set(`refresh:${user.id}`, refreshToken, 'EX', REFRESH_TOKEN_TTL_SECONDS);

    return res.json({ success: true, data: { token, refreshToken, user: sanitizeUser(user) } });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, error: 'refreshToken is required' });
    }

    let payload;
    try {
      payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (err) {
      return res.status(401).json({ success: false, error: 'Invalid or expired refresh token' });
    }

    const stored = await redis.get(`refresh:${payload.sub}`);
    if (!stored || stored !== refreshToken) {
      return res.status(401).json({ success: false, error: 'Refresh token revoked or not found' });
    }

    const userRes = await db.query('SELECT * FROM users WHERE id = $1', [payload.sub]);
    const user = userRes.rows[0];
    if (!user) {
      return res.status(401).json({ success: false, error: 'User not found' });
    }

    const { token, refreshToken: newRefreshToken } = generateTokens(user);
    await redis.set(`refresh:${user.id}`, newRefreshToken, 'EX', REFRESH_TOKEN_TTL_SECONDS);

    return res.json({ success: true, data: { token, refreshToken: newRefreshToken } });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/auth/logout
router.delete('/logout', authenticate, async (req, res, next) => {
  try {
    const token = req.token;
    const decoded = jwt.decode(token);
    const ttl = decoded?.exp ? decoded.exp - Math.floor(Date.now() / 1000) : 900;

    if (ttl > 0) {
      await redis.set(`blacklist:${token}`, '1', 'EX', ttl);
    }

    await redis.del(`refresh:${req.user.id}`);

    return res.json({ success: true, data: { message: 'Logged out successfully' } });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
