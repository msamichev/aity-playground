import { describe, it, expect } from 'vitest';
import { todosToMarkdown } from '../src/markdown.js';
import type { Todo } from '../src/store.js';

const sampleTodo = (overrides: Partial<Todo> = {}): Todo => ({
  id: 'a',
  title: 'Task',
  done: false,
  createdAt: '2025-01-01T00:00:00.000Z',
  ...overrides,
});

describe('todosToMarkdown', () => {
  it('возвращает пустую строку для пустого списка', () => {
    const result = todosToMarkdown([]);

    expect(result).toBe('');
  });

  it('сериализует невыполненную задачу как - [ ]', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'Купить молока', done: false }),
    ];

    const result = todosToMarkdown(todos);

    expect(result).toBe('- [ ] Купить молока');
  });

  it('сериализует выполненную задачу как - [x]', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'Выгулять собаку', done: true }),
    ];

    const result = todosToMarkdown(todos);

    expect(result).toBe('- [x] Выгулять собаку');
  });

  it('сериализует смешанный список выполненных и невыполненных задач', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'A', done: false }),
      sampleTodo({ id: '2', title: 'B', done: true }),
      sampleTodo({ id: '3', title: 'C', done: false }),
    ];

    const result = todosToMarkdown(todos);

    expect(result).toBe('- [ ] A\n- [x] B\n- [ ] C');
  });

  it('сохраняет порядок задач как во входном массиве', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '3', title: 'Third', done: false }),
      sampleTodo({ id: '1', title: 'First', done: true }),
      sampleTodo({ id: '2', title: 'Second', done: false }),
    ];

    const result = todosToMarkdown(todos);

    const lines = result.split('\n');
    expect(lines[0]).toBe('- [ ] Third');
    expect(lines[1]).toBe('- [x] First');
    expect(lines[2]).toBe('- [ ] Second');
  });

  it('не мутирует входной массив', () => {
    const todos: Todo[] = [
      sampleTodo({ id: '1', title: 'Task', done: false }),
    ];

    const snapshot = JSON.stringify(todos);
    todosToMarkdown(todos);

    expect(JSON.stringify(todos)).toBe(snapshot);
  });
});
