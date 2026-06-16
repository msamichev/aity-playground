import { describe, it, expect } from 'vitest';
import { dedupeByTitle } from '../src/dedupe.js';
import type { Todo } from '../src/store.js';

describe('dedupeByTitle', () => {
  it('удаляет дубликаты — оставляет первое вхождение', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Call mom', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'Buy milk', done: true, createdAt: '2025-01-03T00:00:00.000Z' },
      { id: '4', title: 'Call mom', done: false, createdAt: '2025-01-04T00:00:00.000Z' },
      { id: '5', title: 'Do laundry', done: false, createdAt: '2025-01-05T00:00:00.000Z' },
    ];

    const result = dedupeByTitle(todos);

    expect(result).toEqual([
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Call mom', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '5', title: 'Do laundry', done: false, createdAt: '2025-01-05T00:00:00.000Z' },
    ]);
  });

  it('возвращает без изменений, если дубликатов нет', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Call mom', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'Do laundry', done: false, createdAt: '2025-01-03T00:00:00.000Z' },
    ];

    const result = dedupeByTitle(todos);

    expect(result).toEqual(todos);
  });

  it('возвращает [] для пустого входа', () => {
    expect(dedupeByTitle([])).toEqual([]);
  });

  it('сохраняет порядок элементов', () => {
    const todos: Todo[] = [
      { id: '3', title: 'ccc', done: false, createdAt: '2025-03-01T00:00:00.000Z' },
      { id: '1', title: 'aaa', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'bbb', done: false, createdAt: '2025-02-01T00:00:00.000Z' },
      { id: '4', title: 'aaa', done: true, createdAt: '2025-04-01T00:00:00.000Z' },
      { id: '5', title: 'ccc', done: true, createdAt: '2025-05-01T00:00:00.000Z' },
    ];

    const result = dedupeByTitle(todos);

    expect(result.map(t => t.id)).toEqual(['3', '1', '2']);
  });

  it('не мутирует входной массив', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Buy milk', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
    ];
    const snapshot = JSON.parse(JSON.stringify(todos));

    dedupeByTitle(todos);

    expect(todos).toEqual(snapshot);
  });

  it('различает регистр — Buy milk и buy milk считаются разными title', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'buy milk', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'BUY MILK', done: false, createdAt: '2025-01-03T00:00:00.000Z' },
    ];

    const result = dedupeByTitle(todos);

    expect(result).toHaveLength(3);
  });

  it('один элемент — возвращает массив с одним элементом', () => {
    const todos: Todo[] = [
      { id: 'x', title: 'only', done: true, createdAt: '2025-05-05T00:00:00.000Z' },
    ];

    expect(dedupeByTitle(todos)).toEqual(todos);
  });
});
