# API Routes Implementation Guide

This file contains all API route implementations. Create each file in the specified path.

## 1. /app/api/businesses/[id]/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const business = await prisma.business.findUnique({
      where: { id: params.id },
      include: {
        profiles: {
          include: {
            _count: { select: { reviews: true } },
          },
        },
      },
    });

    if (!business) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 });
    }

    return NextResponse.json(business);
  } catch (error) {
    console.error('Get business error:', error);
    return NextResponse.json({ error: 'Failed to fetch business' }, { status: 500 });
  }
}
```

## 2. /app/api/businesses/[id]/score/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { ScoringService } from '@/lib/services/scoring';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const scoringService = new ScoringService();
    const result = await scoringService.calculateBusinessScore(params.id);
    return NextResponse.json(result);
  } catch (error) {
    console.error('Score calculation error:', error);
    return NextResponse.json({ error: 'Failed to calculate score' }, { status: 500 });
  }
}
```

## 3. /app/api/businesses/[id]/reviews/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '50');
    const source = searchParams.get('source');
    const minRating = searchParams.get('minRating');
    const maxRating = searchParams.get('maxRating');

    const skip = (page - 1) * limit;

    const where: any = {
      profile: { businessId: params.id },
    };

    if (source) {
      where.profile = { ...where.profile, source };
    }

    if (minRating || maxRating) {
      where.ratingNormalised = {};
      if (minRating) where.ratingNormalised.gte = parseFloat(minRating);
      if (maxRating) where.ratingNormalised.lte = parseFloat(maxRating);
    }

    const [reviews, total] = await Promise.all([
      prisma.review.findMany({
        where,
        include: {
          profile: { select: { source: true, displayName: true } },
        },
        orderBy: { reviewDate: 'desc' },
        skip,
        take: limit,
      }),
      prisma.review.count({ where }),
    ]);

    return NextResponse.json({
      reviews,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Get reviews error:', error);
    return NextResponse.json({ error: 'Failed to fetch reviews' }, { status: 500 });
  }
}
```

## 4. /app/api/businesses/[id]/signals/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { SignalDetectionService } from '@/lib/services/signals';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const signalService = new SignalDetectionService();
    const signals = await signalService.detectSignals(params.id);
    return NextResponse.json({ signals });
  } catch (error) {
    console.error('Signal detection error:', error);
    return NextResponse.json({ error: 'Failed to detect signals' }, { status: 500 });
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const signalService = new SignalDetectionService();
    const signals = await signalService.detectSignals(params.id);
    await signalService.saveSignals(params.id, signals);
    return NextResponse.json({ success: true, count: signals.length });
  } catch (error) {
    console.error('Save signals error:', error);
    return NextResponse.json({ error: 'Failed to save signals' }, { status: 500 });
  }
}
```

## 5. /app/api/businesses/[id]/ingest/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';

const prisma = new PrismaClient();

const ingestSchema = z.object({
  profileId: z.string().optional(),
  source: z.string(),
  config: z.record(z.any()).optional(),
});

export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json();
    const data = ingestSchema.parse(body);

    // Create ingestion job
    const job = await prisma.ingestJob.create({
      data: {
        profileId: data.profileId,
        source: data.source,
        status: 'pending',
        progress: { current: 0, total: 0, errors: [] },
        config: data.config || {},
      },
    });

    return NextResponse.json({ jobId: job.id });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Invalid request', details: error.errors },
        { status: 400 }
      );
    }
    console.error('Create ingest job error:', error);
    return NextResponse.json({ error: 'Failed to create job' }, { status: 500 });
  }
}
```

## 6. /app/api/ingest/[jobId]/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(
  request: NextRequest,
  { params }: { params: { jobId: string } }
) {
  try {
    const job = await prisma.ingestJob.findUnique({
      where: { id: params.jobId },
      include: {
        profile: {
          include: {
            business: { select: { name: true } },
          },
        },
      },
    });

    if (!job) {
      return NextResponse.json({ error: 'Job not found' }, { status: 404 });
    }

    return NextResponse.json(job);
  } catch (error) {
    console.error('Get job error:', error);
    return NextResponse.json({ error: 'Failed to fetch job' }, { status: 500 });
  }
}
```

