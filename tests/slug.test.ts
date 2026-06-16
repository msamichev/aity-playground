import { describe, it, expect } from 'vitest';
import { slugify } from '../src/slug.js';

describe('slugify', () => {
  it('приводит к нижнему регистру', () => {
    expect(slugify('Buy Milk')).toBe('buy-milk');
  });

  it('убирает ведущие и замыкающие пробелы', () => {
    expect(slugify('  Hello, World  ')).toBe('hello-world');
  });

  it('заменяет пунктуацию на дефис (один символ)', () => {
    expect(slugify('Buy Milk!')).toBe('buy-milk');
  });

  it('схлопывает множественные не-буквенно-цифровые символы в один дефис', () => {
    expect(slugify('Hello,,,World')).toBe('hello-world');
  });

  it('обрабатывает смесь пробелов и знаков пунктуации', () => {
    expect(slugify('Hello,  World!')).toBe('hello-world');
  });

  it('убирает ведущие дефисы после преобразования', () => {
    expect(slugify('!!Buy Milk')).toBe('buy-milk');
  });

  it('убирает замыкающие дефисы после преобразования', () => {
    expect(slugify('Buy Milk!!!')).toBe('buy-milk');
  });

  it('возвращает пустую строку для пустого входа', () => {
    expect(slugify('')).toBe('');
  });

  it('возвращает пустую строку для строки из одних пробелов', () => {
    expect(slugify('     ')).toBe('');
  });

  it('возвращает пустую строку для строки из одних спецсимволов', () => {
    expect(slugify('!@#$%^&*()')).toBe('');
  });

  it('возвращает пустую строку для строки из дефисов и пробелов', () => {
    expect(slugify(' - - - ')).toBe('');
  });

  it('сохраняет цифры', () => {
    expect(slugify('Task 42 Complete')).toBe('task-42-complete');
  });

  it('обрабатывает строку из одних букв и цифр (без изменений кроме регистра)', () => {
    expect(slugify('ABC123')).toBe('abc123');
  });

  it('корректно обрабатывает строку с подчёркиваниями', () => {
    expect(slugify('buy_milk_today')).toBe('buy-milk-today');
  });

  it('корректно обрабатывает строку со смешанными разделителями', () => {
    expect(slugify('Buy\tMilk\nToday')).toBe('buy-milk-today');
  });

  it('не добавляет дефисов там, где их нет — обычный заголовок', () => {
    expect(slugify('Buy milk')).toBe('buy-milk');
  });
});
