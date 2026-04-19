# Next.js Patterns Guide (Additions)

Next.js App Router-specific patterns that extend the universal React patterns in `PATTERNS-REACT.md`. **Current project: Next.js 16 + React 19 + NextAuth v5.**

> **Base patterns (Zod, forms, tables, mutations, skeletons, combobox, etc.)** are in `PATTERNS-REACT.md`.
> This file covers ONLY what's unique to Next.js projects.
>
> **Key Next.js 16 conventions used throughout:**
> - `params` / `searchParams` / `cookies()` / `headers()` are async — always `await`
> - `middleware.ts` → `proxy.ts` (exported function renamed `middleware` → `proxy`)
> - Metadata files (opengraph-image, icon) belong at the `app/` root, not in dynamic segments

---

## Quick Reference

### Extended Directory Layout (App Router)

Extends the React directory layout with Next.js-specific directories:

```
app/
  (auth)/
    login/page.tsx
    reset-password/page.tsx
  (dashboard)/
    {resource}s/
      page.tsx                         # List page (SSR)
      loading.tsx                      # Loading skeleton (automatic)
      create/
        page.tsx                       # Create page
      [{resource}Id]/
        page.tsx                       # Details page (optional)
        edit/
          page.tsx                     # Edit page
    error.tsx                          # Error boundary (shared)
  api/
    {resource}s/
      route.ts                         # GET (list) + POST (create)
      [{resource}Id]/
        route.ts                       # GET (detail) + PUT (update) + DELETE
    auth/
      [...nextauth]/route.ts           # NextAuth handler

config/
  {resource}s.ts                       # Page config (breadcrumb nav)

data/
  queries/
    {resource}s.ts                     # SSR fetch functions
  index.ts                             # Barrel re-exports

env.mjs                                # Type-safe env vars (@t3-oss/env-nextjs)
```

### Next.js-Specific Import Order

```tsx
// 1. React
import { useState, useTransition } from "react"

// 2. Next.js
import Link from "next/link"
import { useRouter, usePathname, useSearchParams } from "next/navigation"
import { getServerSession } from "next-auth"

// 3. Third-party (same as React patterns)
// 4. Internal aliases (same as React patterns)
// 5. Relative imports
// 6. Types
```

---

## Part 1: Foundation (Next.js Additions)

### 1.0 Async Request APIs (Next.js 16)

In Next.js 15+, the following are **Promises** and must be `await`ed:
- `params` — in pages, layouts, and API route handlers
- `searchParams` — in pages
- `cookies()` and `headers()` — from `next/headers`

**Client hooks stay sync:** `useParams()`, `useSearchParams()` — no change.

```ts
// ✅ Server Component / layout
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ page?: string }>
}) {
  const { id } = await params
  const { page } = await searchParams
  // ...
}

// ✅ API route handler
export async function PUT(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  // ...
}

// ✅ cookies() / headers()
import { cookies, headers } from "next/headers"
const cookieStore = await cookies()
const token = cookieStore.get("auth")?.value
const heads = await headers()
const pathname = heads.get("x-next-pathname")
```

### 1.1 Proxy (formerly Middleware)

Next.js 16 renamed `middleware.ts` → `proxy.ts` and the exported function from `middleware` → `proxy`. Everything else (matchers, `NextRequest`, `NextResponse`) works the same.

```ts
// proxy.ts (formerly middleware.ts)
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export function proxy(request: NextRequest) {
  // ...
  return NextResponse.next()
}

export const config = {
  matcher: ["/((?!.+\\.[\\w]+$|_next).*)", "/(api|trpc)(.*)"],
}
```

For NextAuth integration, wrap with `auth()` internally and call the wrapper from the `proxy` export (see `proxy.ts` in this repo).

### 1.2 Config & Nav Breadcrumbs

**When to use:** Every page needs a breadcrumb config for the navigation bar.

```ts
// config/{resource}s.ts
import { PageConfig } from "@/types"

export const {resource}sConfig: PageConfig = {
  mainNav: [
    {
      href: "/",
      icon: "home",
    },
    {
      title: "general",       // section label (disabled)
      disabled: true,
    },
    {
      title: "{resource}s",   // page title with link
      href: "/{resource}s",
    },
  ],
}
```

