require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const express = require('express');
const cors = require('cors');
const path = require('path');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const sightingRoutes = require('./routes/sightings');
const animalRoutes = require('./routes/animals');
const leaderboardRoutes = require('./routes/leaderboard');
const challengeRoutes = require('./routes/challenges');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();

// CORS — restrict to configured origins; fall back to localhost in development only
const allowedOriginsRaw = process.env.ALLOWED_ORIGINS || '';
const corsOrigin =
  allowedOriginsRaw
    ? allowedOriginsRaw.split(',').map((o) => o.trim())
    : process.env.NODE_ENV === 'production'
      ? false
      : 'http://localhost:3000';
app.use(cors({ origin: corsOrigin, credentials: true }));

// Body parsing
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Serve local uploads statically
app.use('/uploads', express.static(path.resolve(process.cwd(), 'uploads')));

// Global rate limiter — 200 req / 15 min per IP
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: 'Too many requests, please try again later.' },
});
app.use(globalLimiter);

// Auth-specific stricter rate limiter
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: 'Too many authentication attempts, please try again later.' },
});

// Health check
app.get('/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok', timestamp: new Date().toISOString() } });
});

// Routes
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/sightings', sightingRoutes);
app.use('/api/animals', animalRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/challenges', challengeRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, error: `Route ${req.method} ${req.path} not found` });
});

// Centralized error handler
app.use(errorHandler);

module.exports = app;
