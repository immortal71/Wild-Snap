# WildSnap — Full Product & Development Prompt
### "Catch the Wild. Save the Planet."

---

## 1. PRODUCT VISION & CONCEPT

**App Name:** WildSnap  
**Tagline:** "Catch the Wild. Save the Planet."  
**Core Concept:** A gamified wildlife photography app where users earn points by photographing real animals in the wild. The app uses AI to identify the animal, assess its rarity, and award points accordingly. Users compete on global and local leaderboards, build personal wildlife collections, and contribute to a real-world conservation database.

**Phase 1 (MVP):** Animals & Birds only  
**Phase 2:** Add insects, reptiles, marine life  
**Phase 3:** Full conservation research integration, tracking rare/endangered species

**Platforms:**  
- Phase 1: Mobile App (iOS + Android via React Native or Flutter)  
- Phase 2: Web App (React.js) with shared backend

---

## 2. TARGET USERS

- **Casual users:** Nature lovers, hikers, tourists (ages 15–45) who enjoy collecting and competing
- **Serious users:** Wildlife photographers, birdwatchers, students who want a real database
- **Researchers (future):** Conservationists, NGOs, government wildlife departments who can access the crowdsourced sighting database
- **Educators:** Teachers using the app for field trips and biology classes

---

## 3. DESIGN SYSTEM

### 3.1 Design Philosophy
**Aesthetic Direction:** Organic Dark — like peering through a night-vision scope into a dense jungle. The app should feel alive, mysterious, and rooted in nature. Not a corporate app. Not a game app. Something in between: a field journal crossed with a sci-fi scanner. Think National Geographic meets tactical military field gear.

### 3.2 Color Palette

| Role | Color Name | Hex Code | Usage |
|---|---|---|---|
| Background Primary | Deep Jungle Black | `#0A0F0D` | Main screen backgrounds |
| Background Secondary | Moss Dark | `#111A14` | Cards, panels, bottom sheets |
| Background Tertiary | Forest Floor | `#192219` | Input fields, inactive tabs |
| Accent Primary | Bioluminescent Green | `#39FF89` | CTAs, scan button, active states, points |
| Accent Secondary | Amber Torch | `#FFAA33` | Rare badges, warnings, streaks |
| Accent Tertiary | Sky Slate | `#7EC8E3` | Info chips, region tags |
| Legendary Color | Solar Gold | `#FFD700` | Legendary rarity glow, top leaderboard |
| Epic Color | Violet Bloom | `#C77DFF` | Epic rarity cards |
| Rare Color | Ocean Blue | `#4895EF` | Rare rarity cards |
| Uncommon Color | Fern Green | `#52B788` | Uncommon rarity cards |
| Common Color | Stone Gray | `#8D99AE` | Common rarity cards |
| Text Primary | Ghost White | `#EDF2EF` | Headlines, primary text |
| Text Secondary | Faded Sage | `#7A9E7E` | Subtitles, metadata |
| Text Muted | Bark Gray | `#4A5553` | Placeholders, disabled |
| Danger | Blood Orchid | `#FF4757` | Errors, delete actions |
| Success | Leaf Flash | `#2ED573` | Successful capture confirmation |

### 3.3 Typography

| Role | Font | Weight | Size |
|---|---|---|---|
| Display / App Name | **Bebas Neue** | 400 | 48–72px |
| Section Headers | **Syne** | 700 | 24–32px |
| Body Text | **DM Sans** | 400/500 | 14–16px |
| Monospace / Scan Data | **JetBrains Mono** | 400 | 12–14px |
| Animal Names | **Playfair Display** | 600 Italic | 20–28px |
| Points / Numbers | **Bebas Neue** | 400 | 36–60px |

### 3.4 Iconography
- Style: Outlined with slight organic imperfection (not perfectly geometric) — use Phosphor Icons or custom SVG set
- Animal category icons: Hand-illustrated style, not emoji
- Navigation icons: Minimal, stroke weight 1.5px

### 3.5 Motion & Animation
- **Scan animation:** Green horizontal laser line sweeps up/down the viewfinder with a subtle noise/grain overlay; corner brackets pulse
- **Capture animation:** Screen flashes white like a camera shutter, then dissolves into a reveal card that flies up from the bottom
- **Rarity reveal:** Legendary/Epic animals get a 2-second "opening" animation — the card is face-down, glows at the edges, then flips. Like opening a rare trading card
- **Points increment:** Numbers count up rapidly (ticker animation) when points are awarded
- **Leaderboard transitions:** Rank changes animate with sliding motion
- **Tab transitions:** Smooth crossfade, no hard cuts
- **Page load:** Staggered fade-up for all cards (150ms delay between each)
- **Micro-interactions:** Every button press has a subtle haptic + scale-down feedback (0.96 scale on press)

