---
scope: next.js
module: image-rendering
date: 2026-02-22
problem_type: runtime-error
symptoms: SVG logo appears blurry/soft on retina/HiDPI displays when using next/image
root_cause: incorrect-assumption
severity: low
tags: [nextjs, svg, retina, hidpi, next-image, image-optimization]
is_bug_fix: true
has_regression_test: false
regression_test_status: skipped
---

# SVG Blurry on Retina Displays with next/image

## Symptom

SVG logos and icons rendered via Next.js `<Image>` component appear slightly blurry or soft on retina/HiDPI displays, even with `unoptimized` prop set.

## Investigation

1. Checked SVG file contents — pure vector `<path>` elements, no embedded rasters
2. Reviewed `<Image>` props — `width={1024} height={1024} unoptimized priority`
3. Container constrains display to `w-48` (192px) via Tailwind — well within SVG resolution
4. SVGs should scale perfectly at any size, so the issue is in rendering, not the asset

## Root Cause

`next/image` wraps `<img>` elements in a `<span>` container and applies internal CSS (position, inset, sub-pixel sizing calculations). For SVG assets, this wrapper can cause the browser to rasterize at CSS pixel dimensions rather than device pixel dimensions on retina screens.

The `unoptimized` flag disables Next.js image optimization (srcset, format conversion) but does NOT remove the wrapper markup — so the rendering artifact persists.

SVGs don't benefit from Next.js image optimization at all: no srcset needed (vector scales infinitely), no format conversion (SVG is already optimal), no lazy loading benefit for small logos.

## Solution

Replace `next/image` `<Image>` with plain `<img>` tags for all SVG assets.

**Before:**
```tsx
import Image from "next/image";

<Image
  src="/brand/logo.svg"
  alt="Logo"
  width={1024}
  height={1024}
  priority
  unoptimized
  className="h-auto w-full"
/>
```

**After:**
```tsx
<img
  src="/brand/logo.svg"
  alt="Logo"
  className="h-auto w-full"
/>
```

Add ESLint disable if needed:
```tsx
/* eslint-disable @next/next/no-img-element -- SVGs don't benefit from next/image; plain <img> avoids retina blur */
```

## Prevention

- **Rule:** Always use `<img>` for SVG assets in Next.js. Reserve `<Image>` for raster formats (PNG, JPG, WebP).
- **Detection:** `grep -r "<Image.*\.svg" --include="*.tsx"` — any match is a potential issue.
- **Code review:** If you see `next/image` with an SVG src, flag it.

## Related

- Next.js docs recommend `next/image` for raster optimization, but don't clearly state SVGs are better served by plain `<img>`.
