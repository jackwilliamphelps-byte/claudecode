#!/bin/bash

# Create all API route directories
mkdir -p app/api/businesses/\[id\]/{score,reviews,signals,ingest}
mkdir -p app/api/ingest/\[jobId\]
mkdir -p app/api/{sources,import/csv}

# Business [id] route
cat > app/api/businesses/\[id\]/route.ts << 'EOF'
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
EOF

# Score route
cat > app/api/businesses/\[id\]/score/route.ts << 'EOF'
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
EOF

# Reviews route
cat > app/api/businesses/\[id\]/reviews/route.ts << 'EOF'
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
EOF

# Signals route
cat > app/api/businesses/\[id\]/signals/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { SignalDetectionService } from '@/lib/services/signals';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    // Check for existing signals
    const existingSignals = await prisma.signal.findMany({
      where: { businessId: params.id },
      include: {
        evidence: {
          include: {
            review: {
              select: {
                id: true,
                text: true,
                authorName: true,
                reviewDate: true,
              },
            },
          },
        },
      },
    });

    if (existingSignals.length > 0) {
      const formatted = existingSignals.map(signal => ({
        type: signal.type,
        title: signal.title,
        explanation: signal.explanation,
        confidence: signal.confidence,
        evidence: signal.evidence.map(e => ({
          reviewId: e.reviewId,
          snippet: e.snippet,
        })),
        evidenceSummary: signal.evidenceSummary,
      }));
      return NextResponse.json({ signals: formatted });
    }

    // Detect signals if none exist
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
EOF

# Ingest route
cat > app/api/businesses/\[id\]/ingest/route.ts << 'EOF'
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
EOF

# Job status route
cat > app/api/ingest/\[jobId\]/route.ts << 'EOF'
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
EOF

# Sources route
cat > app/api/sources/route.ts << 'EOF'
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
EOF

echo "✅ All API routes created!"
