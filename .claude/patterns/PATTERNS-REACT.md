# React Patterns Guide

Universal React patterns for all projects (Vite, CRA, Next.js). Uses `{Resource}`/`{resource}` placeholders.

> For Next.js-specific additions (SSR, API routes, `loading.tsx`, URL-based state), see `PATTERNS-NEXTJS.md`.

---

## Quick Reference

### File Naming Convention
All files use **kebab-case**:
| Type | Example |
|------|---------|
| Component | `{resource}-form.tsx` |
| Hook | `use-{resource}s.ts` |
| Validation | `{resource}s.ts` (in `lib/validations/`) |
| Config | `{resource}s.ts` (in `config/`) |

### Code Naming Convention
| Type | Convention | Example |
|------|-----------|---------|
| Components | PascalCase | `{Resource}Form` |
| Hooks | camelCase with `use` prefix | `use{Resource}s` |
| Functions/Variables | camelCase | `get{Resource}s` |
| Types/Interfaces | PascalCase | `{Resource}Details` |
| Constants | UPPER_SNAKE_CASE | `DEFAULT_PARAMS` |

### Import Order
```tsx
// 1. React/Framework imports
import { useState } from "react"
import { useNavigate } from "react-router-dom"  // or next/navigation

// 2. Third-party libraries
import { zodResolver } from "@hookform/resolvers/zod"
import { useMutation, useQueryClient } from "@tanstack/react-query"
import axios, { AxiosError } from "axios"
import { useForm } from "react-hook-form"

// 3. Internal aliases
import { cn } from "@/lib/utils"
import { {Resource}Details, Safe{Resource}, {resource}Schema } from "@/lib/validations/{resource}s"
import { Button } from "@/components/ui/button"
import { useToast } from "@/components/ui/use-toast"

// 4. Relative imports
import Delete{Resource} from "./delete-{resource}"

// 5. Types (if separate)
import type { Params } from "@/types"
```

### Directory Layout for a CRUD Feature
```
components/
  {resource}s/
    {resource}-form.tsx              # Create/Edit form
    {resource}s-columns.tsx          # Table column definitions
    {resource}s-table.tsx            # Table wrapper component
    {resource}s-table-row-actions.tsx # Row action menu
    {resource}s-filter.tsx           # Filter (optional)
    delete-{resource}.tsx            # Delete confirmation dialog

hooks/
  use-{resource}.ts                  # useQuery for single resource
  use-{resource}s.ts                 # useQuery for list / useInfiniteQuery for combobox

lib/
  validations/
    {resource}s.ts                   # Zod schemas + types

services/  (or api/)
  {resource}s.ts                     # API call functions
```

---

## Code Quality Standards

Rules that apply across all components and files:

| Rule | Description |
|------|-------------|
| **No dead code** | Never create files that aren't imported/used. No unused imports or variables |
| **No duplicate code** | Extract shared logic to reusable components/hooks |
| **No `console.log`** | Remove all console statements before committing (including `console.error` in API routes) |
| **No commented-out code** | Delete commented-out code blocks entirely |
| **No `any` types** | Use proper TypeScript types; only `any` when absolutely necessary |
| **No unused state** | Don't define `useState`/`useQueryState` variables that are never read — adds dead code and (for `useQueryState`) phantom URL params |
| **No missing assets** | Every `<img src="/file.svg">` must have a corresponding file in `public/` |
| **`const` over `let`** | Use `const res = await fetch(...)` not `let res`. Only `let` when actually reassigned |
| **No empty catch blocks** | `catch (error) {}` silently swallows errors — always re-throw, log, or surface a user-facing message |
| **`components/ui/` changes are global** | Modifying base UI primitives (e.g., `button.tsx`, `input.tsx`) affects every instance app-wide. Flag as high-impact. If the change is only needed in one place, add the class/style locally instead |
| **Shared utilities must be generic** | Functions in `lib/utils.ts` must not reference specific module names in JSDoc or error messages |
| **Update all names when copy-pasting** | When creating a new component from an existing one, update every `export function`, `export default function`, and `export const` name to match the new entity |

---

## Part 1: Foundation

### 1.1 Zod Schema Strategy

**When to use:** Every resource needs multiple Zod schemas for different contexts.

