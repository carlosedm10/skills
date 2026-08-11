---
name: frontend-next
description: Scaffolds Next.js landing pages with Bun, shadcn/ui, and lucide-react icons. Official create commands are human-only — the agent provides exact bun commands and configures shadcn after init. Use when creating Next.js landings or when project-scaffold selects Next over React.
---

# Frontend Next

## When to use

- Landing pages and marketing sites
- Projects needing SSR, SSG, or App Router features
- SEO-critical public-facing pages

Use **frontend-react** for interactive webapps and SPAs that do not need SSR.

## Stack

| Tool | Purpose |
|------|---------|
| Bun | Package manager and runtime |
| Next.js (App Router) + TypeScript | Framework |
| shadcn/ui | Component library |
| lucide-react | Icons |
| Tailwind CSS | Styling (installed via shadcn) |

## Directory layout (after human init)

```
frontend/
├── package.json
├── bun.lock
├── tsconfig.json
├── next.config.ts
├── components.json        # shadcn config
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── components/
│   │   └── ui/            # shadcn components
│   └── lib/
│       └── utils.ts
└── public/
```

## Scaffold workflow

### Phase 1 — Agent prepares

1. **Create** empty `frontend/` directory at repo root (if not exists).
2. **Print** the human-init commands below — do NOT execute them.

### Phase 2 — Human runs official create command

Provide these exact commands for the user:

```bash
# From repo root — creates frontend/ with Next.js App Router + TS
bunx create-next-app@latest frontend --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-bun
```

When prompted interactively, recommend:
- TypeScript: **Yes**
- ESLint: **Yes**
- Tailwind CSS: **Yes**
- `src/` directory: **Yes**
- App Router: **Yes**
- Import alias `@/*`: **Yes**
- Bun: **Yes**

### Phase 3 — Agent continues after human init

Once the user confirms the Next project is created:

1. **Initialize shadcn**:

```bash
cd frontend
bunx --bun shadcn@latest init
```

Recommend:
- Style: **New York**
- Base color: project preference (default **Zinc**)
- CSS variables: **yes**

2. **Add lucide-react**:

```bash
bun add lucide-react
```

3. **Add common shadcn components** as needed:

```bash
bunx --bun shadcn@latest add button card
```

4. **Configure** `next.config.ts` for Docker dev if needed.
5. **Add** `lint` script to `package.json` (Next ships with `next lint`).

## next.config.ts (Docker-friendly)

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Allow Docker dev server
  ...(process.env.NODE_ENV === "development" && {
    webpackDevMiddleware: (config) => {
      config.watchOptions = {
        poll: 1000,
        aggregateTimeout: 300,
      };
      return config;
    },
  }),
};

export default nextConfig;
```

Update `package.json` dev script for Docker binding:

```json
{
  "scripts": {
    "dev": "next dev --hostname 0.0.0.0",
    "build": "next build",
    "lint": "next lint",
    "start": "next start"
  }
}
```

## Agent may write

- `next.config.ts` adjustments for Docker
- `components.json` after shadcn init
- Page components, layouts, API routes
- `package.json` script additions

## Agent must NOT execute

- `bunx create-next-app`
- `bunx shadcn init` / `bunx shadcn add`
- `bun install`

## Integration with sibling skills

| Skill | When |
|-------|------|
| dockerization-template | Next frontend Dockerfile, port `3000:3000` |
| makefile-operations | `bun-add`, `lint-frontend`, `test-frontend` |
| github-actions | CI calls `make lint` / `make test` |

## Additional resources

- Full command sequence: [reference.md](reference.md)
