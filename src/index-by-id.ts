import type { Todo } from './store.js';

/**
 * Строит словарь id → Todo из массива задач.
 * При совпадении id побеждает последний элемент в массиве.
 * Входной массив не мутируется.
 */
export function indexById(todos: Todo[]): Record<string, Todo> {
  const index: Record<string, Todo> = {};

  for (const todo of todos) {
    index[todo.id] = todo;
  }

  return index;
}
