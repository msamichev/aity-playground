import { describe, it, expect } from 'vitest';
import { totalWords } from '../src/word-count.js';
import type { Todo } from '../src/store.js';

describe('totalWords', () => {
  // ── несколько задач ──────────────────────────────────────────────────

  it('несколько задач с одним словом каждая', () => {
    const todos: Todo[] = [
      { id: '1', title: 'купить', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'продать', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: 'выбросить', done: true, createdAt: '2025-01-03T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(3);
  });

  it('задачи с несколькими словами', () => {
    const todos: Todo[] = [
      { id: '1', title: 'купить хлеб и молоко', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'позвонить маме', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(6);
  });

  // ── лишние пробелы ───────────────────────────────────────────────────

  it('игнорирует лишние пробелы (ведущие, замыкающие, множественные)', () => {
    const todos: Todo[] = [
      { id: '1', title: '  привет   мир  ', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(2);
  });

  it('заголовок из одних пробелов не добавляет слов', () => {
    const todos: Todo[] = [
      { id: '1', title: '     ', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(0);
  });

  // ── пустой список → 0 ────────────────────────────────────────────────

  it('пустой список возвращает 0', () => {
    expect(totalWords([])).toBe(0);
  });

  // ── пустой title ─────────────────────────────────────────────────────

  it('пустая строка в title не добавляет слов', () => {
    const todos: Todo[] = [
      { id: '1', title: '', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(0);
  });

  it('смесь пустых и непустых заголовков', () => {
    const todos: Todo[] = [
      { id: '1', title: '', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
      { id: '2', title: 'hello world', done: false, createdAt: '2025-01-02T00:00:00.000Z' },
      { id: '3', title: '   ', done: true, createdAt: '2025-01-03T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(2);
  });

  // ── неизменность входного массива ────────────────────────────────────

  it('не мутирует входной массив', () => {
    const todos: Todo[] = [
      { id: '1', title: 'hello world', done: false, createdAt: '2025-01-01T00:00:00.000Z' },
    ];
    const snapshot = JSON.parse(JSON.stringify(todos));
    totalWords(todos);
    expect(todos).toEqual(snapshot);
  });

  // ── один элемент ─────────────────────────────────────────────────────

  it('одна задача с одним словом', () => {
    const todos: Todo[] = [
      { id: 'x', title: 'only', done: true, createdAt: '2025-05-05T00:00:00.000Z' },
    ];
    expect(totalWords(todos)).toBe(1);
  });
});