```ts
// lib/validations/{resource}s.ts
import { z } from "zod"

// 1. Patch Schema — for list/table display (minimal fields)
export const {resource}sPatchSchema = z.object({
  id: z.string(),
  name_en: z.string(),
  name_ar: z.string(),
  createdAt: z.string(),
})

// 2. Details Schema — for detail/edit pages (full fields)
export const {resource}DetailsSchema = z.object({
  id: z.string(),
  name_en: z.string(),
  name_ar: z.string(),
  description_en: z.string(),
  description_ar: z.string(),
  status: z.string(),
  createdAt: z.string(),
})

// 3. Form Schema — for create form validation
export const {resource}Schema = z.object({
  name_en: z.string().min(2),
  name_ar: z.string().min(2),
  description_en: z.string().min(2),
  description_ar: z.string().min(2),
})

// 4. Update Form Schema — for edit form (fields may be optional)
export const update{Resource}Schema = {resource}Schema.merge(
  z.object({
    password: z.string().min(8).optional().or(z.literal("")),
  })
)

// 5. Payload Schema — what's sent to the API (may differ from form)
export const {resource}FormPayloadSchema = {resource}Schema.omit({ password: true }).extend({
  password: z.string().min(8).optional(),
})

// Type exports
export type {Resource} = z.infer<typeof {resource}sPatchSchema>
export type {Resource}Details = z.infer<typeof {resource}DetailsSchema>
export type Safe{Resource} = z.infer<typeof {resource}Schema>
export type {Resource}FormPayload = z.infer<typeof {resource}FormPayloadSchema>
```

**Zod validation rules:**
- **Always use `.parse()`, never `.safeParse()`** — `.parse()` throws on failure, guaranteeing validated data. Never return `response.data` as a fallback when `.safeParse()` fails — return an error response instead
- **Schema must cover all consumed fields** — Zod strips unknown fields by default. If a component reads `operator.phone`, the schema must include it — even if other views don't need it. Missing fields become `undefined` at runtime
- **No `z.any()`, `z.record(z.unknown())`, or `z.unknown()`** — for known data structures, define proper typed schemas
- **Use `z.string()` for combobox IDs in form schemas** — when a combobox selects an entity, the Zod form field should be `z.string()` (the ID), not the full `{ value, label }` object type

---

### 1.2 Type Flow

```
API Response → Zod Schema (parse) → TypeScript Type → Component Props
```

Types are always inferred from Zod schemas:
```ts
export type {Resource} = z.infer<typeof {resource}sPatchSchema>
```

---

### 1.3 Bilingual Fields

**When to use:** All user-facing content fields (names, descriptions).

The backend stores separate `_en` and `_ar` fields (not an i18n library for data).

```tsx
// Zod schema
z.object({
  name_en: z.string().min(2),
  name_ar: z.string().min(2),
})

// Form fields (always in pairs)
<FormField name="name_en" render={({ field }) => (
  <FormItem>
    <FormLabel>Name (English)</FormLabel>
    <FormControl><Input {...field} /></FormControl>
    <FormMessage />
  </FormItem>
)} />
<FormField name="name_ar" render={({ field }) => (
  <FormItem>
    <FormLabel>Name (Arabic)</FormLabel>
    <FormControl><Input dir="rtl" {...field} /></FormControl>
    <FormMessage />
  </FormItem>
)} />
```

---

### 1.4 Enum & Constants Declaration

**When to use:** Every enumerated value (status, type, category) in the project.

All enums (Zod enum + TypeScript type + display options array) must live in `data/constants.ts`. Never define them inline in validation files or components.

```ts
// data/constants.ts
import { z } from "zod"

// 1. Zod enum
export const deviceType = z.enum([
  "gps-tracker",
  "gps-tracker-with-video",
  "rssi-gateway",
  "ble-tag",
])

// 2. TypeScript type (inferred)
export type DeviceType = z.infer<typeof deviceType>

// 3. Display options array (must have Options suffix)
export const deviceTypesOptions: { value: DeviceType; label: string }[] = [
  { value: "gps-tracker", label: "GPS Tracker" },
  { value: "gps-tracker-with-video", label: "GPS Tracker with Video" },
  { value: "rssi-gateway", label: "RSSI Gateway" },
  { value: "ble-tag", label: "BLE Tag" },
]
```

**Rules:**
- All enum declarations belong in `data/constants.ts` — never inline in validation files or components
- Display options array **must** have an `Options` suffix (e.g., `deviceTypesOptions`, not `deviceTypes`)
- Import the Zod enum into `lib/validations/` files — do not redefine it there

---

### 1.5 Hook Naming Conventions

**`useTransition`:** Always destructure with the standard React docs names:
```tsx
// ✅ Correct — standard names
const [isPending, startTransition] = useTransition()

// ✅ Correct — disambiguation when multiple useTransition hooks
const [isPending, startTransition] = useTransition()
const isPendingSearch = isPending
const startSearchTransition = startTransition

// ❌ Forbidden — renaming in destructuring
const [isPendingSearch, startSearchTransition] = useTransition()

// ❌ Forbidden — unrelated names
const [isTransitionPending, setTransition] = useTransition()
const [isLoading, startTransition] = useTransition()
```

When a query/mutation also exposes `isPending`, rename **theirs**:
```tsx
const { isPending: isQueryPending } = useQuery(...)
const { isPending: isMutating } = useMutation(...)
```

---

## Part 2: Data Layer

### 2.1 Client Data Fetching (useQuery)

**When to use:** Fetching data in client components — detail views, sub-resources, dialog/tab content.

