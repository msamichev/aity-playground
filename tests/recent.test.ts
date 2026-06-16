import { describe, it, expect } from 'vitest';
import { mostRecent } from '../src/recent.js';
import type { Todo } from '../src/store.js';

describe('mostRecent', () => {
  const todos: Todo[] = [
    { id: '1', title: 'oldest', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
    { id: '3', title: 'newest', done: true, createdAt: '2025-03-01T00:00:00.000Z' },
    { id: '2', title: 'middle', done: false, createdAt: '2025-02-01T00:00:00.000Z' },
  ];

  // ── сортировка по убыванию createdAt ────────────────────────────

  it('сортировка по createdAt по убыванию (новые первыми)', () => {
    const result = mostRecent(todos, 3);
    expect(result.map(t => t.id)).toEqual(['3', '2', '1']);
  });

  // ── ограничение n ────────────────────────────────────────────────

  it('возвращает не более n задач', () => {
    const result = mostRecent(todos, 2);
    expect(result).toHaveLength(2);
    expect(result.map(t => t.id)).toEqual(['3', '2']);
  });

  it('n = 1 возвращает одну самую свежую', () => {
    const result = mostRecent(todos, 1);
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('3');
  });

  // ── n <= 0 → [] ──────────────────────────────────────────────────

  it('n = 0 возвращает пустой массив', () => {
    expect(mostRecent(todos, 0)).toEqual([]);
  });

  it('n < 0 возвращает пустой массив', () => {
    expect(mostRecent(todos, -1)).toEqual([]);
    expect(mostRecent(todos, -100)).toEqual([]);
  });

  // ── n больше длины списка → все (отсортированные) ────────────────

  it('n больше длины списка возвращает все задачи', () => {
    const result = mostRecent(todos, 10);
    expect(result).toHaveLength(3);
    expect(result.map(t => t.id)).toEqual(['3', '2', '1']);
  });

  // ── пустой список ────────────────────────────────────────────────

  it('пустой массив на входе', () => {
    expect(mostRecent([], 3)).toEqual([]);
    expect(mostRecent([], 0)).toEqual([]);
    expect(mostRecent([], -1)).toEqual([]);
  });

  // ── неизменность входного массива ───────────────────────────────

  it('не мутирует входной массив', () => {
    const snapshot = [...todos];
    mostRecent(todos, 2);
    expect(todos).toEqual(snapshot);
  });

  // ── один элемент ─────────────────────────────────────────────────

  it('один элемент', () => {
    const single: Todo[] = [{ id: 'x', title: 'only', done: true, createdAt: '2025-05-05T00:00:00.000Z' }];
    expect(mostRecent(single, 1)).toEqual(single);
    expect(mostRecent(single, 5)).toEqual(single);
    expect(mostRecent(single, 0)).toEqual([]);
  });
});