## 7. /app/api/ingest/[jobId]/run/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import { getConnector } from '@/lib/connectors';

const prisma = new PrismaClient();
const CHUNK_SIZE = 50; // Process 50 reviews per invocation

export async function POST(
  request: NextRequest,
  { params }: { params: { jobId: string } }
) {
  try {
    const job = await prisma.ingestJob.findUnique({
      where: { id: params.jobId },
      include: { profile: true },
    });

    if (!job) {
      return NextResponse.json({ error: 'Job not found' }, { status: 404 });
    }

    if (job.status === 'completed') {
      return NextResponse.json({ status: 'completed', progress: job.progress });
    }

    if (job.status === 'failed') {
      return NextResponse.json({ status: 'failed', progress: job.progress });
    }

    // Update status to processing
    if (job.status === 'pending') {
      await prisma.ingestJob.update({
        where: { id: job.id },
        data: { status: 'processing', startedAt: new Date() },
      });
    }

    // Get connector
    const connector = getConnector(job.source);
    if (!connector) {
      await prisma.ingestJob.update({
        where: { id: job.id },
        data: {
          status: 'failed',
          progress: { current: 0, total: 0, errors: [`Connector ${job.source} not found`] },
        },
      });
      return NextResponse.json({ error: 'Connector not available' }, { status: 400 });
    }

    if (!job.profile) {
      await prisma.ingestJob.update({
        where: { id: job.id },
        data: {
          status: 'failed',
          progress: { current: 0, total: 0, errors: ['No profile linked to job'] },
        },
      });
      return NextResponse.json({ error: 'No profile linked' }, { status: 400 });
    }

    // Calculate current page
    const progress = job.progress as any;
    const currentPage = Math.floor(progress.current / CHUNK_SIZE) + 1;

    // Fetch next chunk of reviews
    const result = await connector.fetchReviews(
      { externalId: job.profile.externalId },
      { page: currentPage, limit: CHUNK_SIZE }
    );

    // Save reviews to database
    for (const reviewData of result.data) {
      await prisma.review.upsert({
        where: {
          profileId_externalId: {
            profileId: job.profile.id,
            externalId: reviewData.externalId,
          },
        },
        update: {
          authorName: reviewData.authorName,
          title: reviewData.title,
          text: reviewData.text,
          ratingOriginal: reviewData.ratingOriginal,
          ratingNormalised: reviewData.ratingNormalised,
          ratingType: reviewData.ratingType,
          reviewDate: reviewData.reviewDate,
          verifiedPurchase: reviewData.verifiedPurchase || false,
          metadata: reviewData.metadata || {},
        },
        create: {
          profileId: job.profile.id,
          externalId: reviewData.externalId,
          authorName: reviewData.authorName,
          title: reviewData.title,
          text: reviewData.text,
          ratingOriginal: reviewData.ratingOriginal,
          ratingNormalised: reviewData.ratingNormalised,
          ratingType: reviewData.ratingType,
          reviewDate: reviewData.reviewDate,
          verifiedPurchase: reviewData.verifiedPurchase || false,
          metadata: reviewData.metadata || {},
        },
      });
    }

    // Update progress
    const newProgress = {
      current: progress.current + result.data.length,
      total: result.pagination.total || progress.current + result.data.length,
      errors: progress.errors || [],
    };

    const isComplete = !result.pagination.hasMore;

    await prisma.ingestJob.update({
      where: { id: job.id },
      data: {
        status: isComplete ? 'completed' : 'processing',
        progress: newProgress,
        completedAt: isComplete ? new Date() : undefined,
      },
    });

    return NextResponse.json({
      status: isComplete ? 'completed' : 'processing',
      progress: newProgress,
      hasMore: result.pagination.hasMore,
    });
  } catch (error) {
    console.error('Job run error:', error);
    
    // Update job with error
    await prisma.ingestJob.update({
      where: { id: params.jobId },
      data: {
        status: 'failed',
        progress: {
          current: 0,
          total: 0,
          errors: [error instanceof Error ? error.message : 'Unknown error'],
        },
      },
    }).catch(console.error);

    return NextResponse.json({ error: 'Job execution failed' }, { status: 500 });
  }
}
```

## 8. /app/api/sources/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import { getAllConnectors } from '@/lib/connectors';

const prisma = new PrismaClient();

export async function GET(request: NextRequest) {
  try {
    const connectors = getAllConnectors();
    const configs = await prisma.connectorConfig.findMany();

    const sources = connectors.map(connector => {
      const config = configs.find(c => c.source === connector.source);
      return {
        source: connector.source,
        name: connector.name,
        enabled: config?.enabled || false,
        status: config?.status || 'unconfigured',
      };
    });

    return NextResponse.json({ sources });
  } catch (error) {
    console.error('Get sources error:', error);
    return NextResponse.json({ error: 'Failed to fetch sources' }, { status: 500 });
  }
}
```

