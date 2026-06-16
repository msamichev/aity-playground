import type { Todo } from './store.js';

/**
 * Возвращает новый отсортированный массив задач (входной не мутирует).
 *
 * @param todos  исходный массив задач
 * @param by     поле для сортировки: title — лексикографически,
 *               createdAt — по ISO-строке, done — false < true
 * @param dir    направление сортировки (по умолчанию asc)
 */
export function sortTodos(
  todos: Todo[],
  by: 'title' | 'createdAt' | 'done',
  dir: 'asc' | 'desc' = 'asc',
): Todo[] {
  const sorted = [...todos];

  sorted.sort((a, b) => {
    let cmp: number;
    if (by === 'title') {
      cmp = a.title.localeCompare(b.title);
    } else if (by === 'createdAt') {
      cmp = a.createdAt.localeCompare(b.createdAt);
    } else {
      // done: false < true
      cmp = a.done === b.done ? 0 : a.done ? 1 : -1;
    }
    return dir === 'desc' ? -cmp : cmp;
  });

  return sorted;
}
