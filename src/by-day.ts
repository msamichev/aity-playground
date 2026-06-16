import type { Todo } from './store.js';

/**
 * Группирует задачи по дню создания.
 * Ключ — день в формате YYYY-MM-DD (первые 10 символов createdAt).
 * Значение — массив задач этого дня в исходном порядке.
 * Входной массив не мутируется.
 */
export function groupByDay(todos: Todo[]): Record<string, Todo[]> {
  const result: Record<string, Todo[]> = {};

  for (const todo of todos) {
    const day = todo.createdAt.slice(0, 10);
    const bucket = result[day];
    if (bucket) {
      bucket.push(todo);
    } else {
      result[day] = [todo];
    }
  }

  return result;
}