**Basic pattern (fetch by ID):**
```ts
// hooks/use-{resource}.ts
import { {Resource}Details } from "@/lib/validations/{resource}s"
import { useQuery } from "@tanstack/react-query"
import axios from "axios"

const fetch{Resource} = async (id: string) => {
  const res = await axios.get(`/api/{resource}s/${id}`)
  return res.data.data as {Resource}Details
}

export function use{Resource}(id: string) {
  return useQuery({
    queryKey: ["{resource}s", id],
    queryFn: () => fetch{Resource}(id),
    enabled: !!id && id !== "",
  })
}
```

**With additional params:**
```ts
export function use{Resource}Schedule(id: string, from: string | null, to: string | null) {
  return useQuery({
    queryKey: ["{resource}-schedule", id, from, to],
    queryFn: () => fetch{Resource}Schedule({ id, from, to }),
    enabled: !!id && !!from && !!to,
  })
}
```

**With conditional enabling (dialog/tab):**
```ts
export function use{Resource}(id: string, open: boolean) {
  return useQuery({
    queryKey: ["{resource}s", id],
    queryFn: () => fetch{Resource}(id),
    enabled: !!id && open,  // only fetch when dialog is open
  })
}
```

**List query with params:**
```ts
// hooks/use-{resource}s.ts
import { useQuery } from "@tanstack/react-query"
import axios from "axios"

export function use{Resource}s(params: { page: number; limit: number; search?: string }) {
  return useQuery({
    queryKey: ["{resource}s", params],
    queryFn: async () => {
      const res = await axios.get(`/api/{resource}s`, { params })
      return res.data
    },
  })
}
```

**Key conventions:**
- `queryKey` must include ALL variables that affect the fetch
- `enabled` prevents fetching when required params are missing
- Separate fetch function defined outside the hook
- Invalidate with `queryClient.invalidateQueries({ queryKey: [...] })` after mutations

---

### 2.2 Client Data Fetching (Infinite Query)

**When to use:** Comboboxes and infinite scroll lists.

```ts
// hooks/use-{resource}s.ts
import { useInfiniteQuery } from "@tanstack/react-query"
import axios from "axios"

const defaultParams = { limit: 25, sortBy: "name_en:ASC" }

const fetch{Resource}s = async ({ pageParam, term }) => {
  const res = await axios.get(`/api/{resource}s`, {
    params: { page: pageParam, search: term, ...defaultParams },
  })
  return res.data
}

export function use{Resource}s(term?: string) {
  return useInfiniteQuery({
    queryKey: ["{resource}s", term],
    queryFn: ({ pageParam }) => fetch{Resource}s({ pageParam, term }),
    initialPageParam: 1,
    getPreviousPageParam: (firstPage: any) => {
      if (firstPage.meta.currentPage <= firstPage.meta.totalPages) {
        return firstPage.meta.currentPage - 1
      }
      return undefined
    },
    getNextPageParam: (lastPage: any) => {
      if (lastPage.meta.currentPage !== lastPage.meta.totalPages) {
        return lastPage.meta.currentPage + 1
      }
      return undefined
    },
  })
}
```

---

### 2.3 Mutations

**When to use:** All create/update/delete operations.

```tsx
import { useMutation, useQueryClient } from "@tanstack/react-query"
import axios, { AxiosError } from "axios"

const queryClient = useQueryClient()

const { mutate, isPending } = useMutation({
  mutationFn: async (data: {Resource}FormPayload) => {
    const url = {resource} ? `/api/{resource}s/${{resource}.id}` : `/api/{resource}s`
    const method = {resource} ? "put" : "post"
    return axios[method](url, data)
  },
  onSuccess: (data) => {
    toast({
      variant: "success",
      title: {resource} ? "Updated Successfully" : "Created Successfully",
    })
    // Invalidate relevant queries
    queryClient.invalidateQueries({ queryKey: ["{resource}s"] })
    // Navigate to detail page
    navigate(`/{resource}s/${data.data.data.id}`)
  },
  onError: (err: AxiosError) => {
    toast({
      variant: "destructive",
      title: (err?.response?.data as string) || "Failed to perform your request",
    })
  },
})
```

**Key conventions:**
- `useMutation` from `@tanstack/react-query`
- `axios[method](url, data)` for dynamic HTTP method
- Success: toast + invalidate queries + navigate
- Error: toast with server error message

---

### 2.4 Cache Invalidation

**When to use:** After any mutation that changes server data.

```tsx
import { useQueryClient } from "@tanstack/react-query"

const queryClient = useQueryClient()

// After create/update/delete — invalidate the list and detail queries
queryClient.invalidateQueries({ queryKey: ["{resource}s"] })

// Invalidate specific item
queryClient.invalidateQueries({ queryKey: ["{resource}s", id] })

// Invalidate sub-resource
queryClient.invalidateQueries({ queryKey: ["branches-boundaries", branchId] })
```

**Key conventions:**
- Import `useQueryClient` from `@tanstack/react-query`
- Call in `onSuccess` of `useMutation`
- `queryKey` must match the key used in `useQuery`/`useInfiniteQuery`

---

## Part 3: UI Components

### 3.1 Data Tables

**When to use:** Every list page.

#### Column Definitions

