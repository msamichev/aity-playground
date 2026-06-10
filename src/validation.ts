export type ValidateTitleResult =
  | { ok: true; value: string }
  | { ok: false; error: string };

/**
 * Валидирует заголовок задачи: не пустой, не длиннее 200 символов.
 * Обрезает пробелы по краям. Не бросает исключений.
 */
export function validateTitle(input: unknown): ValidateTitleResult {
  if (typeof input !== 'string') {
    return { ok: false, error: 'title is required' };
  }

  const trimmed = input.trim();

  if (trimmed === '') {
    return { ok: false, error: 'title is required' };
  }

  if (trimmed.length > 200) {
    return { ok: false, error: 'title too long' };
  }

  return { ok: true, value: trimmed };
}
