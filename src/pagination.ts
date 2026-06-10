export interface PaginatedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
}

/**
 * Разбивает массив на страницы. Нормализует page и pageSize:
 * - page ≥ 1 (меньше → 1);
 * - pageSize ∈ [1, 100] (меньше → 1, больше → 100).
 */
export function paginate<T>(
  items: T[],
  page: number,
  pageSize: number,
): PaginatedResult<T> {
  const p = Math.max(1, Math.trunc(page));
  const ps = Math.min(100, Math.max(1, Math.trunc(pageSize)));

  const totalItems = items.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / ps));

  const start = (p - 1) * ps;
  const slice = items.slice(start, start + ps);

  return {
    items: slice,
    page: p,
    pageSize: ps,
    totalItems,
    totalPages,
  };
}
