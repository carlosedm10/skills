# Frontend Next reference

## Complete human-init command block

Copy-paste for the user:

```bash
# From repo root
bunx create-next-app@latest frontend \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-bun

cd frontend
bunx --bun shadcn@latest init
bun add lucide-react
bunx --bun shadcn@latest add button card
```

## Example src/app/page.tsx with shadcn + lucide

```tsx
import { Button } from "@/components/ui/button";
import { ArrowRight } from "lucide-react";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center">
      <h1 className="text-4xl font-bold">Welcome</h1>
      <Button className="mt-6">
        Get Started
        <ArrowRight className="ml-2 h-4 w-4" />
      </Button>
    </main>
  );
}
```