Additional configs for create/edit pages:
```ts
// config/create-{resource}.ts
export const create{Resource}Config: PageConfig = {
  mainNav: [
    { href: "/", icon: "home" },
    { title: "general", disabled: true },
    { title: "{resource}s", href: "/{resource}s" },
    { title: "Create {resource}" },
  ],
}
```

**The `PageConfig` type** (from `types/index.d.ts`):
```ts
export type PageConfig = {
  mainNav: BreadcrumbNavItem[]
  sideNav?: NavItem[]
}

export type BreadcrumbNavItem = {
  title?: string
  href?: string
  disabled?: boolean
  icon?: keyof typeof Icons
}
```

**Real examples:** `config/admins.ts`, `config/create-admin.ts`, `config/admin-details.ts`

---

## Part 2: Data Layer (Next.js Additions)

### 2.1 SSR Data Fetching

**When to use:** Server-side data fetching for list and detail pages (runs on the server, not client).

**Key files:** `data/queries/vendors.ts`, `data/index.ts`

**Auth in SSR / API routes** — this project uses NextAuth v5. Always:
```ts
import { auth } from "@/auth"
const session = await auth()
// Bearer: session?.backendTokens  (NOT session?.backendTokens.accessToken)
```

**List query:**
```ts
// data/queries/{resource}s.ts
import { auth } from "@/auth"
import { env } from "@/env.mjs"
import { filteredParams, queryString } from "@/lib/utils"
import { {resource}sPatchSchema } from "@/lib/validations/{resource}s"
import { z } from "zod"
import { Params } from "@/types"

export async function get{Resource}s(
  searchParams: { [key: string]: string },
  defaultParams: Params
) {
  try {
    const params = filteredParams(searchParams, defaultParams)
    const session = await auth()
    if (!session) {
      throw new Error("User not Logged In !!")
    }
    const res = await fetch(
      `${env.BACKEND_URL}/{backendEndpoint}?${queryString(params)}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${session?.backendTokens}`,
        },
      }
    )
    const data = await res.json()
    if (!res.ok) {
      throw new Error(data?.message || "Something went Wrong !!")
    }
    z.array({resource}sPatchSchema).parse(data.data.data)
    return data.data
  } catch (error) {
    throw error
  }
}
```

**Detail query:**
```ts
export async function get{Resource}(id: string) {
  try {
    const session = await auth()
    if (!session) {
      throw new Error("User not Logged In !!")
    }
    const res = await fetch(
      `${env.BACKEND_URL}/{backendEndpoint}/${id}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${session?.backendTokens}`,
        },
      }
    )
    const data = await res.json()
    if (!res.ok) {
      throw new Error(data?.message || "Something went Wrong !!")
    }
    const parsedData = {resource}DetailsSchema.parse(data.data)
    return parsedData
  } catch (error) {
    throw error
  }
}
```

**Re-export from barrel file:**
```ts
// data/index.ts
export { get{Resource}, get{Resource}s } from "@/data/queries/{resource}s"
```

**Real examples:** `data/queries/vendors.ts`, `data/queries/admins.ts`, `data/queries/coupons.ts`

---

### 2.2 API Route Handlers

**When to use:** Every resource needs API routes that proxy to the backend. Client components call these routes (not the backend directly).

**⚠️ Next.js 16 async `params`:** In every route with dynamic segments, `params` is a `Promise<...>` and must be awaited. Route context is no longer passed through a Zod schema — just destructure `{ params }` and `await` it.

**List route (GET + POST):**
```ts
// app/api/{resource}s/route.ts
import { auth } from "@/auth"
import { env } from "@/env.mjs"
import { {resource}sPatchSchema } from "@/lib/validations/{resource}s"
import { z } from "zod"

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url)
    const session = await auth()
    if (!session) {
      throw new Error("User not Logged In !!")
    }
    const res = await fetch(
      `${env.BACKEND_URL}/{backendEndpoint}?${searchParams.toString()}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${session?.backendTokens}`,
        },
      }
    )
    const data = await res.json()
    if (!res.ok) {
      throw new Error(data?.message || "Something went Wrong !!")
    }
    z.array({resource}sPatchSchema).parse(data.data.data)
    return new Response(JSON.stringify(data.data), { status: 200 })
  } catch (error) {
    return new Response(error.message || "Something went Wrong !!", { status: 500 })
  }
}

export async function POST(req: Request) {
  try {
    const session = await auth()
    if (!session) {
      throw new Error("User not Logged In !!")
    }
    const body = await req.json()
    const res = await fetch(`${env.BACKEND_URL}/{backendEndpoint}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${session?.backendTokens}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    })
    const data = await res.json()
    if (!res.ok) {
      throw new Error(data?.message)
    }
    return new Response(JSON.stringify(data), { status: 200 })
  } catch (error) {
    return new Response(error.message || "Something went Wrong !!", { status: 500 })
  }
}
```

**CRUD route (PUT + DELETE):**
```ts
// app/api/{resource}s/[{resource}Id]/route.ts
import { auth } from "@/auth"
import { env } from "@/env.mjs"

