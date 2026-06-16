import type { Todo } from './store.js';

/**
 * Удаляет дубликаты задач по полю title (регистрозависимое сравнение).
 * Для каждого различного title оставляется первое вхождение.
 * Порядок элементов сохраняется, входной массив не мутируется.
 */
export function dedupeByTitle(todos: Todo[]): Todo[] {
  const seen = new Set<string>();
  const result: Todo[] = [];

  for (const todo of todos) {
    if (!seen.has(todo.title)) {
      seen.add(todo.title);
      result.push(todo);
    }
  }

  return result;
}
