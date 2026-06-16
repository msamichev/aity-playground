import { describe, it, expect } from 'vitest';
import { groupByDay } from '../src/by-day.js';
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

describe('by-day', () => {
  describe('groupByDay', () => {
    it('должна возвращать {} для пустого входа', () => {
      const result = groupByDay([]);

      expect(result).toEqual({});
    });

    it('должна все задачи помещать в одну группу, если у них одинаковая дата', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', title: 'A', createdAt: '2026-06-15T10:00:00.000Z' }),
        makeTodo({ id: '2', title: 'B', createdAt: '2026-06-15T14:30:00.000Z' }),
        makeTodo({ id: '3', title: 'C', createdAt: '2026-06-15T23:59:59.000Z' }),
      ];

      const result = groupByDay(todos);

      expect(Object.keys(result)).toHaveLength(1);
      expect(result['2026-06-15']).toHaveLength(3);
      expect(result['2026-06-15'].map(t => t.id)).toEqual(['1', '2', '3']);
    });

    it('должна разбивать задачи по разным дням', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', title: 'A', createdAt: '2026-06-14T08:00:00.000Z' }),
        makeTodo({ id: '2', title: 'B', createdAt: '2026-06-15T12:00:00.000Z' }),
        makeTodo({ id: '3', title: 'C', createdAt: '2026-06-16T18:00:00.000Z' }),
      ];

      const result = groupByDay(todos);

      expect(Object.keys(result)).toHaveLength(3);
      expect(result['2026-06-14'].map(t => t.id)).toEqual(['1']);
      expect(result['2026-06-15'].map(t => t.id)).toEqual(['2']);
      expect(result['2026-06-16'].map(t => t.id)).toEqual(['3']);
    });

    it('должна сохранять исходный порядок задач внутри каждого дня', () => {
      const todos: Todo[] = [
        makeTodo({ id: 'a', title: 'First', createdAt: '2026-06-14T10:00:00.000Z' }),
        makeTodo({ id: 'b', title: 'Second', createdAt: '2026-06-14T11:00:00.000Z' }),
        makeTodo({ id: 'c', title: 'Third', createdAt: '2026-06-15T09:00:00.000Z' }),
        makeTodo({ id: 'd', title: 'Fourth', createdAt: '2026-06-15T14:00:00.000Z' }),
        makeTodo({ id: 'e', title: 'Fifth', createdAt: '2026-06-14T12:00:00.000Z' }),
      ];

      const result = groupByDay(todos);

      expect(result['2026-06-14'].map(t => t.id)).toEqual(['a', 'b', 'e']);
      expect(result['2026-06-15'].map(t => t.id)).toEqual(['c', 'd']);
    });

    it('не должна мутировать входной массив', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', createdAt: '2026-06-14T10:00:00.000Z' }),
        makeTodo({ id: '2', createdAt: '2026-06-15T10:00:00.000Z' }),
      ];
      const snapshot = [...todos];

      groupByDay(todos);

      expect(todos).toEqual(snapshot);
    });

    it('должна корректно обрабатывать одну задачу', () => {
      const todos: Todo[] = [
        makeTodo({ id: '1', title: 'Solo', createdAt: '2026-06-16T10:00:00.000Z' }),
      ];

      const result = groupByDay(todos);

      expect(Object.keys(result)).toHaveLength(1);
      expect(result['2026-06-16']).toHaveLength(1);
      expect(result['2026-06-16'][0].id).toBe('1');
    });
  });
});
