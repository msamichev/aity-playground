/**
 * Приводит заголовок к Title Case: каждое слово начинается с заглавной буквы.
 *
 * Алгоритм:
 *  1. Первый символ каждого слова (после пробела или начала строки) приводится к верхнему регистру.
 *  2. Остальные символы не меняются.
 *  3. Пробелы между словами сохраняются.
 *
 * Примеры:
 *   capitalizeTitle("buy milk")         → "Buy Milk"
 *   capitalizeTitle("  hello   world ") → "  Hello   World "
 *   capitalizeTitle("")                 → ""
 */
export function capitalizeTitle(title: string): string {
  let result = '';
  let startOfWord = true;

  for (let i = 0; i < title.length; i++) {
    const char = title[i];
    if (char === ' ') {
      result += ' ';
      startOfWord = true;
    } else if (startOfWord) {
      result += char.toUpperCase();
      startOfWord = false;
    } else {
      result += char;
    }
  }

  return result;
}
