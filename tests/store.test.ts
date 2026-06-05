import { beforeEach, describe, expect, it } from 'vitest';
import { TodoStore } from '../src/store.js';

describe('TodoStore', () => {
  let store: TodoStore;

  beforeEach(() => {
    store = new TodoStore();
  });

  it('создаёт задачу с дефолтами', () => {
    const todo = store.create('buy milk');
    expect(todo.id).toBeTypeOf('string');
    expect(todo.title).toBe('buy milk');
    expect(todo.done).toBe(false);
    expect(todo.createdAt).toBeTypeOf('string');
  });

  it('возвращает список созданных задач', () => {
    store.create('a');
    store.create('b');
    expect(store.list()).toHaveLength(2);
  });

  it('отдаёт задачу по id и undefined для отсутствующей', () => {
    const todo = store.create('x');
    expect(store.get(todo.id)).toEqual(todo);
    expect(store.get('missing')).toBeUndefined();
  });

  it('переключает done', () => {
    const todo = store.create('x');
    expect(store.toggle(todo.id)?.done).toBe(true);
    expect(store.toggle(todo.id)?.done).toBe(false);
    expect(store.toggle('missing')).toBeUndefined();
  });

  it('выставляет done явно', () => {
    const todo = store.create('x');
    expect(store.setDone(todo.id, true)?.done).toBe(true);
    expect(store.setDone('missing', true)).toBeUndefined();
  });

  it('удаляет задачу', () => {
    const todo = store.create('x');
    expect(store.delete(todo.id)).toBe(true);
    expect(store.delete(todo.id)).toBe(false);
    expect(store.list()).toHaveLength(0);
  });

  it('очищает все задачи', () => {
    store.create('a');
    store.clear();
    expect(store.list()).toHaveLength(0);
  });
});
