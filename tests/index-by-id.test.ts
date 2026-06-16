import { describe, it, expect } from 'vitest';
import { indexById } from '../src/index-by-id.js';
import type { Todo } from '../src/store.js';

describe('indexById', () => {
  it('строит словарь из обычного списка задач', () => {
    const todos: Todo[] = [
      { id: 'a', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: 'b', title: 'Call mom', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: 'c', title: 'Do laundry', done: false, createdAt: '2025-01-03T00:00:00.000Z' },
    ];

    const result = indexById(todos);

    expect(result).toEqual({
      a: { id: 'a', title: 'Buy milk', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      b: { id: 'b', title: 'Call mom', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
      c: { id: 'c', title: 'Do laundry', done: false, createdAt: '2025-01-03T00:00:00.000Z' },
    });
  });

  it('обеспечивает доступ к задаче по id', () => {
    const todos: Todo[] = [
      { id: 'x', title: 'Target', done: true, createdAt: '2025-05-05T00:00:00.000Z' },
      { id: 'y', title: 'Other', done: false, createdAt: '2025-05-06T00:00:00.000Z' },
    ];

    const index = indexById(todos);

    expect(index['x']).toEqual(todos[0]);
    expect(index['y']).toEqual(todos[1]);
  });

  it('при дубликате id побеждает последний', () => {
    const todos: Todo[] = [
      { id: 'dup', title: 'First', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: 'dup', title: 'Last', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
    ];

    const result = indexById(todos);

    // Один ключ, значение — последний элемент
    expect(Object.keys(result)).toHaveLength(1);
    expect(result['dup']).toEqual({
      id: 'dup',
      title: 'Last',
      done: true,
      createdAt: '2025-01-02T00:00:00.000Z',
    });
  });

  it('возвращает {} для пустого входа', () => {
    expect(indexById([])).toEqual({});
  });

  it('не мутирует входной массив', () => {
    const todos: Todo[] = [
      { id: '1', title: 'A', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'B', done: true, createdAt: '2025-01-02T00:00:00.000Z' },
    ];
    const snapshot = JSON.parse(JSON.stringify(todos));

    indexById(todos);

    expect(todos).toEqual(snapshot);
  });

  it('один элемент — словарь с одним ключом', () => {
    const todos: Todo[] = [
      { id: 'only', title: 'Only task', done: false, createdAt: '2025-06-16T00:00:00.000Z' },
    ];

    expect(indexById(todos)).toEqual({
      only: { id: 'only', title: 'Only task', done: false, createdAt: '2025-06-16T00:00:00.000Z' },
    });
  });
});
