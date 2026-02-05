# Ultimate Review Platform - Architecture Overview

## Design Philosophy

**Aesthetic Direction**: Industrial/Editorial Hybrid
- Brutalist data-driven layouts with editorial refinement
- Monospace typography paired with refined serif accents
- High-contrast amber/charcoal color scheme suggesting analysis tools
- Dense information architecture with generous breathing room
- Trust signals through transparency and evidence-based reporting

## System Architecture

### Tech Stack
- **Framework**: Next.js 14 (App Router) + TypeScript
- **Database**: PostgreSQL + Prisma ORM
- **Deployment**: Vercel (serverless)
- **Styling**: Tailwind CSS + CSS variables for theming

### Serverless-Friendly Patterns

#### Job Processing Without Workers
```
User Request → Create Job Record → Return Job ID
             ↓
Frontend Polls Status
             ↓
/api/ingest/:jobId/run → Process Chunk → Update Progress
             ↓
Repeat until complete (each invocation is < 10s)
```

This pattern:
- Avoids Vercel's 10-60s function timeout
- No external queue needed for MVP
- Safe to call idempotently
- Graceful handling of cold starts

### Core Services

#### 1. Entity Resolution Service
- Fuzzy matching on business name + location
- Website domain normalisation
- Confidence scoring for matches
- Manual merge/confirm workflow

#### 2. Connector System (Extensible)
```typescript
interface SourceConnector {
  searchProfiles(query: SearchQuery): Promise<Profile[]>
  fetchReviews(profile: ProfileRef, pagination): Promise<Review[]>
  fetchSummary(profile: ProfileRef): Promise<Summary>
}
```

**MVP Connectors**:
- `CSVImportConnector`: Universal upload handler
- `TrustpilotDemoConnector`: Seeded demo data
- Extension points for Google, Feefo, etc.

#### 3. Scoring Service
**Normalisation**:
- 5-star → (stars/5) * 100
- 10-point → (rating/10) * 100
- Percentage → as-is
- Thumbs → 100 (up) or 0 (down)

**Recency Weighting**:
- Exponential decay with configurable half-life (default 90 days)
- `weight = exp(-ln(2) * days_old / half_life)`

**Confidence Calculation**:
- Wilson score interval on normalised rating distribution
- Penalise low sample sizes and high variance
- Output: 0-100 confidence score + explanation

#### 4. Signal Detection Service
**Algorithms**:
- **Similarity**: TF-IDF vectorisation + cosine similarity (threshold: 0.85)
- **Burst**: Sliding window (7 days), flag if >30% of reviews in window
- **Rating-Text Mismatch**: Sentiment analysis heuristic vs star rating
- **Phrase Repetition**: Top n-grams (3-5 words), flag if >20% contain same phrase
- **Incentive Language**: Keyword matching with context window

**Output Format**:
```
Signal: "Suspicious similarity cluster"
Confidence: 0.87
Evidence: [review_ids] with snippet previews
Explanation: "These reviews share 85%+ similar phrasing"
```

### Database Schema

#### Core Entities
```
Business (canonical)
  ├─ Profiles (1:many) - one per source
  │    └─ Reviews (1:many)
  ├─ ScoreSnapshots (time-series)
  └─ Signals (detected anomalies)

IngestJob (async processing)
  ├─ status: pending | processing | completed | failed
  ├─ progress: { current, total, errors }
  └─ linked to Profiles
```

### API Design

**RESTful with Job Pattern**:
```
POST /api/businesses/resolve
  → { businessId, confidence, possibleMatches[] }

POST /api/businesses/:id/ingest
  → { jobId } (starts background ingestion)

POST /api/ingest/:jobId/run
  → { status, progress } (processes chunk)

GET /api/ingest/:jobId
  → { status, progress, errors }
```

### Frontend Architecture

**Pages** (`/app`):
- `/` - Search + recent activity
- `/businesses/[id]` - Overview dashboard
- `/businesses/[id]/reviews` - Filterable table
- `/businesses/[id]/profiles/[profileId]` - Source detail
- `/settings` - Connectors + scoring config
- `/report/[id]` - Print-friendly report

**Components**:
- Modular connector cards
- Reusable signal badges
- Score breakdown visualisations
- Job progress indicators

### Security Considerations

**MVP Scope** (No Auth):
- Rate limiting via edge middleware
- Input validation with Zod
- SQL injection prevention via Prisma
- XSS prevention via Next.js automatic escaping

**Phase 2**:
- Multi-tenant with row-level security
- API key authentication
- Webhook signatures for connectors

### Performance Optimisations

- Database indices on foreign keys, timestamps
- Partial indices for active jobs
- Review pagination (50 per page)
- Static generation for report pages (ISR)
- Edge caching for aggregated scores

### Monitoring & Observability

**MVP**:
- Job error logging in database
- Console logging with structured format
- Vercel Analytics integration ready

**Phase 2**:
- OpenTelemetry tracing
- Error tracking (Sentry)
- Performance monitoring
- Anomaly detection on ingestion patterns

## Deployment Flow

1. **Local Development**:
   ```bash
   npm install
   npx prisma migrate dev
   npm run seed
   npm run dev
   ```

2. **Vercel Deployment**:
   ```bash
   vercel
   # Configure DATABASE_URL in environment variables
   # Run migrations via Vercel CLI or seed job
   ```

3. **Database Migration Strategy**:
   - Use Prisma Migrate in development
   - Shadow database for production migrations
   - Manual review of migration SQL

## Testing Strategy (MVP Scope)

- **Manual QA**: Core user flows
- **Data Validation**: Seed script exercises all connectors
- **Edge Cases**: Empty states, error handling

**Phase 2**:
- Unit tests for scoring algorithms
- Integration tests for connectors
- E2E tests with Playwright
- Load testing for job processing

## Extensibility Points

### Adding a New Connector
1. Implement `SourceConnector` interface
2. Register in `/lib/connectors/registry.ts`
3. Add configuration UI in settings
4. Create migration for source-specific metadata

### Adding New Signal Types
1. Extend `SignalType` enum in Prisma
2. Implement detection in `/lib/services/signals.ts`
3. Add explanation templates
4. Update UI badge rendering

### Scaling Beyond MVP
- Replace job polling with webhooks
- Introduce message queue (BullMQ, Inngest)
- Separate analytics into OLAP database
- Implement vector search for similarity (pgvector)
- Add real-time updates via WebSockets
