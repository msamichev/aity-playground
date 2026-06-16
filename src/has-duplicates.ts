import type { Todo } from './store.js';

/**
 * Проверяет, есть ли среди задач дубликаты по title (регистрозависимое сравнение).
 * Пустой массив и массив из одного элемента → false.
 * Входной массив не мутируется.
 */
export function hasDuplicateTitles(todos: Todo[]): boolean {
  const seen = new Set<string>();
  for (const todo of todos) {
    if (seen.has(todo.title)) {
      return true;
    }
    seen.add(todo.title);
  }
  return false;
}