```tsx
// components/{resource}s/{resource}s-columns.tsx
"use client"

import { ColumnDef } from "@tanstack/react-table"
import { {Resource} } from "@/lib/validations/{resource}s"
import { {Resource}sTableRowActions } from "./{resource}s-table-row-actions"

export const columns: ColumnDef<{Resource}>[] = [
  {
    id: "number",
    header: () => <div>No</div>,
    cell: ({ row }) => <div className="w-20 truncate">{`#${row.original.id}`}</div>,
    enableSorting: false,
    enableHiding: false,
  },
  {
    accessorKey: "name_en",
    header: "Name",
    cell: ({ row }) => <span>{row.original.name_en}</span>,
  },
  // ... more columns
  {
    id: "actions",
    cell: ({ row }) => <{Resource}sTableRowActions row={row} />,
  },
]
```

**Key points:**
- Columns exported as `const columns` array of `ColumnDef<Type>[]`
- Row actions always last column with `id: "actions"`
- `enableSorting: false, enableHiding: false` for non-sortable columns
- **Separate column file per page** — each page/view gets its own `*-columns.tsx`, even if columns are similar across pages
- **No generic column factory functions** — don't create `createColumn()` wrappers; define columns explicitly with `ColumnDef<T>[]`
- **Shared format functions in `lib/utils.ts`** — reusable value formatting (dates, statuses, etc.) used across column files must live in `lib/utils.ts`, not be duplicated

#### Table Component

Uses `@tanstack/react-table` with `useReactTable`:
```tsx
const table = useReactTable({
  data,
  columns,
  state: { sorting, columnVisibility, columnFilters, pagination },
  getCoreRowModel: getCoreRowModel(),
  getFilteredRowModel: getFilteredRowModel(),
  getSortedRowModel: getSortedRowModel(),
  getFacetedRowModel: getFacetedRowModel(),
  getFacetedUniqueValues: getFacetedUniqueValues(),
  manualPagination: true,  // server-side pagination
})
```

#### Row Actions

```tsx
// components/{resource}s/{resource}s-table-row-actions.tsx
"use client"

import { useState } from "react"
import { Row } from "@tanstack/react-table"
import { {Resource} } from "@/lib/validations/{resource}s"
import { Button } from "@/components/ui/button"
import { AlertDialog, AlertDialogTrigger } from "@/components/ui/alert-dialog"
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import Delete{Resource} from "./delete-{resource}"
import { Icons } from "@/components/icons"

interface Props {
  row: Row<{Resource}>
}

export function {Resource}sTableRowActions({ row }: Props) {
  const [open, setOpen] = useState(false)

  const onChange = (open: boolean) => {
    if (!open) setOpen(false)
  }

  return (
    <AlertDialog open={open} onOpenChange={onChange}>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="flex size-8 p-0 data-[state=open]:bg-muted">
            <Icons.dotsHorizontal className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-[160px]">
          <DropdownMenuItem onClick={() => navigate(`/{resource}s/${row.original.id}/edit`)}>
            Edit
          </DropdownMenuItem>
          <AlertDialogTrigger asChild onClick={() => setOpen(true)}>
            <DropdownMenuItem>Delete</DropdownMenuItem>
          </AlertDialogTrigger>
        </DropdownMenuContent>
      </DropdownMenu>
      <Delete{Resource} id={row.original.id} onOpenChange={onChange} />
    </AlertDialog>
  )
}
```

---

### 3.2 Forms (Create/Edit)

**When to use:** Single form component handles both create and edit modes.

```tsx
// components/{resource}s/{resource}-form.tsx
"use client"

import { useState } from "react"
import { zodResolver } from "@hookform/resolvers/zod"
import { useMutation, useQueryClient } from "@tanstack/react-query"
import axios, { AxiosError } from "axios"
import { useForm } from "react-hook-form"

