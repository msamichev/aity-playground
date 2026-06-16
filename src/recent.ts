import type { Todo } from './store.js';

/**
 * Возвращает новый массив из n самых свежих задач (сортировка по createdAt по убыванию).
 * Входной массив не мутируется.
 *
 * @param todos  исходный массив задач
 * @param n      максимальное количество возвращаемых задач
 * @returns       до n задач, отсортированных от новых к старым; n <= 0 → []
 */
export function mostRecent(todos: Todo[], n: number): Todo[] {
  if (n <= 0) return [];

  const sorted = [...todos];
  sorted.sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  return sorted.slice(0, n);
}
