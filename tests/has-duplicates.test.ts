import { describe, it, expect } from 'vitest';
import { hasDuplicateTitles } from '../src/has-duplicates.js';
import type { Todo } from '../src/store.js';

describe('hasDuplicateTitles', () => {
  it('есть дубликаты → true', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Call mom', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'Buy milk', done: true, createdAt: '2025-01-03T00:00:00.000Z' },
    ];

    expect(hasDuplicateTitles(todos)).toBe(true);
  });

  it('все уникальны → false', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Call mom', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'Do laundry', done: false, createdAt: '2025-01-03T00:00:00.000Z' },
    ];

    expect(hasDuplicateTitles(todos)).toBe(false);
  });

  it('пустой → false', () => {
    expect(hasDuplicateTitles([])).toBe(false);
  });

  it('один элемент → false', () => {
    const todos: Todo[] = [
      { id: 'x', title: 'only', done: true, createdAt: '2025-05-05T00:00:00.000Z' },
    ];

    expect(hasDuplicateTitles(todos)).toBe(false);
  });

  it('разный регистр → false (Buy milk ≠ buy milk)', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'buy milk', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'BUY MILK', done: false, createdAt: '2025-01-03T00:00:00.000Z' },
    ];

    expect(hasDuplicateTitles(todos)).toBe(false);
  });

  it('не мутирует входной массив', () => {
    const todos: Todo[] = [
      { id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'Buy milk', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
    ];
    const snapshot = JSON.parse(JSON.stringify(todos));

    hasDuplicateTitles(todos);

    expect(todos).toEqual(snapshot);
  });
});
