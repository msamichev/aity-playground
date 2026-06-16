import type { Todo } from './store.js';

/**
 * Экранирует поле CSV по RFC-4180:
 * если поле содержит запятую, двойную кавычку или перенос строки —
 * оборачиваем в двойные кавычки и удваиваем внутренние кавычки.
 */
function escapeField(value: string): string {
  if (value.includes(',') || value.includes('"') || value.includes('\n')) {
    return `"${value.replaceAll('"', '""')}"`;
  }
  return value;
}

/**
 * Сериализует список задач в строку CSV (RFC-4180).
 * Первая строка — заголовок `id,title,done,createdAt`.
 * Пустой список → только строка заголовка.
 */
export function todosToCsv(todos: Todo[]): string {
  const header = 'id,title,done,createdAt';

  const rows = todos.map((todo) =>
    [
      escapeField(todo.id),
      escapeField(todo.title),
      String(todo.done),
      escapeField(todo.createdAt),
    ].join(','),
  );

  return [header, ...rows].join('\n');
}
