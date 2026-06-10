import { beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';
import { createApp } from '../src/app.js';
import { TodoStore } from '../src/store.js';

describe('todo API', () => {
  let app: Express;

  beforeEach(() => {
    app = createApp(new TodoStore());
  });

  it('GET /health -> 200 ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('POST /todos создаёт задачу', async () => {
    const res = await request(app).post('/todos').send({ title: 'write tests' });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ title: 'write tests', done: false });
    expect(res.body.id).toBeTypeOf('string');
  });

  it('POST /todos отклоняет пустой title', async () => {
    const res = await request(app).post('/todos').send({ title: '   ' });
    expect(res.status).toBe(400);
  });

  it('POST /todos отклоняет отсутствующий title', async () => {
    const res = await request(app).post('/todos').send({});
    expect(res.status).toBe(400);
  });

  it('GET /todos возвращает список', async () => {
    await request(app).post('/todos').send({ title: 'a' });
    const res = await request(app).get('/todos');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
  });

  it('GET /todos/:id возвращает одну или 404', async () => {
    const created = await request(app).post('/todos').send({ title: 'a' });
    const id = created.body.id as string;
    const ok = await request(app).get(`/todos/${id}`);
    expect(ok.status).toBe(200);
    expect(ok.body.id).toBe(id);
    const missing = await request(app).get('/todos/nope');
    expect(missing.status).toBe(404);
  });

  it('PATCH /todos/:id переключает done', async () => {
    const created = await request(app).post('/todos').send({ title: 'a' });
    const res = await request(app).patch(`/todos/${created.body.id}`).send({});
    expect(res.status).toBe(200);
    expect(res.body.done).toBe(true);
  });

  it('PATCH /todos/:id выставляет done явно', async () => {
    const created = await request(app).post('/todos').send({ title: 'a' });
    const res = await request(app).patch(`/todos/${created.body.id}`).send({ done: true });
    expect(res.body.done).toBe(true);
  });

  it('PATCH /todos/:id отклоняет не-boolean done', async () => {
    const created = await request(app).post('/todos').send({ title: 'a' });
    const res = await request(app).patch(`/todos/${created.body.id}`).send({ done: 'yes' });
    expect(res.status).toBe(400);
  });

  it('PATCH /todos/:id -> 404 для отсутствующей', async () => {
    const res = await request(app).patch('/todos/nope').send({});
    expect(res.status).toBe(404);
  });

  describe('GET /todos/count', () => {
    it('пустой стор возвращает нули', async () => {
      const res = await request(app).get('/todos/count');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ total: 0, done: 0, pending: 0 });
    });

    it('считает pending и done', async () => {
      await request(app).post('/todos').send({ title: 'a' });
      await request(app).post('/todos').send({ title: 'b' });
      await request(app).post('/todos').send({ title: 'c' });
      // помечаем одну выполненной
      const list = await request(app).get('/todos');
      const firstId = (list.body as { id: string }[])[0].id;
      await request(app).patch(`/todos/${firstId}`).send({});

      const res = await request(app).get('/todos/count');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ total: 3, done: 1, pending: 2 });
    });

    it('GET /todos/count не перехватывается :id-роутом', async () => {
      // если бы /todos/count матчился как :id, вернулся бы 404 (нет задачи с id='count')
      const res = await request(app).get('/todos/count');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('total');
      expect(res.body).toHaveProperty('done');
      expect(res.body).toHaveProperty('pending');
    });
  });

  it('DELETE /todos/:id удаляет или 404', async () => {
    const created = await request(app).post('/todos').send({ title: 'a' });
    const id = created.body.id as string;
    expect((await request(app).delete(`/todos/${id}`)).status).toBe(204);
    expect((await request(app).delete(`/todos/${id}`)).status).toBe(404);
  });
});
