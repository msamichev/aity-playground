import { describe, expect, it } from 'vitest';
import { paginate } from '../src/pagination.js';

describe('paginate', () => {
  const full = Array.from({ length: 25 }, (_, i) => i + 1); // [1..25]

  it('обычная страница в середине', () => {
    const r = paginate(full, 2, 10);
    expect(r.items).toEqual([11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
    expect(r.page).toBe(2);
    expect(r.pageSize).toBe(10);
    expect(r.totalItems).toBe(25);
    expect(r.totalPages).toBe(3);
  });

  it('последняя неполная страница', () => {
    const r = paginate(full, 3, 10);
    expect(r.items).toEqual([21, 22, 23, 24, 25]);
    expect(r.page).toBe(3);
    expect(r.pageSize).toBe(10);
    expect(r.totalItems).toBe(25);
    expect(r.totalPages).toBe(3);
  });

  it('page 0 или отрицательный → клампится к 1', () => {
    const r0 = paginate(full, 0, 10);
    expect(r0.page).toBe(1);
    expect(r0.items).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    const rNeg = paginate(full, -5, 10);
    expect(rNeg.page).toBe(1);
    expect(rNeg.items).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  it('pageSize > 100 → клампится к 100', () => {
    const r = paginate(full, 1, 200);
    expect(r.pageSize).toBe(100);
    expect(r.items).toEqual(full); // 25 элементов помещаются в первую страницу
  });

  it('pageSize < 1 → клампится к 1', () => {
    const r = paginate(full, 2, 0);
    expect(r.pageSize).toBe(1);
    expect(r.items).toEqual([2]);
    expect(r.totalPages).toBe(25);
  });

  it('пустой массив: totalPages = 1, items пуст', () => {
    const r = paginate([], 1, 10);
    expect(r.items).toEqual([]);
    expect(r.totalItems).toBe(0);
    expect(r.totalPages).toBe(1);
    expect(r.page).toBe(1);
  });
});
