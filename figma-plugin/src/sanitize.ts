// Text-sanitization + JSON-serialization helpers.
//
// Intentionally has NO Figma dependencies so it can be unit-tested in isolation
// (see scripts/test-sanitize.mjs).
//
// Two distinct concerns, two functions:
//   - safeStringify: LOSSLESS transport safety. Escapes the only two code points
//     that are legal inside a JSON string but are treated as line terminators by
//     editors/JS parsers (U+2028 / U+2029). Parsing restores the exact value, so
//     this is safe to apply to EVERY field — including identity/match strings that
//     must stay byte-identical to the live Figma node.
//   - sanitizeText: DESTRUCTIVE normalization of designer-entered FREE TEXT only
//     (e.g. _meta.optionalContext). Never use it on identity/match strings
//     (layer names, variant names, raw property keys): mutating those would desync
//     the extract from Figma and break the create-* skills' name-based matching.

// U+2028 LINE SEPARATOR and U+2029 PARAGRAPH SEPARATOR are valid in JSON strings
// but trip "unusual line terminator" warnings and historically broke JS/JSONP.
// Escaping them is lossless: JSON.parse turns the escape back into the code point.
export function safeStringify(value: unknown): string {
  return JSON.stringify(value).replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
}

// Normalize free-form, human-entered text to clean plain text:
//   1. All line/paragraph separators (CRLF, CR, LS, PS, NEL) -> "\n".
//   2. Strip zero-width, BOM, and bidirectional format controls (Unicode "Cf"
//      plus the zero-width space block).
//   3. Strip remaining C0/C1 control characters (Unicode "Cc"), keeping only the
//      whitelisted whitespace "\t" and "\n".
// Printable content (letters, accents, CJK, emoji, punctuation) is left untouched.
export function sanitizeText<T extends string | null | undefined>(input: T): T {
  if (input == null) return input;
  let s = String(input);
  // 1. Unify line breaks.
  s = s.replace(/\r\n?/g, '\n');
  s = s.replace(/[\u2028\u2029\u0085]/g, '\n');
  // 2. Zero-width / BOM / bidi format controls.
  s = s.replace(/[\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u206F\uFEFF]/g, '');
  // 3. Remaining control chars (C0 except \t \n; DEL + C1). CR already handled above.
  s = s.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/g, '');
  return s as T;
}