export async function PUT(
  req: Request,
  { params }: { params: Promise<{ {resource}Id: string }> }
) {
  try {
    const { {resource}Id } = await params
    const session = await auth()
    if (!session) {
      throw new Error("User not Logged In !!")
    }
    const body = await req.json()
    const res = await fetch(
      `${env.BACKEND_URL}/{backendEndpoint}/${{resource}Id}`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${session?.backendTokens}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      }
    )
    const data = await res.json()
    if (!res.ok) {
      throw new Error(data?.message)
    }
    return new Response(JSON.stringify(data), { status: 200 })
  } catch (error) {
    return new Response(error.message || "Something went Wrong !!", { status: 500 })
  }
}

export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ {resource}Id: string }> }
) {
  try {
    const { {resource}Id } = await params
    const session = await auth()
    if (!session) {
      throw new Error("User not Logged In !!")
    }
    const res = await fetch(
      `${env.BACKEND_URL}/{backendEndpoint}/${{resource}Id}`,
      {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${session?.backendTokens}`,
          "Content-Type": "application/json",
        },
      }
    )
    const data = await res.json()
    if (!res.ok) {
      throw new Error(data?.message)
    }
    return new Response("Deleted Successfully", { status: 200 })
  } catch (error) {
    return new Response(error.message || "Something went Wrong !!", { status: 500 })
  }
}
```

**Real examples:** `app/api/coupons/route.ts`, `app/api/clients/[clientId]/route.ts`

**API route handler rules:**
- **`NextResponse` body must be a string** — `new NextResponse(error, { status: 500 })` passes a raw `Error` object (invalid). Always: `new NextResponse("Internal error", { status: 500 })`
- **Always `.parse()`, never `.safeParse()`** — use `schema.parse(response.data)` which throws on failure. Never return `response.data` as a fallback when `.safeParse()` fails. On parse failure, return an error response (`new NextResponse("Invalid response format", { status: 500 })`)
- **Zod validation only on GET handlers** — PUT & DELETE handlers do not require Zod response validation

```ts
// ❌ BAD — safeParse with raw data fallback
const parsed = schema.safeParse(data)
return NextResponse.json(parsed.success ? parsed.data : data)

// ✅ GOOD — parse throws on failure, catch returns error
const validated = schema.parse(data.data)
return NextResponse.json(validated)
// If parse fails, it throws → caught by catch block → error response
```

---

### 2.5 Client-to-Backend Communication

**Rule:** Never use `axiosInstance` from `@/lib/axios` in client components for backend API calls.

`axiosInstance` uses `NEXT_PUBLIC_API_URL`, which exposes the backend URL and auth tokens in the browser's network tab. All backend calls from client code must go through Next.js route handlers (`/api/...`), which proxy to the backend server-side using the private `BACKEND_URL`.

```tsx
// ❌ BAD — exposes backend URL and tokens in browser
"use client"
import axiosInstance from "@/lib/axios"
const res = await axiosInstance.get("/vehicles")

// ✅ GOOD — proxied through Next.js route handler
"use client"
import axios from "axios"
const res = await axios.get("/api/vehicles")
```

**Exceptions:**
1. **Third-party APIs** (Google Maps, Firebase) that use their own public keys
2. **Large file uploads** where the payload exceeds the route handler size limit (~5 MB)

---

### 2.3 SSR Cache Invalidation

**Extends** PATTERNS-REACT.md section 2.4 (which covers `queryClient.invalidateQueries`).

In Next.js, SSR-fetched data needs different invalidation strategies:

| Strategy | When | Example |
|----------|------|---------|
| `window.location.assign(url)` | After edit on SSR page (clear server cache) | `window.location.assign('/admins/123')` |
| `router.push(url)` + `startTransition` | After create (navigate to new resource) | `startTransition(() => router.push('/admins/123'))` |
| `router.refresh()` | After delete from table row (re-run SSR) | `router.refresh()` |
| `window.location.assign('/list')` | After delete from detail page | `window.location.assign('/{resource}s')` |

```ts
import { useRouter } from "next/navigation"
import { useTransition } from "react"

const router = useRouter()
const [isPending, startTransition] = useTransition()

// After edit — full page refresh to clear server-side cache
window.location.assign(`/{resource}s/${id}`)

// After create — client navigation
startTransition(() => router.push(`/{resource}s/${data.data.data.id}`))

// After delete from table row — refresh current list
router.refresh()

// After delete from detail page — navigate to list
window.location.assign(`/{resource}s`)
```

**Can combine with React Query invalidation** when both SSR and client-fetched data need updating:
```ts
queryClient.invalidateQueries({ queryKey: ["{resource}s"] })
router.refresh()
```

---

### 2.4 URL Search Params (Server-Side State)

**When to use:** Filters, pagination, sorting, and search are stored in URL params — NOT React state.

**Key files:** `lib/utils.ts`

**Utility functions:**
```ts
import { createUrl, filteredParams, queryString, getIsSorted } from "@/lib/utils"

// createUrl — combine pathname with search params
const url = createUrl("/admins", new URLSearchParams({ page: "1", limit: "10" }))
// → "/admins?page=1&limit=10"

// filteredParams — merge user params with defaults, filter empty strings
const params = filteredParams(
  { page: 1, search: "" },
  { page: 1, limit: 10 }
)
// → { page: 1, limit: 10 } (empty search removed)

// queryString — build query string for backend API calls
const qs = queryString({ page: 1, limit: 10, sortBy: "name_en:ASC" })
// → "page=1&limit=10&sortBy=name_en:ASC"

// getIsSorted — check column sort state from URL
const sorted = getIsSorted("name_en", "name_en:ASC")
// → "ASC"
```

**URL param pattern in components:**
```tsx
import { useSearchParams, useRouter, usePathname } from "next/navigation"
import { useTransition } from "react"
import { createUrl } from "@/lib/utils"

const searchParams = useSearchParams()
const router = useRouter()
const pathname = usePathname()
const [isPending, startTransition] = useTransition()

const newParams = new URLSearchParams(searchParams.toString())
newParams.set("page", "1")
newParams.set("sortBy", `${column.id}:ASC`)
startTransition(() => router.push(createUrl(pathname, newParams), { scroll: false }))
```

**Default params for list pages:**
```ts
const defaultParams: Params = {
  page: 1,
  limit: 10,
}
```

**Real examples:** `components/dashboard/data-table-column-header.tsx`, `hooks/use-Pagination.ts`, `components/search.tsx`

---

## Part 3: Pages & UI (Next.js Additions)

### 3.1 List Page (SSR)

```tsx
// app/(dashboard)/{resource}s/page.tsx
import { Params } from "@/types"
import { get{Resource}s } from "@/data"
import { {resource}sConfig } from "@/config/{resource}s"
import { Nav } from "@/components/nav"
import Search from "@/components/search"
import { columns } from "@/components/dashboard/{resource}s/{resource}s-columns"
import { {Resource}sTable } from "@/components/dashboard/{resource}s/{resource}s-table"

const defaultParams: Params = {
  page: 1,
  limit: 10,
}

const {Resource}sPage = async ({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string }>
}) => {
  const resolvedSearchParams = await searchParams
  const data = await get{Resource}s(resolvedSearchParams, defaultParams)

  return (
    <>
      <div className="flex items-center justify-between pb-8 pt-4">
        <Nav items={{resource}sConfig.mainNav} />
        <Search path="/{resource}s" />
      </div>
      <div className="rounded-md bg-background">
        <{Resource}sTable columns={columns} data={data} />
      </div>
    </>
  )
}
export default {Resource}sPage
```

---

### 3.2 Create Page

```tsx
// app/(dashboard)/{resource}s/create/page.tsx
import { create{Resource}Config } from "@/config/create-{resource}"
import { Nav } from "@/components/nav"
import {Resource}Form from "@/components/dashboard/{resource}s/{resource}-form"

const Create{Resource}Page = () => {
  return (
    <>
      <div className="flex items-center justify-between pb-8 pt-4">
        <Nav items={create{Resource}Config.mainNav} />
      </div>
      <div className="max-w-xl">
        <{Resource}Form />
      </div>
    </>
  )
}
export default Create{Resource}Page
```

---

### 3.3 Edit Page (SSR)

```tsx
// app/(dashboard)/{resource}s/[{resource}Id]/edit/page.tsx
import { get{Resource} } from "@/data"
import { {resource}DetailsConfig } from "@/config/{resource}-details"
import { Nav } from "@/components/nav"
import {Resource}Form from "@/components/dashboard/{resource}s/{resource}-form"

interface Props {
  params: Promise<{
    {resource}Id: string
  }>
}

const Edit{Resource}Page = async ({ params }: Props) => {
  const { {resource}Id } = await params
  const {resource} = await get{Resource}({resource}Id)

  return (
    <>
      <div className="flex items-center justify-between pb-8 pt-4">
        <Nav items={{resource}DetailsConfig.mainNav} />
      </div>
      <div className="max-w-xl">
        <{Resource}Form {resource}={{resource}} />
      </div>
    </>
  )
}
export default Edit{Resource}Page
```

---

### 3.4 Loading Page (loading.tsx)

**When to use:** Every route segment needs a `loading.tsx` for automatic loading states.

```tsx
// app/(dashboard)/{resource}s/loading.tsx
import { DataTableSkeleton } from "@/components/dashboard/data-table-skeletons"
import { Nav } from "@/components/nav"
import { Skeleton } from "@/components/ui/skeleton"
import { {resource}sConfig } from "@/config/{resource}s"

const Loading = () => {
  return (
    <>
      <div className="flex items-center justify-between pb-8 pt-4">
        <Nav items={{resource}sConfig.mainNav} />
        <Skeleton className="h-8 w-[200px]" />
      </div>
      <div className="rounded-md bg-background">
        <DataTableSkeleton />
      </div>
    </>
  )
}
export default Loading
```

**Real examples:** `app/(dashboard)/admins/loading.tsx`

---

### 3.5 Error Boundary (error.tsx)

**When to use:** The error boundary at `app/(dashboard)/error.tsx` handles all dashboard errors.

```tsx
// app/(dashboard)/error.tsx
"use client"

import { useEffect } from "react"
import { signOut } from "next-auth/react"
import { Button } from "@/components/ui/button"
import { useToast } from "@/components/ui/use-toast"
import { ErrorCard } from "@/components/error-card"
import { Shell } from "@/components/shell"

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  const { toast } = useToast()
  // Error format: "message__STATUS_CODE__400"
  const [errorMessage, statusCode] = error.message.split("__STATUS_CODE__")
  const parsedStatusCode = parseInt(statusCode, 10) || 500

  useEffect(() => {
    // Auto sign-out on 401
    if (parsedStatusCode === 401 || error.message.includes("401")) {
      signOut({ callbackUrl: `${window.location.origin}/login` })
    }
  }, [error.message, parsedStatusCode, toast])

  return (
    <Shell variant="centered">
      <ErrorCard title={`Error ${parsedStatusCode}`} description={errorMessage} />
      <Button onClick={() => reset()}>Try again</Button>
    </Shell>
  )
}
```

**Key conventions:**
- Error message format: `"Human message__STATUS_CODE__400"`
- 401 errors auto-redirect to login via `signOut()`
- `reset()` retries the failed operation
- One shared error boundary for entire dashboard

---

### 3.6 Search Component (URL-Based)

```tsx
// Usage in list page
import Search from "@/components/search"

<Search path="/{resource}s" placeholder="Search {resource}s..." />
```

**How it works:**
- Form-based submission (Enter key)
- Sets `search` URL param, resets `page` to 1
- Uses `useTransition` for pending state
- Input key tied to `searchParams.get("search")` to reset on navigation

**Real examples:** `components/search.tsx`

---

### 3.7 Filters Sheet (URL-Based)

**When to use:** List pages with filterable columns.

```tsx
// components/dashboard/{resource}s/{resource}s-filter.tsx
"use client"

import { zodResolver } from "@hookform/resolvers/zod"
import { usePathname, useRouter, useSearchParams } from "next/navigation"
import { useTransition } from "react"
import { useForm } from "react-hook-form"
import * as z from "zod"

import { FiltersSheet } from "@/components/filters-sheet"
import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { SheetClose, SheetFooter } from "@/components/ui/sheet"
import { createUrl } from "@/lib/utils"

const formSchema = z.object({
  type: z.string(),
  from: z.string(),
  to: z.string(),
})

type FormData = z.infer<typeof formSchema>

export function {Resource}sFilter<TData>({ table }) {
  const searchParams = useSearchParams()
  const router = useRouter()
  const pathname = usePathname()
  const [isPending, startTransition] = useTransition()

  // Initialize form from URL params
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      type: searchParams?.get("filter.target") || "all",
      from: searchParams?.get("filter.from") || "",
      to: searchParams?.get("filter.to") || "",
    },
  })

  function onSubmit(values: FormData) {
    const optionSearchParams = new URLSearchParams(searchParams.toString())
    optionSearchParams.set("page", "1")

    if (values.type) {
      optionSearchParams.set("filter.target", values.type)
    } else {
      optionSearchParams.delete("filter.target")
    }
    // ... set or delete other filter params

    startTransition(() => router.push(createUrl(pathname, optionSearchParams), { scroll: false }))
  }

  function onReset() {
    form.reset({ type: "all", from: "", to: "" })
  }

  return (
    <FiltersSheet title="Filters" isPending={isPending}>
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <div className="grid gap-4 py-4">
            {/* FormFields for each filter */}
          </div>
          <SheetFooter>
            <SheetClose asChild>
              <Button type="submit" disabled={isPending}>Save Changes</Button>
            </SheetClose>
            <Button variant="ghost" type="reset" onClick={onReset}>Clear all</Button>
          </SheetFooter>
        </form>
      </Form>
    </FiltersSheet>
  )
}
```

**Key conventions:**
- Initialize form defaults from URL search params
- On submit, build new URLSearchParams and push
- Always reset page to 1 on filter change
- Include a "Clear all" reset button

**Real examples:** `components/dashboard/clients/clients-filter.tsx`

---

### 3.8 Column Sorting (URL-Based)

**When to use:** Table columns with server-side sorting via URL params.

**How it works:**
- Sort state stored in URL as `sortBy=columnId:ASC` or `sortBy=columnId:DESC`
- `DataTableColumnHeader` reads sort state via `getIsSorted()` utility
- Clicking sort pushes new URL params with `page=1`
- `useTransition` shows spinner during navigation

```tsx
// In column definition
{
  accessorKey: "name_en",
  header: ({ column }) => (
    <DataTableColumnHeader column={column} title="Name" />
  ),
}
```

**Real examples:** `components/dashboard/data-table-column-header.tsx`, `components/dashboard/vendors/vendors-columns.tsx`

---

### 3.9 Form Mutation (Next.js Navigation)

**Extends** PATTERNS-REACT.md section 2.3 (mutations) with Next.js-specific navigation.

In Next.js, the form's `onSuccess` uses `useRouter` from `next/navigation` and `useTransition`:

```tsx
import { useRouter } from "next/navigation"
import { useTransition } from "react"

const [isPending, startTransition] = useTransition()
const router = useRouter()

const { mutate } = useMutation({
  mutationFn: async (data) => { /* ... */ },
  onSuccess: (data) => {
    toast({ variant: "success", title: "Saved" })
    // Edit: full refresh to clear SSR cache
    {resource}
      ? window.location.assign(`/{resource}s/${{resource}.id}`)
      : startTransition(() => router.push(`/{resource}s/${data.data.data.id}`))
  },
})
```

---

### 3.10 Delete Dialog (Next.js Navigation)

**Extends** PATTERNS-REACT.md section 3.4 (delete dialog) with Next.js-specific navigation.

```tsx
import { useRouter } from "next/navigation"

const router = useRouter()

const { mutate } = useMutation({
  mutationFn: async () => axios.delete(`/api/{resource}s/${id}`),
  onSuccess: () => {
    toast({ title: "Deleted Successfully", variant: "success" })
    onOpenChange(false)
    // From table row: refresh list | From detail page: navigate to list
    refresh ? router.refresh() : window.location.assign(`/{resource}s`)
  },
})
```

**Key:** `refresh` prop distinguishes table row delete (`router.refresh()`) from detail page delete (`window.location.assign`).

---

## Appendix

### A. New Feature Checklist (Full Next.js)

When adding a new CRUD feature `{Resource}`, create these files:

**Required:**
- [ ] `lib/validations/{resource}s.ts` — Zod schemas (patch, details, form, update, payload) + types
- [ ] `config/{resource}s.ts` — Page config (breadcrumb nav)
- [ ] `config/create-{resource}.ts` — Create page config
- [ ] `config/{resource}-details.ts` — Details/edit page config
- [ ] `data/queries/{resource}s.ts` — SSR fetch functions (getAll + getOne)
- [ ] `data/index.ts` — Add re-exports
- [ ] `app/api/{resource}s/route.ts` — GET + POST
- [ ] `app/api/{resource}s/[{resource}Id]/route.ts` — PUT + DELETE
- [ ] `app/(dashboard)/{resource}s/page.tsx` — List page (SSR)
- [ ] `app/(dashboard)/{resource}s/loading.tsx` — Loading skeleton
- [ ] `app/(dashboard)/{resource}s/create/page.tsx` — Create page
- [ ] `app/(dashboard)/{resource}s/[{resource}Id]/edit/page.tsx` — Edit page
- [ ] `components/dashboard/{resource}s/{resource}s-columns.tsx` — Table columns
- [ ] `components/dashboard/{resource}s/{resource}s-table.tsx` — Table wrapper
- [ ] `components/dashboard/{resource}s/{resource}s-table-row-actions.tsx` — Row actions
- [ ] `components/dashboard/{resource}s/{resource}-form.tsx` — Create/edit form
- [ ] `components/dashboard/{resource}s/delete-{resource}.tsx` — Delete dialog

**Optional:**
- [ ] `hooks/use-{resource}s.ts` — Client infinite query (if used in combobox)
- [ ] `components/dashboard/{resource}s/{resource}s-filter.tsx` — Filter sheet
- [ ] `components/dashboard/select-source/{resource}s-combo-box.tsx` — Combobox
- [ ] Add sidebar nav item in `config/dashboard.ts`

### B. Next.js-Specific Pitfalls

1. **Don't use React state for URL-driven data** — use `useSearchParams()` for filters, pagination, sorting
2. **Don't use `router.push()` after edit** — use `window.location.assign()` to clear SSR cache
3. **Don't forget to add re-exports** — update `data/index.ts` when adding new query files
4. **Don't forget `manualPagination: true`** — table pagination is server-side
5. **Don't forget `loading.tsx`** — every route segment needs one
6. **Don't forget `page: 1` reset** — when changing filters or sort via URL params
7. **Never use `axiosInstance` in client components** — use `axios` to call Next.js route handlers (`/api/...`) instead
8. **`NextResponse` body must be a string** — don't pass raw `Error` objects to `new NextResponse()`
9. **Always `.parse()`, never `.safeParse()` in API routes** — never return raw unvalidated data as a fallback
10. **Never access `params` / `searchParams` / `cookies()` / `headers()` synchronously** (Next.js 16) — all are Promises. Always type as `Promise<...>` and `await`. Client hooks (`useParams`, `useSearchParams`) remain sync
11. **Never create `middleware.ts`** (Next.js 16) — use `proxy.ts` with `export function proxy(...)` instead
12. **Never use NextAuth v4 patterns** — this project is v5. Use `import { auth } from "@/auth"` + `await auth()`, not `getServerSession(authOptions)`. Backend token is `session?.backendTokens` (flat), not `.accessToken`
13. **Never use deprecated `next.config` options** — use `images.remotePatterns` (not `images.domains`) and top-level `serverExternalPackages` (not `experimental.serverComponentsExternalPackages`)
14. **Don't place metadata files (opengraph-image, icon, apple-icon) in dynamic route segments** — Next.js 16 fails to prerender them without `generateStaticParams`. Place them at the `app/` root or in static segments
15. **Don't import browser-only libraries at module level** — libraries like `lottie-react` that access `document`/`window` must be wrapped with `next/dynamic({ ssr: false })`. See `components/ui/lottie.tsx`
