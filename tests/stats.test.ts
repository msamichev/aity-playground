import { describe, it, expect } from 'vitest';
import { summarize } from '../src/stats.js';
import type { Todo } from '../src/store.js';

describe('stats', () => {
  describe('summarize', () => {
    it('should return all zeros for an empty list', () => {
      const todos: Todo[] = [];
      const result = summarize(todos);

      expect(result).toEqual({
        total: 0,
        done: 0,
        pending: 0,
        completionRate: 0
      });
    });

    it('should return completionRate of 1 when all tasks are done', () => {
      const todos: Todo[] = [
        { id: '1', title: 'Task 1', done: true, createdAt: new Date().toISOString() },
        { id: '2', title: 'Task 2', done: true, createdAt: new Date().toISOString() },
        { id: '3', title: 'Task 3', done: true, createdAt: new Date().toISOString() }
      ];
      const result = summarize(todos);

      expect(result).toEqual({
        total: 3,
        done: 3,
        pending: 0,
        completionRate: 1
      });
    });

    it('should calculate correctly for mixed case (1 done out of 3)', () => {
      const todos: Todo[] = [
        { id: '1', title: 'Task 1', done: true, createdAt: new Date().toISOString() },
        { id: '2', title: 'Task 2', done: false, createdAt: new Date().toISOString() },
        { id: '3', title: 'Task 3', done: false, createdAt: new Date().toISOString() }
      ];
      const result = summarize(todos);

      expect(result).toEqual({
        total: 3,
        done: 1,
        pending: 2,
        completionRate: 0.33
      });
    });
  });
});