import { cn } from "@/lib/utils"
import {
  {Resource}Details, {Resource}FormPayload, Safe{Resource},
  {resource}Schema, update{Resource}Schema,
} from "@/lib/validations/{resource}s"
import { Button, buttonVariants } from "@/components/ui/button"
import { AlertDialog, AlertDialogTrigger } from "@/components/ui/alert-dialog"
import {
  Form, FormControl, FormField, FormItem, FormLabel, FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { useToast } from "@/components/ui/use-toast"
import Delete{Resource} from "./delete-{resource}"
import { Icons } from "@/components/icons"

interface {Resource}FormProps {
  {resource}?: {Resource}Details   // undefined = create, defined = edit
}

const {Resource}Form = ({ {resource} }: {Resource}FormProps) => {
  const { toast } = useToast()
  const [open, setOpen] = useState(false)
  const queryClient = useQueryClient()

  const { mutate, isPending } = useMutation({
    mutationFn: async (data: {Resource}FormPayload) => {
      const url = {resource} ? `/api/{resource}s/${{resource}.id}` : `/api/{resource}s`
      const method = {resource} ? "put" : "post"
      return axios[method](url, data)
    },
    onSuccess: (data) => {
      toast({
        variant: "success",
        title: {resource} ? "Updated Successfully" : "Created Successfully",
      })
      queryClient.invalidateQueries({ queryKey: ["{resource}s"] })
      // Navigate after success
    },
    onError: (err: AxiosError) => {
      toast({
        variant: "destructive",
        title: (err?.response?.data as string) || "Failed to perform your request",
      })
    },
  })

  const form = useForm<Safe{Resource}>({
    resolver: zodResolver({resource} ? update{Resource}Schema : {resource}Schema),
    mode: "onChange",
    criteriaMode: "all",
    defaultValues: {
      name_en: {resource}?.name_en || "",
      name_ar: {resource}?.name_ar || "",
    },
  })

  const onSubmit = (values: Safe{Resource}) => {
    const payload: {Resource}FormPayload = { /* map form values to payload */ }
    mutate(payload)
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name_en"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name (English)</FormLabel>
              <FormControl>
                <Input disabled={isPending} placeholder="Enter name" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        {/* More fields... */}

        <Button disabled={isPending || !form.formState.isValid} type="submit"
          className={cn("w-full capitalize", buttonVariants({ size: "lg" }))}>
          {{resource} ? "update" : "create"}
        </Button>
      </form>

      {{resource} && (
        <AlertDialog open={open} onOpenChange={(o) => !o && setOpen(false)}>
          <AlertDialogTrigger asChild onClick={() => setOpen(true)}>
            <div className="mt-5 text-center">
              <Button variant="ghost" className="text-destructive hover:text-destructive">
                <Icons.trash className="me-2 size-5" /> Delete
              </Button>
            </div>
          </AlertDialogTrigger>
          <Delete{Resource} id={{resource}.id} onOpenChange={(o) => !o && setOpen(false)} />
        </AlertDialog>
      )}
    </Form>
  )
}
export default {Resource}Form
```

**Key conventions:**
- Single component for create AND edit (prop presence determines mode)
- Different Zod schema for create vs update
- `mode: "onChange"` for real-time validation
- Submit button disabled when `!formState.isValid`
- Delete dialog only shown in edit mode

---

### 3.3 Dynamic Field Arrays

**When to use:** Repeatable form sections (variations, options).

```tsx
import { useFieldArray } from "react-hook-form"

const { fields, append, remove } = useFieldArray({
  control: form.control,
  name: "variations",
})

{fields.map((field, index) => (
  <div key={field.id} className="flex items-center gap-2">
    <FormField
      control={form.control}
      name={`variations.${index}.name_en`}
      render={({ field }) => (
        <FormItem>
          <FormControl><Input {...field} /></FormControl>
          <FormMessage />
        </FormItem>
      )}
    />
    <Button variant="ghost" onClick={() => remove(index)}>
      <Icons.trash className="size-4" />
    </Button>
  </div>
))}
<Button type="button" variant="outline" onClick={() => append({ name_en: "", name_ar: "" })}>
  <Icons.add className="me-1 size-4" /> Add variation
</Button>
```

---

### 3.4 Delete Confirmation AlertDialog

**When to use:** Every delete action needs a confirmation dialog. Use `AlertDialog` (not `Dialog`) — it prevents accidental dismissal and is semantically correct for destructive actions.

```tsx
// components/{resource}s/delete-{resource}.tsx
import { useMutation, useQueryClient } from "@tanstack/react-query"
import { cn } from "@/lib/utils"
import { Button, buttonVariants } from "@/components/ui/button"
import {
  AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { toast } from "@/components/ui/use-toast"
import { Icons } from "@/components/icons"
import axios, { AxiosError } from "axios"

const Delete{Resource} = ({
  id,
  onOpenChange,
}: {
  id: string
  onOpenChange: (open: boolean) => void
}) => {
  const queryClient = useQueryClient()

  const { mutate, isPending } = useMutation({
    mutationFn: async () => axios.delete(`/api/{resource}s/${id}`),
    onSuccess: () => {
      toast({ title: "Deleted Successfully", variant: "success" })
      onOpenChange(false)
      queryClient.invalidateQueries({ queryKey: ["{resource}s"] })
    },
    onError: (err: AxiosError) => {
      toast({
        title: err?.response?.data as string,
        description: "{Resource} has not been deleted. Please try again.",
        variant: "destructive",
      })
    },
  })

  return (
    <AlertDialogContent>
      <AlertDialogHeader className="text-center">
        <AlertDialogTitle className="font-bold">Delete {resource}?</AlertDialogTitle>
        <AlertDialogDescription>Delete {resource} forever?</AlertDialogDescription>
      </AlertDialogHeader>
      <AlertDialogFooter className="flex space-y-3 sm:flex-col sm:space-x-0">
        <AlertDialogAction onClick={() => mutate()} disabled={isPending}
          className={cn("w-full capitalize bg-destructive text-destructive-foreground hover:bg-destructive/90", buttonVariants({ size: "lg" }))}>
          <Icons.trash className="me-2 size-5" /> delete
        </AlertDialogAction>
        <AlertDialogCancel disabled={isPending}
          className={cn("w-full capitalize", buttonVariants({ size: "lg" }))}>
          cancel
        </AlertDialogCancel>
      </AlertDialogFooter>
    </AlertDialogContent>
  )
}
export default Delete{Resource}
```

**Key conventions:**
- Uses `AlertDialog` (not `Dialog`) for destructive confirmation
- Component renders `AlertDialogContent` only (parent manages trigger)
- Uses `queryClient.invalidateQueries` after delete

---

### 3.5 Loading States & Skeletons

#### DataTableSkeleton
```tsx
import { Skeleton } from "@/components/ui/skeleton"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

const columns = Array.from({ length: 5 })
const rows = Array.from({ length: 10 })

export function DataTableSkeleton() {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          {columns.map((_, i) => (
            <TableHead key={i}><Skeleton className="h-4 w-[50px]" /></TableHead>
          ))}
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((_, i) => (
          <TableRow key={i}>
            {columns.map((_, j) => (
              <TableCell key={j}><Skeleton className="h-9 w-[60px]" /></TableCell>
            ))}
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
```

#### FormSkeleton
```tsx
const FormSkeleton = ({ num }: { num: number }) => (
  <>
    <div className="space-y-4">
      {Array.from({ length: num }).map((_, i) => (
        <div className="space-y-2" key={i}>
          <Skeleton className="h-5 w-1/4 rounded-md" />
          <Skeleton className="h-10 rounded-md" />
        </div>
      ))}
    </div>
    <Skeleton className="mt-6 h-10 w-full" />
  </>
)
```

#### Component.Skeleton Pattern
```tsx
export const {Resource}Card = ({ {resource} }: Props) => {
  return <Card>...</Card>
}

{Resource}Card.Skeleton = function {Resource}CardSkeleton() {
  return (
    <Card>
      <Skeleton className="h-10 w-40" />
    </Card>
  )
}
```

---

### 3.6 Toast Notifications

```tsx
import { useToast } from "@/components/ui/use-toast"
// or for non-component contexts:
import { toast } from "@/components/ui/use-toast"

// Success
toast({ variant: "success", title: "{Resource} created Successfully" })

// Error
toast({ variant: "destructive", title: "Failed to perform your request" })

// With description
toast({
  variant: "destructive",
  title: "Delete failed",
  description: "{Resource} has not been deleted. Please try again.",
})
```

**Variants:** `"success"`, `"destructive"`, `"default"`

---

### 3.7 i18n, RTL & Dark Mode

**When to use:** Every user-facing component.

#### Translations

All user-facing text must use `t("key")` — no hardcoded strings:

```tsx
// ❌ BAD — hardcoded strings
<span>No data found</span>
<Button>Save</Button>

// ✅ GOOD — translated
<span>{t("no_data_found")}</span>
<Button>{t("save")}</Button>
```

**Translation key rules:**
- Add keys to **both** `en` and `ar` locale files
- Never accidentally change existing translation key values (e.g., `"Settings"` → `"settings"`)
- Every `t("key")` call must have a corresponding entry in both locale files — no fallback-only patterns like `t("key") || "fallback"`
- **Before removing keys**, grep for all usages (`t("key_name")`) across the codebase. Removing a key another component still uses causes raw key strings to appear for users (especially breaking for Arabic)

#### RTL Support

Always handle `lng === "ar"` for RTL layouts:

```tsx
<ScrollArea dir={lng === "ar" ? "rtl" : "ltr"}>
  <div className="ltr:mr-4 rtl:ml-4">
    <Icons.chevronRight className="rtl:rotate-180" />
  </div>
</ScrollArea>
```

- Use `rtl:` Tailwind prefix for RTL-specific styles
- Use `ltr:` Tailwind prefix for LTR-specific styles
- Use `dir` attribute on ScrollArea and other directional components

#### Dark Mode

Every component needs `dark:` Tailwind variants:

```tsx
className="bg-white dark:bg-card text-gray-900 dark:text-foreground"
```

#### Required States

Every data-driven component must handle all three states:

| State | Requirement |
|-------|-------------|
| **Loading** | Skeleton placeholder while data loads (see Section 3.5) |
| **Error** | Error handling UI for failed fetches |
| **Empty** | Graceful UI when data array is empty |

---

## Part 4: Advanced Patterns

### 4.1 Combobox with Infinite Scroll

**When to use:** Selecting from large lists (vendors, clients) — NOT basic `<Select>`.

```tsx
"use client"

import { useCallback, useRef, useState } from "react"
import { useDebounce } from "@uidotdev/usehooks"
import { Check, ChevronsUpDown, Search } from "lucide-react"

import { cn } from "@/lib/utils"
import { use{Resource}s } from "@/hooks/use-{resource}s"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Separator } from "@/components/ui/separator"
import { Icons } from "@/components/icons"

interface {Resource}sComboboxProps {
  value: { id: string; name_en: string }[]
  onChange: (value: { id: string; name_en: string }[]) => void
  single?: boolean
}

export const {Resource}sCombobox = ({ value, onChange, single }: {Resource}sComboboxProps) => {
  const [open, setOpen] = useState(false)
  const [searchTerm, setSearch] = useState("")
  const debouncedSearch = useDebounce(searchTerm, 500)

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isLoading } = use{Resource}s(debouncedSearch)
  const items = data?.pages?.flatMap((page) => page.data) ?? []

  // IntersectionObserver for infinite scroll
  const observer = useRef<IntersectionObserver | null>(null)
  const lastElementRef = useCallback(
    (node: HTMLDivElement) => {
      if (isLoading) return
      if (observer.current) observer.current.disconnect()
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasNextPage) fetchNextPage()
      })
      if (node) observer.current.observe(node)
    },
    [isLoading, hasNextPage, fetchNextPage]
  )

  return (
    <Popover open={open} onOpenChange={setOpen} modal={true}>
      <PopoverTrigger asChild>
        <Button variant="outline" role="combobox" className="w-full justify-between">
          {value.length > 0 ? value[0].name_en : "Select..."}
          <ChevronsUpDown className="ml-2 size-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[--radix-popover-trigger-width] p-0">
        <Input placeholder="Search..." value={searchTerm} onChange={(e) => setSearch(e.target.value)} />
        <Separator />
        <div className="flex max-h-[300px] flex-col overflow-y-auto">
          {items.map((item, index) => (
            <div
              key={item.id}
              ref={index === items.length - 1 ? lastElementRef : undefined}
              onClick={() => { /* handleSelect */ }}
              className="flex cursor-pointer items-center p-2 hover:bg-gray-100"
            >
              <Check className={cn("mr-2 size-4", value.some((v) => v.id === item.id) ? "opacity-100" : "opacity-0")} />
              <span>{item.name_en}</span>
            </div>
          ))}
          {isFetchingNextPage && <Icons.spinner className="mx-auto size-4 animate-spin" />}
        </div>
      </PopoverContent>
    </Popover>
  )
}
```

**Key conventions:**
- `useDebounce` (500ms) for search
- `IntersectionObserver` on last element triggers `fetchNextPage()`
- `Popover` with `modal={true}`
- `PopoverContent` width: `w-[--radix-popover-trigger-width]`
- **Self-contained** — combobox fetches its own data via internal hook. Parent only receives the selected ID via `onChange`. Never fetch data in the parent and pass it down
- **Value is `{ value, label }`, never just an ID** — form field stores `{ value: id, label: name }`. Combobox displays `selectedItem.label` directly — no `.find()` on the data array. Storing only the ID forces a `.find()` lookup on every render, which breaks with paginated data when the selected item isn't in the current page

---

### 4.2 Multi-Step Forms

**When to use:** Complex forms with multiple sections.

```tsx
import { useState } from "react"
import { Form } from "@/components/ui/form"
import { Tabs, TabsContent } from "@/components/ui/tabs"

