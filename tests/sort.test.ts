import { describe, it, expect } from 'vitest';
import { sortTodos } from '../src/sort.js';
import type { Todo } from '../src/store.js';

describe('sortTodos', () => {
  const todos: Todo[] = [
    { id: '3', title: 'ccc', done: false, createdAt: '2025-03-01T00:00:00.000Z' },
    { id: '1', title: 'aaa', done: true, createdAt: '2025-01-01T00:00:00.000Z' },
    { id: '2', title: 'bbb', done: false, createdAt: '2025-02-01T00:00:00.000Z' },
  ];

  // ── title ──────────────────────────────────────────────────────

  it('сортировка по title asc', () => {
    const result = sortTodos(todos, 'title', 'asc');
    expect(result.map(t => t.id)).toEqual(['1', '2', '3']);
  });

  it('сортировка по title desc', () => {
    const result = sortTodos(todos, 'title', 'desc');
    expect(result.map(t => t.id)).toEqual(['3', '2', '1']);
  });

  it('dir по умолчанию asc', () => {
    const result = sortTodos(todos, 'title');
    expect(result.map(t => t.id)).toEqual(['1', '2', '3']);
  });

  // ── createdAt ───────────────────────────────────────────────────

  it('сортировка по createdAt asc', () => {
    const result = sortTodos(todos, 'createdAt', 'asc');
    expect(result.map(t => t.id)).toEqual(['1', '2', '3']);
  });

  it('сортировка по createdAt desc', () => {
    const result = sortTodos(todos, 'createdAt', 'desc');
    expect(result.map(t => t.id)).toEqual(['3', '2', '1']);
  });

  // ── done ────────────────────────────────────────────────────────

  it('сортировка по done asc (false < true)', () => {
    const result = sortTodos(todos, 'done', 'asc');
    expect(result.map(t => t.id)).toEqual(['3', '2', '1']);
  });

  it('сортировка по done desc (true < false)', () => {
    const result = sortTodos(todos, 'done', 'desc');
    expect(result.map(t => t.id)).toEqual(['1', '3', '2']);
  });

  // ── неизменность входного массива ──────────────────────────────

  it('не мутирует входной массив', () => {
    const snapshot = [...todos];
    sortTodos(todos, 'title', 'asc');
    expect(todos).toEqual(snapshot);
  });

  // ── краевые случаи ─────────────────────────────────────────────

  it('пустой массив', () => {
    expect(sortTodos([], 'title')).toEqual([]);
    expect(sortTodos([], 'createdAt')).toEqual([]);
    expect(sortTodos([], 'done')).toEqual([]);
  });

  it('один элемент', () => {
    const single: Todo[] = [{ id: 'x', title: 'only', done: true, createdAt: '2025-05-05T00:00:00.000Z' }];
    expect(sortTodos(single, 'title')).toEqual(single);
    expect(sortTodos(single, 'title', 'desc')).toEqual(single);
  });
});
