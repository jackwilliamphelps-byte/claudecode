# Ultimate Review Platform - Production MVP

A comprehensive review aggregation platform that consolidates business reviews from multiple sources (Trustpilot, Google, Feefo), normalises ratings to a 0-100 scale, detects suspicious review patterns, and provides confidence-scored analytics.

## 🎯 Features

### Core Functionality
- **Multi-source Aggregation**: Unified view of reviews across Trustpilot, Google, Feefo, and CSV imports
- **Entity Resolution**: Intelligent business matching with confidence scoring
- **Normalised Scoring**: Convert all rating systems (stars, percentages, thumbs) to 0-100 scale
- **Recency Weighting**: Exponential decay with configurable half-life (default 90 days)
- **Confidence Calculation**: Wilson score interval approach with sample size and variance analysis
- **Source Coverage**: Discover unclaimed and duplicate profiles

### Signal Detection (Explainable AI)
- **Similarity Clustering**: TF-IDF cosine similarity to detect templated reviews
- **Burst Detection**: Identify unusual review volume spikes
- **Rating-Text Mismatch**: Detect 5-star reviews with negative sentiment (and vice versa)
- **Phrase Repetition**: N-gram analysis for coordinated language
- **Incentive Language**: Keyword detection for compensated reviews

All signals include:
- Confidence scores
- Evidence snippets
- Clear explanations
- Review references

### Technical Architecture
- **Framework**: Next.js 14 (App Router) + TypeScript
- **Database**: PostgreSQL + Prisma ORM
- **Deployment**: Vercel-optimised serverless architecture
- **Job Processing**: Chunked ingestion pattern (no external queue needed for MVP)
- **Extensibility**: Connector interface for adding new sources

## 📁 Project Structure

```
review-platform/
├── app/                          # Next.js App Router
│   ├── api/                      # API routes
│   │   ├── businesses/           # Business endpoints
│   │   ├── ingest/               # Job processing
│   │   ├── sources/              # Connector management
│   │   └── import/               # CSV upload
│   ├── businesses/[id]/          # Business detail pages
│   ├── settings/                 # Configuration UI
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Homepage
│   └── globals.css               # Styles
├── lib/
│   ├── connectors/               # Source integrations
│   │   ├── types.ts              # Connector interface
│   │   ├── trustpilot-demo.ts    # Demo connector
│   │   ├── csv-import.ts         # CSV importer
│   │   └── index.ts              # Registry
│   └── services/                 # Business logic
│       ├── scoring.ts            # Score calculation
│       ├── signals.ts            # Pattern detection
│       └── entity-resolution.ts  # Business matching
├── prisma/
│   ├── schema.prisma             # Database schema
│   └── seed.ts                   # Demo data
├── components/                   # React components
├── ARCHITECTURE.md               # Technical documentation
├── API_ROUTES.md                 # API reference
└── package.json
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm
- PostgreSQL 13+ (local or managed)
- Git

### Local Development

1. **Clone and install dependencies:**
```bash
git clone <repository-url>
cd review-platform
npm install
```

2. **Set up environment variables:**
```bash
cp .env.example .env
```

Edit `.env` and add your database URL:
```env
DATABASE_URL="postgresql://user:password@localhost:5432/review_platform"
```

3. **Initialize database:**
```bash
# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate dev --name init

# Seed demo data
npm run seed
```

4. **Start development server:**
```bash
npm run dev
```

Visit `http://localhost:3000`

### Demo Data

The seed script creates:
- **3 businesses**: TechMart Electronics, GreenLeaf Organics, UrbanFit Gym
- **6 profiles** across sources (including 1 unclaimed duplicate for testing)
- **90 reviews** with embedded suspicious patterns:
  - Similar templated reviews
  - Review burst patterns
  - Rating-text mismatches
  - Incentive language
  - Phrase repetition

## 📊 Database Schema

### Core Entities
- **Business**: Canonical business entity
- **Profile**: Source-specific representation (1:many with Business)
- **Review**: Individual review with normalised rating
- **ScoreSnapshot**: Historical score tracking
- **Signal**: Detected suspicious patterns
- **SignalEvidence**: Links signals to reviews
- **IngestJob**: Async job processing
- **ConnectorConfig**: Source configuration

### Key Indices
- Business: name, postcode, website
- Profile: businessId, source, externalId
- Review: profileId, reviewDate, ratingNormalised
- Signal: businessId, type, detectedAt

## 🔌 Adding a New Connector

1. **Implement the connector interface:**
```typescript
// lib/connectors/my-source.ts
import { SourceConnector, SearchQuery, ProfileMatch, ReviewData } from './types';

export class MySourceConnector implements SourceConnector {
  readonly name = 'My Source';
  readonly source = 'my_source';

  async searchProfiles(query: SearchQuery): Promise<ProfileMatch[]> {
    // Implementation
  }

  async fetchReviews(profileRef, pagination) {
    // Implementation
  }

  async fetchSummary(profileRef) {
    // Implementation
  }
}
```

2. **Register the connector:**
```typescript
// lib/connectors/index.ts
import { MySourceConnector } from './my-source';

export function initializeConnectors() {
  registerConnector(new MySourceConnector());
  // ...
}
```

3. **Add configuration:**
```sql
INSERT INTO "ConnectorConfig" (source, enabled, status)
VALUES ('my_source', false, 'unconfigured');
```

## 📡 API Endpoints

### Business Management
- `POST /api/businesses/resolve` - Entity resolution
- `GET /api/businesses/:id` - Get business details
- `POST /api/businesses/:id/ingest` - Create ingestion job
- `GET /api/businesses/:id/score` - Calculate score
- `GET /api/businesses/:id/reviews` - Get reviews (filterable)
- `GET /api/businesses/:id/signals` - Get detected signals

