#!/bin/bash

# Ultimate Review Platform - Complete File Generation Script
# This script creates all necessary API routes and configuration files

cd "$(dirname "$0")"

echo "🚀 Generating Ultimate Review Platform files..."

# Create directory structure
mkdir -p app/api/businesses/\[id\]/{ingest,score,reviews,signals,profiles/\[profileId\]}
mkdir -p app/api/{ingest/\[jobId\],sources,import/csv}
mkdir -p app/{businesses/\[id\],settings,report/\[id\]}
mkdir -p app/businesses/\[id\]/{reviews,profiles/\[profileId\]}
mkdir -p components/{ui,business,signals}
mkdir -p lib/{utils,types}

echo "✅ Directory structure created"

# Generate Next.js config
cat > next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: {
      bodySizeLimit: '10mb',
    },
  },
};

module.exports = nextConfig;
NEXTCONFIG

# Generate TypeScript config
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIG

# Generate Tailwind config
cat > tailwind.config.ts << 'TAILWIND'
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        amber: {
          50: '#fffbeb',
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          400: '#fbbf24',
          500: '#f59e0b',
          600: '#d97706',
          700: '#b45309',
          800: '#92400e',
          900: '#78350f',
        },
      },
      fontFamily: {
        mono: ['IBM Plex Mono', 'Courier New', 'monospace'],
        serif: ['Lora', 'Georgia', 'serif'],
      },
    },
  },
  plugins: [],
};
export default config;
TAILWIND

# Generate PostCSS config
cat > postcss.config.js << 'POSTCSS'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
POSTCSS

# Generate .env.example
cat > .env.example << 'ENVEXAMPLE'
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/review_platform"

# Optional: Source API Keys
TRUSTPILOT_API_KEY=""
GOOGLE_PLACES_API_KEY=""
FEEFO_API_KEY=""
ENVEXAMPLE

# Generate .gitignore
cat > .gitignore << 'GITIGNORE'
# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
GITIGNORE

echo "✅ Configuration files created"
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. npm install"
echo "2. Set DATABASE_URL in .env"
echo "3. npx prisma migrate dev"
echo "4. npm run seed"
echo "5. npm run dev"
