import { beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';
import { createApp } from '../src/app.js';
import { TodoStore } from '../src/store.js';

describe('GET /todos/search', () => {
  let app: Express;
  let store: TodoStore;

  beforeEach(() => {
    store = new TodoStore();
    app = createApp(store);
  });

  it('находит задачи по подстроке регистронезависимо', async () => {
    store.create('Buy milk');
    store.create('Milk shake');
    store.create('Cook dinner');

    const res = await request(app).get('/todos/search?q=milk');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);
    expect(res.body).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ title: 'Buy milk', done: false }),
        expect.objectContaining({ title: 'Milk shake', done: false }),
      ]),
    );
    // поля ответа — только id, title, done
    for (const item of res.body) {
      expect(Object.keys(item).sort()).toEqual(['done', 'id', 'title']);
    }
  });

  it('находит задачу даже если регистр запроса отличается', async () => {
    store.create('UPPERCASE');

    const res = await request(app).get('/todos/search?q=upper');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({ title: 'UPPERCASE' });
  });

  it('возвращает пустой массив если ничего не найдено', async () => {
    store.create('Buy milk');

    const res = await request(app).get('/todos/search?q=xyz');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('пустой q возвращает 400', async () => {
    const res = await request(app).get('/todos/search?q=');
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('отсутствующий q возвращает 400', async () => {
    const res = await request(app).get('/todos/search');
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('q из одних пробелов возвращает 400', async () => {
    const res = await request(app).get('/todos/search?q=   ');
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('/todos/search не перехватывается маршрутом /todos/:id', async () => {
    // если бы /todos/search матчился как :id, то пришёл бы 404
    // (нет задачи с id='search'), а не 400 за отсутствие q
    // но здесь мы проверяем что /todos/search вообще доступен —
    // с пустым q он возвращает 400, а не 404
    const resEmpty = await request(app).get('/todos/search?q=');
    expect(resEmpty.status).toBe(400);

    // с валидным q возвращает 200, не 404
    store.create('find me');
    const resOk = await request(app).get('/todos/search?q=find');
    expect(resOk.status).toBe(200);
    expect(resOk.body).toHaveLength(1);
  });
});
