import type { Todo } from './store.js';

/**
 * Возвращает суммарное число слов во всех заголовках задач.
 * Слова — непустые последовательности, разделённые пробелами.
 * Входной массив не мутируется.
 *
 * @param todos  исходный массив задач
 * @returns      общее количество слов по всем title; пустой список → 0
 */
export function totalWords(todos: Todo[]): number {
  let total = 0;
  for (const t of todos) {
    if (t.title.trim() === '') continue;
    total += t.title.trim().split(/\s+/).length;
  }
  return total;
}
