# Frontend Components Reference

This file documents all React components needed to complete the MVP. Create each component in the specified path.

## Core Components

### 1. ScoreCard Component
**Path:** `components/business/ScoreCard.tsx`

```typescript
'use client';

interface ScoreCardProps {
  score: number;
  confidence: number;
  confidenceExplanation: string;
  reviewCount: number;
  trend?: {
    direction: 'up' | 'down' | 'stable';
    change: number;
  };
}

export default function ScoreCard({ score, confidence, confidenceExplanation, reviewCount, trend }: ScoreCardProps) {
  const getScoreColor = (score: number) => {
    if (score >= 80) return 'text-emerald-500';
    if (score >= 60) return 'text-amber-500';
    return 'text-red-500';
  };

  const getTrendIcon = () => {
    if (!trend) return null;
    if (trend.direction === 'up') return '↗';
    if (trend.direction === 'down') return '↘';
    return '→';
  };

  return (
    <div className="stat-card">
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="text-sm font-medium text-neutral-400 mb-1">Overall Score</h3>
          <div className={`text-5xl font-bold ${getScoreColor(score)}`}>
            {score.toFixed(1)}
            <span className="text-2xl text-neutral-500">/100</span>
          </div>
        </div>
        {trend && (
          <div className="text-right">
            <span className="text-2xl">{getTrendIcon()}</span>
            <div className="text-sm text-neutral-400">{Math.abs(trend.change).toFixed(1)}%</div>
          </div>
        )}
      </div>
      
      <div className="space-y-2">
        <div className="flex items-center justify-between text-sm">
          <span className="text-neutral-400">Confidence</span>
          <span className={`font-semibold ${confidence >= 70 ? 'text-emerald-500' : 'text-amber-500'}`}>
            {confidence.toFixed(0)}%
          </span>
        </div>
        <div className="w-full bg-neutral-800 rounded-full h-2">
          <div
            className={`h-2 rounded-full transition-all duration-500 ${
              confidence >= 70 ? 'bg-emerald-600' : 'bg-amber-600'
            }`}
            style={{ width: `${confidence}%` }}
          />
        </div>
        <p className="text-xs text-neutral-500">{confidenceExplanation}</p>
      </div>

      <div className="mt-4 pt-4 border-t border-neutral-800">
        <div className="flex items-center justify-between text-sm">
          <span className="text-neutral-400">Total Reviews</span>
          <span className="font-semibold text-neutral-200">{reviewCount}</span>
        </div>
      </div>
    </div>
  );
}
```

### 2. SourceBreakdown Component
**Path:** `components/business/SourceBreakdown.tsx`

```typescript
'use client';

interface Source {
  source: string;
  displayName: string;
  score: number;
  reviewCount: number;
}

interface SourceBreakdownProps {
  sources: Source[];
}

const sourceIcons: Record<string, string> = {
  trustpilot: '⭐',
  google: '🔍',
  feefo: '✓',
  csv_import: '📄',
};

export default function SourceBreakdown({ sources }: SourceBreakdownProps) {
  return (
    <div className="card">
      <h3 className="section-title">Source Breakdown</h3>
      <div className="space-y-4">
        {sources.map((source) => (
          <div key={source.source} className="flex items-center gap-4">
            <div className="text-2xl">{sourceIcons[source.source] || '📊'}</div>
            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm font-medium text-neutral-200">{source.displayName}</span>
                <span className="text-sm font-semibold text-amber-500">{source.score.toFixed(1)}</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex-1 bg-neutral-800 rounded-full h-1.5">
                  <div
                    className="h-1.5 rounded-full bg-amber-600 transition-all duration-500"
                    style={{ width: `${source.score}%` }}
                  />
                </div>
                <span className="text-xs text-neutral-500">{source.reviewCount} reviews</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 3. SignalBadge Component
**Path:** `components/signals/SignalBadge.tsx`

```typescript
interface SignalBadgeProps {
  type: string;
  title: string;
  confidence: number;
  count?: number;
}

