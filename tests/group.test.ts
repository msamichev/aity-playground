import { describe, it, expect } from 'vitest';
import { groupByStatus } from '../src/group.js';
import type { Todo } from '../src/store.js';

function makeTodo(overrides: Partial<Todo> = {}): Todo {
  return {
    id: '1',
    title: 'Test',
    done: false,
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}

describe('group', () => {
  describe('groupByStatus', () => {
    it('должна возвращать пустые массивы для пустого входа', () => {
      const result = groupByStatus([]);

      expect(result).toEqual({ done: [], pending: [] });
    });

    it('должна все задачи помещать в done, если все выполнены', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', title: 'A', done: true }),
        makeTodo({ id: '2', title: 'B', done: true }),
        makeTodo({ id: '3', title: 'C', done: true }),
      ];

      const result = groupByStatus(todos);

      expect(result.done).toHaveLength(3);
      expect(result.pending).toHaveLength(0);
      expect(result.done.map(t => t.id)).toEqual(['1', '2', '3']);
    });

    it('должна все задачи помещать в pending, если все невыполнены', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', title: 'A', done: false }),
        makeTodo({ id: '2', title: 'B', done: false }),
      ];

      const result = groupByStatus(todos);

      expect(result.done).toHaveLength(0);
      expect(result.pending).toHaveLength(2);
      expect(result.pending.map(t => t.id)).toEqual(['1', '2']);
    });

    it('должна корректно разбивать смешанный список', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', title: 'A', done: false }),
        makeTodo({ id: '2', title: 'B', done: true }),
        makeTodo({ id: '3', title: 'C', done: false }),
        makeTodo({ id: '4', title: 'D', done: true }),
        makeTodo({ id: '5', title: 'E', done: false }),
      ];

      const result = groupByStatus(todos);

      expect(result.done.map(t => t.id)).toEqual(['2', '4']);
      expect(result.pending.map(t => t.id)).toEqual(['1', '3', '5']);
    });

    it('должна сохранять относительный порядок внутри групп', () => {
      const todos: Todo[] = [
        makeTodo({ id: 'a', title: 'First', done: true }),
        makeTodo({ id: 'b', title: 'Second', done: false }),
        makeTodo({ id: 'c', title: 'Third', done: true }),
        makeTodo({ id: 'd', title: 'Fourth', done: false }),
        makeTodo({ id: 'e', title: 'Fifth', done: true }),
      ];

      const result = groupByStatus(todos);

      // done-задачи должны идти в порядке появления во входном массиве
      expect(result.done.map(t => t.id)).toEqual(['a', 'c', 'e']);
      // pending-задачи — аналогично
      expect(result.pending.map(t => t.id)).toEqual(['b', 'd']);
    });

    it('не должна мутировать входной массив', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', done: true }),
        makeTodo({ id: '2', done: false }),
      ];
      const snapshot = [...todos];

      groupByStatus(todos);

      expect(todos).toEqual(snapshot);
    });
  });
});
