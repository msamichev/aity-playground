import { describe, it, expect } from 'vitest';
import { todosToCsv } from '../src/csv.js';
import type { Todo } from '../src/store.js';

const sampleTodo = (overrides: Partial<Todo> = {}): Todo => ({
  id: 'a',
  title: 'Task',
  done: false,
  createdAt: '2025-01-01T00:00:00.000Z',
  ...overrides,
});

describe('todosToCsv', () => {
  it('возвращает только заголовок для пустого списка', () => {
    const result = todosToCsv([]);

    expect(result).toBe('id,title,done,createdAt');
  });

  it('сериализует обычный список задач', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'Buy milk', done: false, createdAt: '2025-01-01T10:00:00.000Z' }),
      sampleTodo({ id: '2', title: 'Walk dog', done: true, createdAt: '2025-01-02T12:00:00.000Z' }),
    ];

    const result = todosToCsv(todos);

    const lines = result.split('\n');
    expect(lines).toHaveLength(3);
    expect(lines[0]).toBe('id,title,done,createdAt');
    expect(lines[1]).toBe('1,Buy milk,false,2025-01-01T10:00:00.000Z');
    expect(lines[2]).toBe('2,Walk dog,true,2025-01-02T12:00:00.000Z');
  });

  it('экранирует title с запятой по RFC-4180', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'Buy milk, bread, and butter', done: false }),
    ];

    const result = todosToCsv(todos);

    const lines = result.split('\n');
    expect(lines[1]).toBe('1,"Buy milk, bread, and butter",false,2025-01-01T00:00:00.000Z');
  });

  it('экранирует title с двойной кавычкой по RFC-4180', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'He said "hello"', done: false }),
    ];

    const result = todosToCsv(todos);

    const lines = result.split('\n');
    expect(lines[1]).toBe('1,"He said ""hello""",false,2025-01-01T00:00:00.000Z');
  });

  it('экранирует title с переносом строки по RFC-4180', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'Line 1\nLine 2', done: false }),
    ];

    const result = todosToCsv(todos);

    const lines = result.split('\n');
    // перенос строки внутри экранированного поля; split по \n даст 3 части:
    // заголовок, "1,"Line 1, Line 2",false,..."
    expect(lines).toHaveLength(3); // header + строка с \n-полем (разбивается split'ом)
    expect(lines[0]).toBe('id,title,done,createdAt');
    expect(lines[1]).toBe('1,"Line 1');
    expect(lines[2]).toBe('Line 2",false,2025-01-01T00:00:00.000Z');
  });

  it('сериализует done как true/false строками', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', done: true }),
      sampleTodo({ id: '2', done: false }),
    ];

    const result = todosToCsv(todos);

    const lines = result.split('\n');
    expect(lines[1]).toContain(',true,');
    expect(lines[2]).toContain(',false,');
  });

  it('корректно обрабатывает один todo', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '42', title: 'Solo', done: true, createdAt: '2025-06-01T08:00:00.000Z' }),
    ];

    const result = todosToCsv(todos);

    expect(result).toBe(
      'id,title,done,createdAt\n' +
        '42,Solo,true,2025-06-01T08:00:00.000Z',
    );
  });
});