const signalConfig: Record<string, { icon: string; colorClass: string }> = {
  similarity_cluster: { icon: '🔄', colorClass: 'badge-warning' },
  burst: { icon: '📈', colorClass: 'badge-warning' },
  rating_mismatch: { icon: '⚠️', colorClass: 'badge-danger' },
  phrase_repetition: { icon: '💬', colorClass: 'badge-warning' },
  incentive_language: { icon: '💰', colorClass: 'badge-danger' },
};

export default function SignalBadge({ type, title, confidence, count }: SignalBadgeProps) {
  const config = signalConfig[type] || { icon: '🔍', colorClass: 'badge-neutral' };

  return (
    <div className={`badge ${config.colorClass} flex items-center gap-2`}>
      <span>{config.icon}</span>
      <span>{title}</span>
      {count && <span className="ml-1">({count})</span>}
      <span className="text-xs opacity-75">{Math.round(confidence * 100)}%</span>
    </div>
  );
}
```

### 4. ReviewTable Component
**Path:** `components/business/ReviewTable.tsx`

```typescript
'use client';

import { useState } from 'react';
import SignalBadge from '../signals/SignalBadge';

interface Review {
  id: string;
  authorName?: string;
  title?: string;
  text?: string;
  ratingNormalised: number;
  reviewDate: Date;
  profile: {
    source: string;
    displayName: string;
  };
}

interface ReviewTableProps {
  reviews: Review[];
  onLoadMore?: () => void;
  hasMore?: boolean;
}

