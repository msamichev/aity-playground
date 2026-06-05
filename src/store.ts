import { randomUUID } from 'node:crypto';

export interface Todo {
  id: string;
  title: string;
  done: boolean;
  createdAt: string;
}

/**
 * In-memory хранилище задач. Никакой персистентности — рестарт = чистое состояние.
 * Инкапсулировано (не глобальный синглтон), чтобы тесты могли создавать свежий стор.
 */
export class TodoStore {
  private readonly todos = new Map<string, Todo>();

  create(title: string): Todo {
    const todo: Todo = {
      id: randomUUID(),
      title,
      done: false,
      createdAt: new Date().toISOString(),
    };
    this.todos.set(todo.id, todo);
    return todo;
  }

  list(): Todo[] {
    return [...this.todos.values()];
  }

  get(id: string): Todo | undefined {
    return this.todos.get(id);
  }

  setDone(id: string, done: boolean): Todo | undefined {
    const todo = this.todos.get(id);
    if (!todo) return undefined;
    todo.done = done;
    return todo;
  }

  toggle(id: string): Todo | undefined {
    const todo = this.todos.get(id);
    if (!todo) return undefined;
    todo.done = !todo.done;
    return todo;
  }

  delete(id: string): boolean {
    return this.todos.delete(id);
  }

  clear(): void {
    this.todos.clear();
  }
}
