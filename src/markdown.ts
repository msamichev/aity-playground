import type { Todo } from './store.js';

/**
 * Сериализует список задач в Markdown-чеклист (GitHub-стиль).
 * Каждая задача — строка `- [x] <title>` если done, иначе `- [ ] <title>`.
 * Строки соединяются `\n`. Порядок — как во входном массиве.
 * Пустой список → пустая строка ''.
 */
export function todosToMarkdown(todos: Todo[]): string {
  return todos
    .map((todo) => `- [${todo.done ? 'x' : ' '}] ${todo.title}`)
    .join('\n');
}
