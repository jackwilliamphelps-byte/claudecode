#!/bin/bash

# Business resolve route
mkdir -p app/api/businesses/resolve
cat > app/api/businesses/resolve/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { EntityResolutionService } from '@/lib/services/entity-resolution';

const resolveSchema = z.object({
  name: z.string().min(1),
  website: z.string().optional(),
  postcode: z.string().optional(),
  city: z.string().optional(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const data = resolveSchema.parse(body);
    const resolver = new EntityResolutionService();
    const result = await resolver.resolve(data);
    return NextResponse.json(result);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid request data', details: error.errors }, { status: 400 });
    }
    console.error('Business resolve error:', error);
    return NextResponse.json({ error: 'Failed to resolve business' }, { status: 500 });
  }
}
EOF

echo "Created: app/api/businesses/resolve/route.ts"