## 9. /app/api/import/csv/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import { CSVImportConnector } from '@/lib/connectors/csv-import';

const prisma = new PrismaClient();

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const businessId = formData.get('businessId') as string;
    const mapping = JSON.parse(formData.get('mapping') as string);

    if (!file || !businessId) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    const csvContent = await file.text();

    // Create or find CSV import profile
    let profile = await prisma.profile.findFirst({
      where: {
        businessId,
        source: 'csv_import',
        displayName: file.name,
      },
    });

    if (!profile) {
      profile = await prisma.profile.create({
        data: {
          businessId,
          source: 'csv_import',
          externalId: `csv-${Date.now()}`,
          displayName: file.name,
          claimedStatus: 'unknown',
          matchConfidence: 1.0,
          discoveryMethod: 'upload',
        },
      });
    }

    // Create ingestion job
    const job = await prisma.ingestJob.create({
      data: {
        profileId: profile.id,
        source: 'csv_import',
        status: 'pending',
        progress: { current: 0, total: 0, errors: [] },
        config: { mapping, fileName: file.name },
      },
    });

    // Start processing (in a real app, this would be async)
    const connector = new CSVImportConnector({
      file: csvContent,
      mapping,
      profileExternalId: profile.externalId,
    });

    const result = await connector.fetchReviews({ externalId: profile.externalId });

    // Save reviews
    for (const reviewData of result.data) {
      await prisma.review.create({
        data: {
          profileId: profile.id,
          externalId: reviewData.externalId,
          authorName: reviewData.authorName,
          title: reviewData.title,
          text: reviewData.text,
          ratingOriginal: reviewData.ratingOriginal,
          ratingNormalised: reviewData.ratingNormalised,
          ratingType: reviewData.ratingType,
          reviewDate: reviewData.reviewDate,
          verifiedPurchase: reviewData.verifiedPurchase || false,
          metadata: reviewData.metadata || {},
        },
      });
    }

    // Complete job
    await prisma.ingestJob.update({
      where: { id: job.id },
      data: {
        status: 'completed',
        progress: { current: result.data.length, total: result.data.length, errors: [] },
        completedAt: new Date(),
      },
    });

    return NextResponse.json({
      success: true,
      jobId: job.id,
      profileId: profile.id,
      reviewCount: result.data.length,
    });
  } catch (error) {
    console.error('CSV import error:', error);
    return NextResponse.json(
      { error: 'Failed to import CSV', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
```

---

## Implementation Instructions

1. Create each file at the specified path
2. Ensure all imports reference correct paths (@/ is project root)
3. Run `npm install` to get all dependencies
4. Test each endpoint with the seeded database
5. Frontend pages will consume these API endpoints

All routes follow RESTful conventions and include proper error handling.