const steps = [
  { value: "info", label: "Information" },
  { value: "details", label: "Details" },
  { value: "settings", label: "Settings" },
]

const {Resource}Form = ({ {resource} }: Props) => {
  const [activeStep, setActiveStep] = useState("info")
  const form = useForm(/* ... */)

  return (
    <Form {...form}>
      <div className="mb-8 text-center">
        <h4 className="text-sm text-muted-foreground">
          Step {steps.findIndex((s) => s.value === activeStep) + 1} / {steps.length}
        </h4>
        <h3 className="text-base font-semibold">
          {steps.find((s) => s.value === activeStep)?.label}
        </h3>
      </div>

      <form onSubmit={form.handleSubmit(onSubmit)}>
        <Tabs value={activeStep} onValueChange={setActiveStep}>
          <TabsContent value="info">
            <Step1 form={form} onNext={() => setActiveStep("details")} />
          </TabsContent>
          <TabsContent value="details">
            <Step2 form={form} onNext={() => setActiveStep("settings")} />
          </TabsContent>
          <TabsContent value="settings">
            <Step3 form={form} />  {/* Last step has submit */}
          </TabsContent>
        </Tabs>
      </form>
    </Form>
  )
}
```

**Key:** Single `useForm` wraps all steps. Only last step has submit button.

---

### 4.3 DnD Ordering

**When to use:** Reordering lists (playlists, banners, categories).

```tsx
"use client"

