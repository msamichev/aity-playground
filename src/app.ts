import express, { type Express, type Request, type Response } from 'express';
import { TodoStore, type Todo } from './store.js';

/**
 * Собирает Express-приложение поверх переданного хранилища.
 * Принимает store параметром — так тесты прогоняют запросы против свежего стора.
 */
export function createApp(store: TodoStore = new TodoStore()): Express {
  const app = express();
  app.use(express.json());

  app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({ status: 'ok' });
  });

  app.get('/todos', (_req: Request, res: Response) => {
    res.status(200).json(store.list());
  });

  app.post('/todos', (req: Request, res: Response) => {
    const { title } = (req.body ?? {}) as { title?: unknown };
    if (typeof title !== 'string' || title.trim() === '') {
      res.status(400).json({ error: 'title is required and must be a non-empty string' });
      return;
    }
    res.status(201).json(store.create(title.trim()));
  });

  app.get('/todos/:id', (req: Request, res: Response) => {
    const todo = store.get(String(req.params.id));
    if (!todo) {
      res.status(404).json({ error: 'todo not found' });
      return;
    }
    res.status(200).json(todo);
  });

  app.patch('/todos/:id', (req: Request, res: Response) => {
    const id = String(req.params.id);
    const { done } = (req.body ?? {}) as { done?: unknown };
    let todo: Todo | undefined;
    if (done === undefined) {
      todo = store.toggle(id);
    } else if (typeof done === 'boolean') {
      todo = store.setDone(id, done);
    } else {
      res.status(400).json({ error: 'done must be a boolean' });
      return;
    }
    if (!todo) {
      res.status(404).json({ error: 'todo not found' });
      return;
    }
    res.status(200).json(todo);
  });

  app.delete('/todos/:id', (req: Request, res: Response) => {
    if (!store.delete(String(req.params.id))) {
      res.status(404).json({ error: 'todo not found' });
      return;
    }
    res.status(204).send();
  });

  return app;
}
