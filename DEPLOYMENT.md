# Ultimate Review Platform - Complete Deployment Guide

## 📦 What's Included

This codebase contains a **production-ready MVP** with:

### ✅ Complete Backend
- Prisma schema with 10+ models
- 3 extensible connectors (Trustpilot Demo, CSV Import, Registry)
- 4 core services (Scoring, Signals, Entity Resolution, Ingestion)
- 9+ API endpoints (fully implemented)
- Seed script with 90 reviews across 3 businesses

### ✅ Core Frontend
- Next.js App Router with TypeScript
- Industrial/editorial design system
- Homepage with search
- Business detail page foundation
- Reusable components
- Global styles and animations

### ✅ Infrastructure
- Vercel-optimised serverless architecture
- Chunked job processing (no queue needed)
- Database migrations
- Configuration files

## 🎯 MVP Status

**What Works Out of the Box:**
- Business search and entity resolution
- Multi-source review aggregation
- Score calculation with recency weighting
- Confidence scoring (Wilson interval)
- Signal detection (5 algorithms)
- CSV import
- Job processing
- API endpoints

**What Needs Completion:**
The frontend is 60% complete. Remaining work:
- Complete business detail page components
- Settings page for connector management
- Report generation page
- Additional UI polish

**Estimated completion time:** 4-6 hours for experienced React developer

## 🚀 Immediate Deployment Path

### Option 1: Quick Deploy (Recommended)
```bash
# 1. Clone and install
git clone <repo>
cd review-platform
npm install

# 2. Set up database (choose one)
# A) Local PostgreSQL
# B) Vercel Postgres (vercel.com/dashboard)
# C) Supabase (supabase.com)
# D) Neon (neon.tech)

# 3. Configure environment
echo 'DATABASE_URL="postgresql://..."' > .env

# 4. Initialize database
npx prisma migrate dev
npm run seed

# 5. Test locally
npm run dev  # Visit http://localhost:3000

# 6. Deploy to Vercel
vercel --prod
```

### Option 2: Full Development Setup
```bash
# 1. Clone
git clone <repo>
cd review-platform

# 2. Install dependencies
npm install

# 3. Local PostgreSQL
createdb review_platform
echo 'DATABASE_URL="postgresql://localhost:5432/review_platform"' > .env

# 4. Database setup
npx prisma generate
npx prisma migrate dev --name init
npm run seed

# 5. Verify data
npx prisma studio  # Opens GUI at http://localhost:5555

# 6. Start dev server
npm run dev

# 7. Test API
curl http://localhost:3000/api/sources
curl http://localhost:3000/api/businesses/resolve \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"TechMart"}'

# 8. Deploy
vercel
```

## 📊 Testing the Demo Data

After seeding, you can test with:

1. **TechMart Electronics** (ID in database)
   - 40 reviews across Trustpilot, Google
   - Has suspicious signals (burst, similarity, incentive language)
   - 1 unclaimed duplicate profile

2. **GreenLeaf Organics** (ID in database)
   - 20 reviews on Trustpilot
   - Clean pattern, high ratings

3. **UrbanFit Gym** (ID in database)
   - 30 reviews across Google, Feefo
   - Has rating-text mismatches

### API Testing Examples
```bash
# Get business by ID (replace with actual ID from seed)
curl http://localhost:3000/api/businesses/<id>

# Calculate score
curl http://localhost:3000/api/businesses/<id>/score

# Get reviews
curl http://localhost:3000/api/businesses/<id>/reviews

# Detect signals
curl http://localhost:3000/api/businesses/<id>/signals
```

## 🔧 Environment Variables

### Required
```env
DATABASE_URL="postgresql://user:password@host:port/database"
```

### Optional (for Phase 2)
```env
TRUSTPILOT_API_KEY="your_key_here"
GOOGLE_PLACES_API_KEY="your_key_here"
FEEFO_API_KEY="your_key_here"
```

## 📁 Key Files to Understand

### Backend Core
1. `prisma/schema.prisma` - Database schema
2. `lib/connectors/types.ts` - Connector interface
3. `lib/services/scoring.ts` - Score calculation
4. `lib/services/signals.ts` - Pattern detection
5. `prisma/seed.ts` - Demo data

### API Layer
6. `app/api/businesses/resolve/route.ts` - Entity resolution
7. `app/api/businesses/[id]/score/route.ts` - Scoring
8. `app/api/ingest/[jobId]/run/route.ts` - Job processor

### Frontend
9. `app/layout.tsx` - Root layout with design system
10. `app/page.tsx` - Homepage
11. `app/globals.css` - Styling system

## 🎨 Design System Quick Reference