import { useMutation } from "@tanstack/react-query"
import axios from "axios"
import React from "react"

import { Button } from "@/components/ui/button"
import { Sortable, SortableItem, SortableDragHandle } from "@/components/ui/sortable"
import { useToast } from "@/components/ui/use-toast"
import { Icons } from "@/components/icons"

export const {Resource}sOrder = ({ items }: { items: {Resource}[] }) => {
  const [sortedItems, setSortedItems] = React.useState(items)
  const { toast } = useToast()

  const { mutate, isPending } = useMutation({
    mutationFn: (values: { id: string; order: number }[]) =>
      axios.post(`/api/{resource}s/order`, values),
    onSuccess: () => toast({ variant: "success", title: "Order updated" }),
    onError: () => toast({ variant: "destructive", title: "Failed to update order" }),
  })

  const saveOrder = () => {
    mutate(sortedItems.map((item, index) => ({ id: item.id, order: index })))
  }

  return (
    <>
      <Button onClick={saveOrder}><Icons.check className="me-1 size-5" /> Save Order</Button>
      <Sortable value={sortedItems} onValueChange={setSortedItems} orientation="vertical">
        {sortedItems.map((item) => (
          <SortableItem key={item.id} value={item.id} asChild>
            <div className="flex items-center gap-2">
              <SortableDragHandle variant="ghost" size="icon" disabled={isPending}>
                <Icons.grip className="size-5 text-muted-foreground" />
              </SortableDragHandle>
              <{Resource}Card item={item} />
            </div>
          </SortableItem>
        ))}
      </Sortable>
    </>
  )
}
```

---

### 4.4 Image/File Upload

**When to use:** Forms with image upload.

```tsx
<FormField
  control={form.control}
  name="image"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Image</FormLabel>
      <FormControl>
        <div className="flex flex-col items-center gap-3">
          <Avatar className="h-[273px] w-[600px] rounded-md">
            <AvatarImage src={field.value ? URL.createObjectURL(field.value) : existingUrl} />
            <AvatarFallback className="rounded-md">
              <Icons.media className="size-10 text-muted-foreground" />
            </AvatarFallback>
          </Avatar>
          <div className="relative">
            <Button variant="link"><Icons.media className="me-1 size-5" /> Upload</Button>
            <Input
              type="file" accept="image/jpeg,image/jpg" value={undefined}
              onChange={(e) => { if (e.target.files?.[0]) field.onChange(e.target.files[0]) }}
              className="absolute inset-0 z-10 size-full cursor-pointer opacity-0"
            />
          </div>
        </div>
      </FormControl>
      <FormMessage />
    </FormItem>
  )}