### 3.6 UI Components

**Bottom Navigation Bar:**  
5 tabs — Home, Scan, Collection, Leaderboard, Profile  
The Scan tab is a large raised circular button (48px radius), glowing green, always center

**Animal Cards:**  
- Rounded corners (16px radius)  
- Rarity-colored left border (4px)  
- Rarity glow on hover/focus matching color table above  
- Shows: Animal emoji or photo thumbnail, name, region, rarity badge, points value  
- Locked/unseen animals shown as dark silhouette with "???" name

**Rarity Badge:**  
- Small pill-shaped chip, uppercase monospace font  
- Color matches rarity table  
- Subtle shimmer animation on Legendary/Epic

**Scan Viewfinder:**  
- Full-screen camera view  
- Corner bracket overlays in green  
- Animated scan line  
- Bottom HUD bar showing: GPS coordinates, timestamp, compass bearing, altitude  
- "ANALYZING..." text in JetBrains Mono during AI processing

**Toast Notifications:**  
- Slide in from top  
- Dark glass morphism background (backdrop blur)  
- Green left border for success, amber for info, red for error

---

## 4. SCREENS & USER FLOWS

### Screen 1: Splash / Onboarding
- Full-screen dark background with slow animated particles (fireflies / bioluminescent dots floating up)
- WildSnap logo in Bebas Neue, letter-by-letter reveal
- Tagline fades in below
- "Start Your Journey" CTA button
- 3-step onboarding carousel:
  1. "Photograph animals in the wild"
  2. "AI identifies and rates rarity"
  3. "Compete, collect, and conserve"
- Sign up with Google / Apple / Email

### Screen 2: Home (Feed)
- Top bar: User avatar, current streak 🔥, total points badge
- **"Nearby Sightings"** horizontal scroll — other users' recent catches near your location (blurred photo + animal name + distance "2.3 km away")
- **"Your Recent Catches"** section — last 5 animals you photographed
- **"Daily Challenge"** card — e.g., "Photograph a bird today for 2x points"
- **"Rare Alert"** card — AI-detected rare animal spotted near you (uses collective data from other users)
- **"Top of the Week"** leaderboard teaser — top 3 users with crowns

### Screen 3: Scan (Core Feature)
- Full-screen camera viewfinder
- Scanning UI overlay (see design above)
- User taps shutter button
- Photo is captured and sent to AI for identification
- Loading state: "Analyzing wildlife..."
- Result appears as a bottom sheet sliding up:
  - Animal name + scientific name
  - Rarity tier with badge
  - Points awarded (animated count-up)
  - Region/habitat info
  - "Add to Collection" button
  - "Retake" option
- If animal not recognized: "Unknown Species — Submit for Review" option

### Screen 4: Collection (Pokédex equivalent)
- Grid view of all animals in the database
- Caught animals: full color with photo
- Uncaught animals: dark silhouette, name hidden ("???"), points shown as "??"
- Filter bar: All | Caught | Uncaught | By Rarity | By Region
- Search bar at top
- Tapping a caught animal: Full detail card — your best photo, date caught, GPS location on mini-map, rarity info, total times caught, personal notes field

