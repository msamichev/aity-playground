import type { Todo } from './store.js';

/**
 * Разбивает список задач на две группы: выполненные и невыполненные.
 * Порядок внутри каждой группы сохраняется как во входном массиве.
 * Входной массив не мутируется.
 */
export function groupByStatus(todos: Todo[]): { done: Todo[]; pending: Todo[] } {
  const done: Todo[] = [];
  const pending: Todo[] = [];

  for (const todo of todos) {
    if (todo.done) {
      done.push(todo);
    } else {
      pending.push(todo);
    }
  }

  return { done, pending };
}