### Colors
- Primary: `amber-500` (#f59e0b)
- Background: `neutral-950` (#0a0a0a)
- Text: `neutral-100` (#f5f5f5)
- Borders: `neutral-800` (#262626)

### Components
```tsx
<button className="btn btn-primary">Action</button>
<div className="card">Content</div>
<span className="badge badge-warning">Label</span>
<input className="input" />
```

## 🐛 Common Issues & Solutions

### Issue: Prisma Client not generated
```bash
npx prisma generate
```

### Issue: Migration failed
```bash
npx prisma migrate reset  # WARNING: Deletes data
npx prisma migrate dev
```

### Issue: Seed script fails
```bash
# Check database connection
npx prisma studio

# Re-run seed
npm run seed
```

### Issue: TypeScript errors
```bash
npm run build  # Check for errors
rm -rf .next && npm run dev  # Clean rebuild
```

### Issue: Vercel deployment fails
1. Check DATABASE_URL is set in Vercel dashboard
2. Ensure migrations are applied: `vercel env pull && npx prisma migrate deploy`
3. Check build logs in Vercel dashboard

## 📈 Performance Optimization

### Database
```sql
-- Already included in schema:
-- Indices on foreign keys
-- Indices on query fields (name, postcode, reviewDate)

-- For production, add:
CREATE INDEX CONCURRENTLY idx_review_text ON "Review" USING GIN (to_tsvector('english', text));
```

### Caching
```typescript
// app/businesses/[id]/page.tsx
export const revalidate = 300; // 5 minutes

// For static export
export async function generateStaticParams() {
  const businesses = await prisma.business.findMany();
  return businesses.map((b) => ({ id: b.id }));
}
```

## 🔐 Security Hardening

### Rate Limiting
```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const rateLimit = new Map<string, number[]>();

export function middleware(request: NextRequest) {
  const ip = request.ip || 'anonymous';
  const now = Date.now();
  const windowMs = 60000; // 1 minute
  const maxRequests = 100;

  if (!rateLimit.has(ip)) {
    rateLimit.set(ip, []);
  }

  const requests = rateLimit.get(ip)!.filter(time => now - time < windowMs);
  requests.push(now);
  rateLimit.set(ip, requests);

  if (requests.length > maxRequests) {
    return new NextResponse('Too Many Requests', { status: 429 });
  }

  return NextResponse.next();
}
```

## 📊 Monitoring Setup

### Vercel Analytics
```bash
npm install @vercel/analytics
```

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

## 🚢 Production Checklist

Before launch:
- [ ] Database backups configured
- [ ] Environment variables set in Vercel
- [ ] Migrations applied to production database
- [ ] Error tracking enabled (Sentry)
- [ ] Analytics configured
- [ ] Rate limiting enabled
- [ ] HTTPS enforced
- [ ] Custom domain configured
- [ ] SEO meta tags added
- [ ] Privacy policy created
- [ ] Terms of service created
- [ ] API documentation published
- [ ] User testing completed

## 📞 Next Steps

1. **Complete Frontend** (4-6 hours)
   - Implement components from COMPONENTS.md
   - Add settings page
   - Create report generation

2. **Add Real Connectors** (8-16 hours)
   - Trustpilot API integration
   - Google Places API
   - Feefo API

3. **Authentication** (4-8 hours)
   - NextAuth.js setup
   - User model
   - Protected routes

4. **Job Queue** (4-8 hours)
   - Inngest or BullMQ
   - Scheduled re-ingestion
   - Webhook processing

5. **Advanced Features** (16-40 hours)
   - Vector similarity (pgvector)
   - Review response management
   - Competitive analysis
   - Custom reports

## 🎓 Learning Resources

- **Next.js**: https://nextjs.org/docs
- **Prisma**: https://www.prisma.io/docs
- **Vercel**: https://vercel.com/docs
- **TF-IDF**: https://en.wikipedia.org/wiki/Tf%E2%80%93idf
- **Wilson Score**: https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval

## 📝 File Manifest

Total files created: **25+**

### Configuration (6)
- package.json
- tsconfig.json
- tailwind.config.ts
- postcss.config.js
- next.config.js
- .env.example

### Database (2)
- prisma/schema.prisma
- prisma/seed.ts

### Services (4)
- lib/services/scoring.ts
- lib/services/signals.ts
- lib/services/entity-resolution.ts
- lib/connectors/* (4 files)

### API Routes (9+)
- app/api/businesses/resolve/route.ts
- app/api/businesses/[id]/route.ts
- app/api/businesses/[id]/score/route.ts
- app/api/businesses/[id]/reviews/route.ts
- app/api/businesses/[id]/signals/route.ts
- app/api/businesses/[id]/ingest/route.ts
- app/api/ingest/[jobId]/route.ts
- app/api/ingest/[jobId]/run/route.ts
- app/api/sources/route.ts
- app/api/import/csv/route.ts

### Frontend (4)
- app/layout.tsx
- app/page.tsx
- app/globals.css
- app/businesses/[id]/page.tsx (starter)

### Documentation (6)
- README.md
- ARCHITECTURE.md
- API_ROUTES.md
- COMPONENTS.md
- DEPLOYMENT.md (this file)
- setup.sh

---

**Status:** ✅ MVP Ready for Deployment
**Estimated Time to Production:** 2-4 hours (database + deploy)
**Estimated Time to Complete:** 10-20 hours (frontend + polish)

Built with ❤️ using Next.js, TypeScript, PostgreSQL, and Vercel.
