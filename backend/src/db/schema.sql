-- WildSnap database schema
-- Run with: psql $DATABASE_URL -f schema.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(30) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT,
  avatar_url TEXT,
  country_code CHAR(2),
  region VARCHAR(100),
  total_points INT DEFAULT 0,
  weekly_points INT DEFAULT 0,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_active_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Animals master database
CREATE TABLE IF NOT EXISTS animals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  common_name VARCHAR(100) NOT NULL,
  scientific_name VARCHAR(150),
  category VARCHAR(50),
  rarity VARCHAR(20) CHECK (rarity IN ('common','uncommon','rare','epic','legendary')),
  base_points INT NOT NULL,
  iucn_status VARCHAR(30),
  description TEXT,
  habitat TEXT,
  typical_regions TEXT[],
  silhouette_url TEXT,
  reference_image_url TEXT,
  ai_labels TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sightings
CREATE TABLE IF NOT EXISTS sightings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  animal_id UUID REFERENCES animals(id),
  photo_url TEXT NOT NULL,
  thumbnail_url TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  altitude_m INT,
  compass_bearing INT,
  captured_at TIMESTAMPTZ NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  ai_confidence DECIMAL(5, 2),
  ai_raw_response JSONB,
  points_awarded INT,
  multipliers_applied JSONB,
  photo_quality_score DECIMAL(4, 2),
  is_verified BOOLEAN DEFAULT FALSE,
  is_flagged BOOLEAN DEFAULT FALSE,
  offline_queued BOOLEAN DEFAULT FALSE,
  sync_status VARCHAR(20) DEFAULT 'synced'
);

-- User Collection
CREATE TABLE IF NOT EXISTS user_collection (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  animal_id UUID REFERENCES animals(id),
  first_caught_at TIMESTAMPTZ,
  total_catches INT DEFAULT 1,
  best_photo_sighting_id UUID REFERENCES sightings(id),
  PRIMARY KEY (user_id, animal_id)
);

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100),
  description TEXT,
  icon_url TEXT,
  points_reward INT DEFAULT 0,
  condition_type VARCHAR(50),
  condition_value JSONB
);

CREATE TABLE IF NOT EXISTS user_achievements (
  user_id UUID REFERENCES users(id),
  achievement_id UUID REFERENCES achievements(id),
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, achievement_id)
);

-- Leaderboard snapshots
CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start DATE NOT NULL,
  user_id UUID REFERENCES users(id),
  rank INT,
  points INT,
  catches INT,
  scope VARCHAR(20),
  scope_value VARCHAR(100)
);

-- Follows
CREATE TABLE IF NOT EXISTS follows (
  follower_id UUID REFERENCES users(id),
  following_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_sightings_user_id ON sightings(user_id);
CREATE INDEX IF NOT EXISTS idx_sightings_animal_id ON sightings(animal_id);
CREATE INDEX IF NOT EXISTS idx_sightings_location ON sightings(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_sightings_captured_at ON sightings(captured_at);
CREATE INDEX IF NOT EXISTS idx_user_collection_user ON user_collection(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_scope ON leaderboard_snapshots(scope, scope_value, week_start);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_animals_rarity ON animals(rarity);
CREATE INDEX IF NOT EXISTS idx_animals_category ON animals(category);
CREATE INDEX IF NOT EXISTS idx_users_total_points ON users(total_points DESC);
CREATE INDEX IF NOT EXISTS idx_users_weekly_points ON users(weekly_points DESC);
CREATE INDEX IF NOT EXISTS idx_users_country ON users(country_code);
CREATE INDEX IF NOT EXISTS idx_users_region ON users(region);
