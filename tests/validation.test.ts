import { describe, expect, it } from 'vitest';
import { validateTitle } from '../src/validation.js';

describe('validateTitle', () => {
  it('возвращает ошибку для числа', () => {
    const result = validateTitle(42);
    expect(result).toEqual({ ok: false, error: 'title is required' });
  });

  it('возвращает ошибку для undefined', () => {
    const result = validateTitle(undefined);
    expect(result).toEqual({ ok: false, error: 'title is required' });
  });

  it('возвращает ошибку для пустой строки', () => {
    const result = validateTitle('');
    expect(result).toEqual({ ok: false, error: 'title is required' });
  });

  it('возвращает ошибку для строки из одних пробелов', () => {
    const result = validateTitle('   ');
    expect(result).toEqual({ ok: false, error: 'title is required' });
  });

  it('принимает строку ровно из 200 символов', () => {
    const title = 'a'.repeat(200);
    const result = validateTitle(title);
    expect(result).toEqual({ ok: true, value: title });
  });

  it('возвращает ошибку для строки длиннее 200 символов', () => {
    const title = 'a'.repeat(201);
    const result = validateTitle(title);
    expect(result).toEqual({ ok: false, error: 'title too long' });
  });

  it('обрезает пробелы по краям и возвращает валидное значение', () => {
    const result = validateTitle('  hello world  ');
    expect(result).toEqual({ ok: true, value: 'hello world' });
  });
});
