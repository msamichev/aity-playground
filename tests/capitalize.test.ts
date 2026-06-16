import { describe, it, expect } from 'vitest';
import { capitalizeTitle } from '../src/capitalize.js';

describe('capitalizeTitle', () => {
  it('переводит одно слово в Title Case', () => {
    expect(capitalizeTitle('hello')).toBe('Hello');
  });

  it('переводит несколько слов в Title Case', () => {
    expect(capitalizeTitle('buy milk')).toBe('Buy Milk');
  });

  it('не меняет уже заглавные буквы', () => {
    expect(capitalizeTitle('Buy Milk')).toBe('Buy Milk');
  });

  it('возвращает пустую строку для пустого входа', () => {
    expect(capitalizeTitle('')).toBe('');
  });

  it('сохраняет пробелы между словами', () => {
    expect(capitalizeTitle('  hello   world ')).toBe('  Hello   World ');
  });

  it('не меняет регистр остальных символов слова', () => {
    expect(capitalizeTitle('bUy MiLK')).toBe('BUy MiLK');
  });

  it('обрабатывает строку из одного символа', () => {
    expect(capitalizeTitle('a')).toBe('A');
  });

  it('не меняет строку из одних пробелов', () => {
    expect(capitalizeTitle('     ')).toBe('     ');
  });

  it('обрабатывает строку с цифрами и спецсимволами', () => {
    expect(capitalizeTitle('task 42 complete!')).toBe('Task 42 Complete!');
  });

  it('корректно обрабатывает строку без пробелов (одно длинное слово)', () => {
    expect(capitalizeTitle('alreadyOneWord')).toBe('AlreadyOneWord');
  });
});