/>
```

**Submit with FormData:**
```ts
const formData = new FormData()
formData.append("image", new Blob([file], { type: file.type }), `${Date.now()}.${ext}`)
formData.append("name", values.name)
mutate(formData)
```

---

### 4.5 Date Handling (Kuwait Timezone)

```ts
import { format, toDate, utcToZonedTime, zonedTimeToUtc } from "date-fns-tz"

const kuwaitTimezone = "Asia/Kuwait"

// UTC string → Kuwait Date
function getKuwaitDate(date: string): Date {
  return utcToZonedTime(toDate(date, { timeZone: "UTC" }), kuwaitTimezone)
}

// Format with Kuwait timezone
function formatDate(input: string, pattern: string): string {
  return format(getKuwaitDate(input), pattern, { timeZone: kuwaitTimezone })
}

// Kuwait Date → UTC (for API requests)
function getUtcFromKuwaitDate(date: Date): Date {
  return zonedTimeToUtc(date, kuwaitTimezone)
}
```

---

## Appendix

### Common Pitfalls

1. **Don't use `useEffect` for derived state** — calculate directly or use `useMemo`
2. **Don't use React state for URL-driven data** — use URL params for filters/pagination/sorting
3. **Don't use `<Select>` for large datasets** — use Combobox with infinite scroll
4. **Don't forget both `_en` and `_ar` fields** — bilingual content needs pairs
5. **Don't forget cache invalidation** — call `queryClient.invalidateQueries()` after every mutation
6. **Don't forget the delete dialog** — every delete needs confirmation
7. **Don't forget loading states** — show skeletons while data loads
8. **Don't use `useEffect` for event handling** — use event handlers directly
9. **Don't use `useEffect` to reset state** — use the `key` prop
10. **Don't forget `enabled` on useQuery** — prevent fetches when params are missing
11. **Use `const` over `let`** — `const res = await fetch(...)` not `let res`. Only `let` when actually reassigned
20. **Use `var qs = require("qs")` for qs** — this is the correct import style for `qs` in the project, not `import qs from "qs"`
12. **No empty catch blocks** — `catch (error) {}` silently swallows errors. Always re-throw, log, or surface a message
13. **Update all names when copy-pasting** — change every `export function`, `export default function`, and `export const` to match the new entity
14. **External links must use `<a>` tags** — map links, external URLs use `<a>` or `Link`, not `<Button>` or `<div>`
15. **Use Popover for truncated text** — long addresses, descriptions need `Popover` so users can view the full content
16. **`components/ui/` changes are global** — modifying base UI primitives affects every instance app-wide. Add classes locally if the change is only needed in one place
17. **Shared utilities must be generic** — functions in `lib/utils.ts` must not reference specific module names in JSDoc or error messages
18. **Use proper component variant props** — don't use `className?.includes("compact")` for conditional styling; use dedicated `size`/`variant` props
19. **Shared rendering for shared types** — when multiple data flows produce the same type, share rendering components; only the data fetching/transformation layer should differ