### Screen 5: Leaderboard
- Tabs: Global | Country | Region | Friends
- Top 3 displayed as podium with crown icons + animated glow
- Rest of list scrolls as ranked rows
- Your rank always pinned at bottom if not in top 10
- Each row: Rank number, avatar, username, points, number of catches, rarity badge (highest rarity they've caught)
- Weekly reset indicator with countdown timer

### Screen 6: Profile
- Cover photo (user-selectable or auto-generated from their best catch)
- Avatar + username + join date
- Stats: Total Points | Total Catches | Rarest Catch | Current Streak | Longest Streak
- Achievement badges row (horizontal scroll):
  - "First Catch", "Snow Leopard Hunter", "100 Catches", "7-Day Streak", etc.
- My Collection preview (first 6 animals)
- Offline cache status: "X photos pending sync"
- Settings link

### Screen 7: Animal Detail Page
- Hero image (user's photo, full bleed)
- Animal name in Playfair Display italic
- Scientific name in small gray text below
- Rarity badge + points value
- Info tabs: Overview | Habitat | Conservation Status | Your Sightings
- Overview: Description of animal, fun fact
- Conservation Status: IUCN Red List status pulled from database
- Your Sightings: All your past photos of this animal, date, location, points each

### Screen 8: Settings
- Account settings (name, email, password, linked accounts)
- Notification preferences (Rare Alert nearby, Daily Challenge reminder, Leaderboard changes)
- Privacy (location sharing: always / while using / never)
- Offline mode toggle
- Data usage (limit uploads to WiFi only)
- Export my data (download your personal sightings as CSV)
- About / Legal / Licenses

---

## 5. CORE FEATURES (DETAILED)

### 5.1 AI Animal Identification
- User takes a photo
- Photo is sent to the AI identification API
- AI returns: animal species name, confidence score (%), scientific name, rarity classification
- If confidence < 70%: show "Low confidence — are you sure this is [animal name]?" with confirm/deny
- If completely unrecognized: flag for manual review by community moderators
- **AI Model Options:**
  - **iNaturalist API** (free, open, excellent for wildlife) — recommended for MVP
  - **Google Cloud Vision API** (broader but less wildlife-specific)
  - **Custom fine-tuned model** (Phase 3 — train on your own database once you have enough photos)
- Fallback: If offline, queue the photo locally and identify when back online

### 5.2 Rarity & Points System

| Rarity Tier | Examples | Base Points | How Rare |
|---|---|---|---|
| Common | Crow, Sparrow, Cow, Dog | 10–30 pts | Seen daily |
| Uncommon | Peacock, Monitor Lizard, Mongoose | 50–100 pts | Seen weekly |
| Rare | Bengal Tiger, One-Horned Rhino, Gharial | 150–250 pts | Endangered/regional |
| Epic | Snow Leopard, Red Panda, Clouded Leopard | 280–400 pts | Very rarely seen |
| Legendary | Irrawaddy Dolphin, Gangetic Dolphin, Wild Yak | 500–1000 pts | Critically endangered or ultra-rare sighting |

**Points Multipliers:**
- First time catching this species: 2x points
- Daily first catch: 1.5x points
- Photo quality score (sharpness, framing, lighting assessed by AI): up to 1.3x bonus
- Rare location bonus (if sighted outside known range): 1.5x bonus
- Night sighting (between 8pm–5am): 1.2x bonus

**Point Decay:** Points from common animals reduce by 20% after your 10th catch of the same species (anti-farming mechanic)

### 5.3 Offline Mode
- Camera always works offline — user can photograph and queue
- App stores: pending photos, GPS coordinates, timestamp, compass bearing locally (SQLite on device)
- When connection restored: auto-sync queue to server, identify queued photos, award points
- Collection data cached locally so users can browse their collection offline
- Leaderboard cached — shows last known state with "Last updated X minutes ago" label
- Offline indicator: subtle amber dot on scan button when offline

### 5.4 Leaderboard System
- Computed in real-time on backend
- **Tiers:**
  - Global (all users worldwide)
  - Country-level (auto-detected from user's GPS history)
  - Region/Province level
  - Friends (user-defined follow system)
- Weekly leaderboard resets every Monday 00:00 UTC
- All-time leaderboard never resets
- **Anti-cheat:**
  - GPS metadata must match photo EXIF location (±5km tolerance)
  - Duplicate photo detection (perceptual hash comparison)
  - Velocity check: user can't submit photos from two locations 1000km apart within 1 hour
  - AI confidence threshold enforcement
  - Community reporting: users can flag suspicious catches

### 5.5 Gamification Elements
- **Daily Streak:** Log in and catch at least one animal daily. Streak counter shown prominently. 7-day streak = bonus 100 pts. 30-day = badge + 500 pts
- **Achievements/Badges:** 50+ unique badges (First Catch, Region Master, Rarity Hunter, etc.)
- **Animal Dex Completion:** Completing a region's full set awards a Region Champion badge
- **Seasonal Events:** "Monsoon Migration" event where migratory birds score 3x for 2 weeks
- **Challenges:** Weekly community challenges — "Most rhinos caught this week" with leaderboard for that challenge

---

## 6. BACKEND ARCHITECTURE

### 6.1 Tech Stack Recommendation

| Layer | Technology | Reason |
|---|---|---|
| Mobile Frontend | **Flutter** (Dart) | Single codebase for iOS + Android, excellent camera APIs, great performance |
| Web Frontend (Phase 2) | **React.js + Next.js** | SEO-friendly, fast, reuse component logic |
| Backend API | **Node.js + Express** or **FastAPI (Python)** | FastAPI preferred if heavy ML integration; Node if JS-only team |
| Database (Primary) | **PostgreSQL** | Relational, reliable, handles user/animal/sighting data well |
| Database (Cache/Leaderboard) | **Redis** | Real-time leaderboard computation, session caching, rate limiting |
| File Storage | **AWS S3** or **Cloudflare R2** | Store user-uploaded animal photos at scale |
| AI Identification | **iNaturalist API** (MVP) → **Custom ML Model** (Phase 3) | |
| Auth | **Firebase Auth** or **Supabase Auth** | Google/Apple/Email sign-in, handles JWT, refresh tokens |
| Push Notifications | **Firebase Cloud Messaging (FCM)** | Cross-platform push for both iOS and Android |
| Offline Sync | **SQLite** (on device) + sync queue via REST API | |
| CDN | **Cloudflare** | Cache photos globally, reduce latency for image loading |
| Hosting | **Railway** or **Render** (MVP) → **AWS ECS** (scale) | |
| Monitoring | **Sentry** (errors) + **PostHog** (analytics) | |

### 6.2 Database Schema

```sql
-- Users
CREATE TABLE users (
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

-- Animals (master database)
CREATE TABLE animals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  common_name VARCHAR(100) NOT NULL,
  scientific_name VARCHAR(150),
  category VARCHAR(50), -- mammal, bird, reptile, insect
  rarity VARCHAR(20) CHECK (rarity IN ('common','uncommon','rare','epic','legendary')),
  base_points INT NOT NULL,
  iucn_status VARCHAR(30), -- LC, NT, VU, EN, CR, EW, EX
  description TEXT,
  habitat TEXT,
  typical_regions TEXT[], -- array of region names
  silhouette_url TEXT, -- for locked state in collection
  reference_image_url TEXT,
  ai_labels TEXT[], -- labels iNaturalist/Vision returns for this animal
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sightings (each photo submission)
CREATE TABLE sightings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  animal_id UUID REFERENCES animals(id),
  photo_url TEXT NOT NULL,
  thumbnail_url TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  altitude_m INT,
  compass_bearing INT,
  captured_at TIMESTAMPTZ NOT NULL, -- from photo EXIF or device clock
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  ai_confidence DECIMAL(5, 2), -- 0.00 to 100.00
  ai_raw_response JSONB, -- full AI API response stored for audit
  points_awarded INT,
  multipliers_applied JSONB, -- {first_catch: true, quality_bonus: 1.2}
  photo_quality_score DECIMAL(4, 2),
  is_verified BOOLEAN DEFAULT FALSE,
  is_flagged BOOLEAN DEFAULT FALSE,
  offline_queued BOOLEAN DEFAULT FALSE,
  sync_status VARCHAR(20) DEFAULT 'synced' -- synced | pending | failed
);

-- User Collection (which animals a user has caught)
CREATE TABLE user_collection (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  animal_id UUID REFERENCES animals(id),
  first_caught_at TIMESTAMPTZ,
  total_catches INT DEFAULT 1,
  best_photo_sighting_id UUID REFERENCES sightings(id),
  PRIMARY KEY (user_id, animal_id)
);

-- Achievements
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100),
  description TEXT,
  icon_url TEXT,
  points_reward INT DEFAULT 0,
  condition_type VARCHAR(50), -- catch_count, rarity, streak, species_id
  condition_value JSONB
);

CREATE TABLE user_achievements (
  user_id UUID REFERENCES users(id),
  achievement_id UUID REFERENCES achievements(id),
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, achievement_id)
);

-- Leaderboard snapshots (weekly)
CREATE TABLE leaderboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start DATE NOT NULL,
  user_id UUID REFERENCES users(id),
  rank INT,
  points INT,
  catches INT,
  scope VARCHAR(20), -- global | country | region
  scope_value VARCHAR(100) -- e.g., "NP" or "Bagmati"
);

-- Follows (friends system)
CREATE TABLE follows (
  follower_id UUID REFERENCES users(id),
  following_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);
```

### 6.3 API Endpoints

**Auth**
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/google
POST   /api/auth/apple
POST   /api/auth/refresh
DELETE /api/auth/logout
```

**Users**
```
GET    /api/users/me
PATCH  /api/users/me
GET    /api/users/:username
GET    /api/users/:id/collection
GET    /api/users/:id/achievements
GET    /api/users/:id/sightings
```

**Sightings (Core)**
```
POST   /api/sightings              -- Submit a photo (multipart/form-data)
GET    /api/sightings/nearby       -- ?lat=&lng=&radius_km=
GET    /api/sightings/:id
DELETE /api/sightings/:id
POST   /api/sightings/:id/flag     -- Report suspicious sighting
POST   /api/sightings/sync         -- Batch sync for offline queue
```

**Animals**
```
GET    /api/animals                -- Full database, filterable
GET    /api/animals/:id
GET    /api/animals/search?q=
GET    /api/animals/nearby?lat=&lng=  -- Animals historically spotted near location
```

**Leaderboard**
```
GET    /api/leaderboard/global?period=weekly|alltime
GET    /api/leaderboard/country/:code
GET    /api/leaderboard/region/:name
GET    /api/leaderboard/friends
GET    /api/leaderboard/me/rank    -- Returns user's current rank across all scopes
```

**Challenges**
```
GET    /api/challenges/active
GET    /api/challenges/:id
POST   /api/challenges/:id/progress
```

### 6.4 Photo Submission Flow (Server Side)
1. Receive photo via `POST /api/sightings`
2. Validate: file type (JPEG/PNG/HEIC), max size 15MB, GPS metadata present
3. Anti-cheat: check velocity (last submission location vs this one)
4. Perceptual hash check against recent submissions to detect duplicates
5. Upload original to S3 (`/originals/{user_id}/{timestamp}.jpg`)
6. Generate thumbnail (400x400) and store to S3 (`/thumbs/{...}`)
7. Send to AI identification service (iNaturalist API or Vision API)
8. Map AI response to `animals` table entry
9. Calculate points: base points × all applicable multipliers
10. Insert `sightings` row
11. Upsert `user_collection` row
12. Update `users.total_points` and `users.weekly_points`
13. Trigger achievement check (async job)
14. Update Redis leaderboard sorted set: `ZADD leaderboard:global {points} {user_id}`
15. Return sighting result to client

### 6.5 Leaderboard (Redis)
```
# Weekly global leaderboard
ZADD leaderboard:weekly:global {weekly_points} {user_id}
ZREVRANK leaderboard:weekly:global {user_id}  → user's rank
ZREVRANGE leaderboard:weekly:global 0 99       → top 100

# Country-level
ZADD leaderboard:weekly:country:NP {points} {user_id}

# Reset every Monday (cron job):
# 1. Snapshot current leaderboard to leaderboard_snapshots table
# 2. DEL all leaderboard:weekly:* keys
# 3. Reset users.weekly_points = 0
```

---

## 7. AI IDENTIFICATION MODULE

### 7.1 iNaturalist Integration (MVP)
```
Endpoint: GET https://api.inaturalist.org/v1/identifications
Method: POST image to /computervision/score_image
Returns: top 10 species suggestions with scores
Map the highest-confidence result to your animals table
```

### 7.2 Confidence Handling
- Score ≥ 85%: Auto-accept, award points
- Score 70–84%: Show user "We think this is [X] — confirm?"
- Score 50–69%: "Low confidence — what animal did you photograph?" (user picks from list)
- Score < 50%: "Unrecognized animal — submit for community review"

### 7.3 Custom Model (Phase 3)
- Once you have 50,000+ labeled sightings in your database
- Fine-tune a MobileNetV3 or EfficientNet model on your specific regional species
- Host on AWS SageMaker or Google Vertex AI
- This will outperform generic APIs for your target geography (Nepal/South Asia initially)

---

## 8. OFFLINE ARCHITECTURE (MOBILE)

### On-Device Storage (SQLite via Drift for Flutter)
```
Tables mirrored locally:
- animals (full cache, synced on app update)
- sightings (pending_sync only — user's unsynced photos)
- user_collection (full cache for offline browsing)
- leaderboard_cache (last known state with timestamp)
```

### Sync Logic
```
On app open:
1. Check connectivity
2. If online: push all pending sightings, pull latest leaderboard + collection
3. If offline: load from local cache, show offline badge

Background sync:
- Listen for connectivity change
- Auto-trigger sync when connection restored
- Show "X photos synced!" toast notification
```

---

## 9. NOTIFICATIONS

| Trigger | Message | Type |
|---|---|---|
| Rare animal spotted nearby | "🔴 A Snow Leopard was spotted 3km from you!" | Push |
| Daily challenge available | "🌿 Today's challenge: Photograph a bird for 2x points" | Push |
| Someone overtakes you on leaderboard | "⚔️ RajeshKC just passed you! You're now #4" | Push |
| New achievement unlocked | "🏅 Achievement unlocked: First Legendary!" | In-app |
| Weekly leaderboard reset | "🏁 New week! Leaderboard has reset. Go catch something rare!" | Push |
| Sync complete after offline | "✅ 4 photos synced. You earned 340 points!" | In-app |

---

## 10. CONSERVATION DATABASE LAYER (FUTURE)

This is the long-term value of the app beyond gaming:

- Every sighting is geo-tagged and timestamped → builds a real spatial database
- For rare/endangered animals, alert partner organizations (WWF, IUCN, local wildlife departments)
- Public API for researchers: `GET /api/research/sightings?species=panthera_uncia&from=2024-01-01`
- Heatmap visualization of species distribution over time
- Anomaly detection: if a CR (Critically Endangered) species is photographed outside known range → trigger alert to conservationists
- Annual public "WildSnap Report" — crowdsourced wildlife data published openly

---

## 11. MONETIZATION (FUTURE OPTIONS)

- **Freemium:** Free with ads. Premium tier ($2.99/month) removes ads, adds rare animal radar, offline map downloads
- **Conservation donations:** In-app "donate points" to partner NGOs — converts points to real donations
- **Researcher data access:** API access for universities/NGOs for a fee
- **Merchandise:** Physical field journals, WildSnap binoculars bundle
- **Sponsored challenges:** Wildlife parks sponsor events ("Photograph animals in Chitwan NP this weekend")

---

## 12. DEVELOPMENT ROADMAP

### Phase 1 — MVP (3–4 months)
- [ ] Flutter app (iOS + Android)
- [ ] Camera + photo submission
- [ ] iNaturalist AI identification
- [ ] Animals database (500 species, Nepal/South Asia focused)
- [ ] Points system (no multipliers yet)
- [ ] Basic collection screen
- [ ] Global leaderboard (weekly only)
- [ ] User auth (Google + Email)
- [ ] Offline queue + sync

### Phase 2 — Growth (2–3 months after MVP)
- [ ] Multipliers + daily challenges
- [ ] Achievements system
- [ ] Friends/follows + friends leaderboard
- [ ] Country/region leaderboards
- [ ] Push notifications
- [ ] Rare animal nearby alert
- [ ] Improve UI polish + animations
- [ ] Web app (Next.js)

### Phase 3 — Scale & Conservation (6+ months)
- [ ] Custom ML model trained on your own data
- [ ] Insects category added
- [ ] Conservation partner integrations
- [ ] Researcher API
- [ ] Heatmap / species distribution maps
- [ ] Seasonal events engine
- [ ] Community moderation tools

---

## 13. THIRD-PARTY SERVICES SUMMARY

| Service | Purpose | Cost |
|---|---|---|
| iNaturalist API | Animal identification | Free |
| AWS S3 / Cloudflare R2 | Photo storage | ~$0.015/GB |
| Firebase Auth | Authentication | Free up to 10k users |
| Firebase FCM | Push notifications | Free |
| Redis Cloud | Leaderboard cache | Free tier available |
| Supabase | Postgres + Auth combo | Free tier available |
| Sentry | Error tracking | Free tier |
| PostHog | Analytics | Free tier |

---

## 14. SECURITY CONSIDERATIONS

- All photos scanned for CSAM (using Google SafeSearch API) before storage
- Rate limiting: max 50 photo submissions per user per day (anti-farming)
- JWT tokens with 15-minute expiry + refresh tokens (7-day, rotated)
- Photos stored with random UUID names (not predictable URLs)
- S3 buckets private — all photo URLs signed with 1-hour expiry
- GDPR-ready: users can request full data export or account deletion
- Location data: stored only as general region (city-level), not precise GPS, in public-facing APIs

---

*Document version 1.0 — WildSnap MVP Specification*  
*Ready to share with developers, designers, or investors.*