export default function ReviewTable({ reviews, onLoadMore, hasMore }: ReviewTableProps) {
  const [filter, setFilter] = useState<string>('all');

  const getRatingColor = (rating: number) => {
    if (rating >= 80) return 'text-emerald-500';
    if (rating >= 60) return 'text-amber-500';
    return 'text-red-500';
  };

  return (
    <div className="card">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-semibold text-neutral-300">Reviews</h3>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="input w-48"
        >
          <option value="all">All Sources</option>
          <option value="trustpilot">Trustpilot</option>
          <option value="google">Google</option>
          <option value="feefo">Feefo</option>
        </select>
      </div>

      <div className="space-y-4">
        {reviews.map((review) => (
          <div key={review.id} className="border-b border-neutral-800 pb-4 last:border-0">
            <div className="flex items-start justify-between mb-2">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-1">
                  <span className="text-sm font-medium text-neutral-200">
                    {review.authorName || 'Anonymous'}
                  </span>
                  <span className="badge badge-neutral text-xs">{review.profile.source}</span>
                </div>
                {review.title && (
                  <h4 className="text-sm font-medium text-neutral-300 mb-1">{review.title}</h4>
                )}
              </div>
              <div className="text-right">
                <div className={`text-lg font-semibold ${getRatingColor(review.ratingNormalised)}`}>
                  {review.ratingNormalised.toFixed(0)}
                </div>
                <div className="text-xs text-neutral-500">
                  {new Date(review.reviewDate).toLocaleDateString('en-GB')}
                </div>
              </div>
            </div>
            {review.text && (
              <p className="text-sm text-neutral-400 leading-relaxed">{review.text}</p>
            )}
          </div>
        ))}
      </div>

      {hasMore && onLoadMore && (
        <div className="mt-6 text-center">
          <button onClick={onLoadMore} className="btn btn-secondary">
            Load More Reviews
          </button>
        </div>
      )}
    </div>
  );
}
```

### 5. Business Detail Page
**Path:** `app/businesses/[id]/page.tsx`

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import ScoreCard from '@/components/business/ScoreCard';
import SourceBreakdown from '@/components/business/SourceBreakdown';
import ReviewTable from '@/components/business/ReviewTable';
import SignalBadge from '@/components/signals/SignalBadge';

export default function BusinessDetailPage() {
  const params = useParams();
  const [business, setBusiness] = useState<any>(null);
  const [score, setScore] = useState<any>(null);
  const [reviews, setReviews] = useState<any[]>([]);
  const [signals, setSignals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [businessRes, scoreRes, reviewsRes, signalsRes] = await Promise.all([
          fetch(`/api/businesses/${params.id}`),
          fetch(`/api/businesses/${params.id}/score`),
          fetch(`/api/businesses/${params.id}/reviews`),
          fetch(`/api/businesses/${params.id}/signals`),
        ]);

        setBusiness(await businessRes.json());
        setScore(await scoreRes.json());
        const reviewData = await reviewsRes.json();
        setReviews(reviewData.reviews);
        const signalData = await signalsRes.json();
        setSignals(signalData.signals);
      } catch (error) {
        console.error('Failed to fetch business data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [params.id]);

  if (loading) {
    return (
      <div className="container mx-auto px-6 py-12">
        <div className="max-w-6xl mx-auto">
          <div className="animate-pulse space-y-8">
            <div className="h-12 bg-neutral-800 rounded w-1/3"></div>
            <div className="h-64 bg-neutral-800 rounded"></div>
          </div>
        </div>
      </div>
    );
  }

  if (!business || !score) {
    return (
      <div className="container mx-auto px-6 py-12">
        <div className="max-w-6xl mx-auto text-center">
          <h2 className="text-2xl font-bold text-neutral-300 mb-4">Business not found</h2>
          <a href="/" className="btn btn-primary">Return Home</a>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-6 py-12">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-neutral-100 mb-2">{business.name}</h1>
          {business.website && (
            <a
              href={business.website}
              target="_blank"
              rel="noopener noreferrer"
              className="text-amber-500 hover:text-amber-400 text-sm"
            >
              {business.website}
            </a>
          )}
          {business.city && (
            <p className="text-sm text-neutral-400 mt-1">
              {business.city}, {business.postcode}
            </p>
          )}
        </div>

        {/* Signals Alert */}
        {signals.length > 0 && (
          <div className="card border-amber-600/30 mb-8">
            <div className="flex items-start gap-4">
              <div className="text-2xl">⚠️</div>
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-neutral-200 mb-3">
                  Suspicious Signals Detected
                </h3>
                <div className="flex flex-wrap gap-2">
                  {signals.map((signal, idx) => (
                    <SignalBadge
                      key={idx}
                      type={signal.type}
                      title={signal.title}
                      confidence={signal.confidence}
                    />
                  ))}
                </div>
                <p className="text-sm text-neutral-400 mt-3">
                  These signals are consistent with suspicious review patterns. Click each to view evidence.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Score Dashboard */}
        <div className="grid md:grid-cols-2 gap-6 mb-8">
          <ScoreCard
            score={score.overallScore}
            confidence={score.confidence}
            confidenceExplanation={score.confidenceExplanation}
            reviewCount={score.reviewCount}
            trend={score.trend}
          />
          <SourceBreakdown sources={score.sourceBreakdown} />
        </div>

        {/* Profiles */}
        <div className="card mb-8">
          <h3 className="section-title">Connected Profiles</h3>
          <div className="space-y-3">
            {business.profiles.map((profile: any) => (
              <div key={profile.id} className="flex items-center justify-between p-3 bg-neutral-800/50 rounded">
                <div>
                  <div className="text-sm font-medium text-neutral-200">{profile.displayName}</div>
                  <div className="text-xs text-neutral-500 mt-1">
                    {profile.source} • {profile._count.reviews} reviews
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {profile.claimedStatus === 'claimed' && (
                    <span className="badge badge-success text-xs">Claimed</span>
                  )}
                  {profile.claimedStatus === 'unclaimed' && (
                    <span className="badge badge-warning text-xs">Unclaimed</span>
                  )}
                  {profile.externalUrl && (
                    <a
                      href={profile.externalUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-amber-500 hover:text-amber-400 text-xs"
                    >
                      View →
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Reviews */}
        <ReviewTable reviews={reviews} />
      </div>
    </div>
  );
}
```

## Implementation Checklist

Create each file at the specified path:
- [ ] ScoreCard.tsx
- [ ] SourceBreakdown.tsx
- [ ] SignalBadge.tsx
- [ ] ReviewTable.tsx
- [ ] Business detail page
- [ ] Settings page (connector management)
- [ ] Report page (print view)

All components use the industrial/editorial design system defined in globals.css.