### Job Processing
- `POST /api/ingest/:jobId/run` - Process next chunk
- `GET /api/ingest/:jobId` - Get job status

### Configuration
- `GET /api/sources` - List connectors
- `POST /api/import/csv` - Upload CSV

### Example: Process an Ingestion Job
```typescript
// 1. Create job
const { jobId } = await fetch('/api/businesses/123/ingest', {
  method: 'POST',
  body: JSON.stringify({ source: 'trustpilot', profileId: 'abc' })
}).then(r => r.json());

// 2. Poll and process
const interval = setInterval(async () => {
  const result = await fetch(`/api/ingest/${jobId}/run`, { method: 'POST' })
    .then(r => r.json());
  
  if (result.status === 'completed' || result.status === 'failed') {
    clearInterval(interval);
  }
}, 2000);
```

## 🚢 Vercel Deployment

### Prerequisites
- Vercel account
- Managed PostgreSQL (Vercel Postgres, Supabase, Neon, etc.)

### Deployment Steps

1. **Push to Git repository:**
```bash
git init
git add .
git commit -m "Initial commit"
git push origin main
```

2. **Connect to Vercel:**
```bash
npm i -g vercel
vercel login
vercel
```

3. **Configure environment variables in Vercel dashboard:**
- `DATABASE_URL`: Your PostgreSQL connection string
- Optional: Source API keys (`TRUSTPILOT_API_KEY`, etc.)

4. **Run database migrations:**

Option A: Using Vercel CLI
```bash
vercel env pull .env.local
npx prisma migrate deploy
npm run seed  # Optional: seed demo data
```

Option B: Using CI/CD
Add to your build command in `vercel.json`:
```json
{
  "buildCommand": "npx prisma generate && npx prisma migrate deploy && next build"
}
```

5. **Deploy:**
```bash
vercel --prod
```

### Production Checklist
- [ ] Database migrations applied
- [ ] Environment variables configured
- [ ] Demo data seeded (optional)
- [ ] API endpoints tested
- [ ] Connector status verified
- [ ] Edge caching configured
- [ ] Error tracking enabled

## 🎨 Design System

### Aesthetic Direction
**Industrial/Editorial Hybrid** - Brutalist data layouts with editorial refinement

- **Colors**: High-contrast amber/charcoal (trust signals)
- **Typography**: IBM Plex Mono (primary) + Lora (accents)
- **Layout**: Dense information with generous breathing room
- **Interactions**: Subtle hover states, glow effects on key elements

### Key Components
- **Stat Cards**: Hover-activated gradient backgrounds
- **Signal Badges**: Color-coded by confidence
- **Score Visualizations**: Rechart-based trend graphs
- **Review Table**: Filterable, sortable, with inline signals

## 📈 Phase 2 Roadmap

### Near-term Enhancements
- [ ] Real API integrations (Trustpilot, Google Places, Feefo)
- [ ] Multi-tenant support with row-level security
- [ ] Authentication (NextAuth.js)
- [ ] Webhook-based job processing (Inngest, BullMQ)
- [ ] Advanced entity deduplication
- [ ] Review sentiment analysis (transformers.js)
- [ ] Vector similarity search (pgvector)
- [ ] Scheduled re-ingestion (Vercel Cron)

### Long-term Vision
- [ ] Review response management
- [ ] Competitive benchmarking
- [ ] Custom report builder
- [ ] API for third-party integrations
- [ ] Mobile apps (React Native)
- [ ] White-label deployment
- [ ] AI-powered review summarisation
- [ ] Automated response suggestions

## 🧪 Testing

### Manual Testing
1. Search for businesses
2. View score breakdown
3. Inspect signal detection
4. Upload CSV reviews
5. Test job processing
6. Export reports

### Future: Automated Testing
```bash
npm run test        # Unit tests
npm run test:e2e    # Playwright E2E
npm run test:api    # API integration tests
```

## 🔒 Security Considerations

### MVP Scope
- Input validation (Zod schemas)
- SQL injection prevention (Prisma)
- XSS protection (Next.js auto-escaping)
- Rate limiting (edge middleware)

### Production Recommendations
- Implement authentication
- Add CSRF protection
- Enable audit logging
- Use secrets management
- Set up WAF rules
- Implement backup strategy

## 📝 License

MIT License - See LICENSE file for details

## 🤝 Contributing

### Setup for Contributors
```bash
git clone <repo>
npm install
cp .env.example .env
# Edit .env with your DATABASE_URL
npx prisma migrate dev
npm run seed
npm run dev
```

### Code Standards
- TypeScript strict mode
- Prisma for database access
- Next.js App Router conventions
- Tailwind CSS for styling
- ESLint + Prettier

## 📧 Support

- **Issues**: GitHub Issues
- **Documentation**: /ARCHITECTURE.md, /API_ROUTES.md
- **Database Schema**: Run `npx prisma studio`

## 🎯 Production Checklist

Before going live:
- [ ] Set up managed PostgreSQL
- [ ] Configure connection pooling (PgBouncer)
- [ ] Enable database backups
- [ ] Set up error tracking (Sentry)
- [ ] Configure monitoring (Vercel Analytics)
- [ ] Test API rate limits
- [ ] Review security headers
- [ ] Enable HTTPS
- [ ] Set up custom domain
- [ ] Test mobile responsiveness
- [ ] Verify SEO meta tags
- [ ] Create privacy policy
- [ ] Set up analytics

---

**Built with:**
Next.js • TypeScript • PostgreSQL • Prisma • Tailwind CSS • Vercel

**MVP Development Time:** Estimated 3-5 days for experienced full-stack engineer
