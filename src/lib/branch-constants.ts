// src/lib/branch-constants.ts
//
// Centralized branch UUID constants. The DB stores branch_id as UUID
// (e.g. 'b1000000-0000-0000-0000-000000000001'), but several FE fallbacks
// used the human-readable code 'B001' which caused PostgREST 22P02
// (invalid_text_representation) when the column is queried with .eq().
//
// IMPORTANT: when adding new branches, add the matching row to the
// `public.branches` table first, then mirror the UUID here.

export const BRANCH_IDS = {
  /** Ngưu Cát Quận 1 — code B001, db row id below */
  B001: 'b1000000-0000-0000-0000-000000000001',
  /** Ngưu Cát Phú Nhuận — code B002, db row id below */
  B002: 'b1000000-0000-0000-0000-000000000002',
} as const

export const DEFAULT_BRANCH_ID = BRANCH_IDS.B001

export type BranchId = (typeof BRANCH_IDS)[keyof typeof BRANCH_IDS]
