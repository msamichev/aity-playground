import type { Todo } from './store.js';

export function summarize(todos: Todo[]): { total: number; done: number; pending: number; completionRate: number } {
  const total = todos.length;
  const done = todos.filter(todo => todo.done).length;
  const pending = total - done;
  const completionRate = total > 0 ? Number((done / total).toFixed(2)) : 0;

  return {
    total,
    done,
    pending,
    completionRate
  };
}
