export class ToolError extends Error {
  constructor(code, message, options = {}) {
    super(message);
    this.name = "ToolError";
    this.code = code;
    this.hint = options.hint ?? null;
    this.details = options.details ?? null;
  }
}

export function ok(data) {
  return {
    content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    structuredContent: data,
  };
}

export function fail(errorLike) {
  const error =
    errorLike instanceof ToolError
      ? errorLike
      : new ToolError("INTERNAL_ERROR", errorLike?.message ?? String(errorLike));

  const payload = {
    ok: false,
    error: {
      code: error.code,
      message: error.message,
      hint: error.hint,
      details: error.details,
    },
  };

  return {
    content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
    isError: true,
  };
}

export function ensureNonEmptyString(value, fieldName, hint) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new ToolError("INVALID_ARGUMENT", `Field "${fieldName}" must be a non-empty string.`, {
      hint,
      details: { field: fieldName },
    });
  }

  return value.trim();
}

export function ensureEnum(value, fieldName, allowedValues) {
  const normalized = ensureNonEmptyString(
    value,
    fieldName,
    `Allowed values: ${allowedValues.join(", ")}`,
  );

  if (!allowedValues.includes(normalized)) {
    throw new ToolError("INVALID_ARGUMENT", `Field "${fieldName}" must be one of: ${allowedValues.join(", ")}.`, {
      hint: `Use one of the documented values for "${fieldName}".`,
      details: { field: fieldName, allowedValues },
    });
  }

  return normalized;
}

export function parsePagination(args, options = {}) {
  const {
    defaultLimit = 50,
    maxLimit = 200,
    defaultOffset = 0,
  } = options;

  const limit = parseWholeNumber(args.limit, "limit", {
    minimum: 1,
    maximum: maxLimit,
    fallback: defaultLimit,
  });
  const offset = parseWholeNumber(args.offset, "offset", {
    minimum: 0,
    fallback: defaultOffset,
  });

  return { limit, offset };
}

export function buildPaginatedWidgetsPayload(context, widgets, total, limit, offset) {
  return {
    ...context,
    total,
    count: widgets.length,
    limit,
    offset,
    hasMore: offset + widgets.length < total,
    widgets,
  };
}

function parseWholeNumber(value, fieldName, options) {
  const { minimum, maximum, fallback } = options;
  if (value === undefined || value === null) return fallback;

  const numericValue =
    typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;

  if (!Number.isInteger(numericValue)) {
    throw new ToolError("INVALID_ARGUMENT", `Field "${fieldName}" must be an integer.`, {
      hint: `Pass "${fieldName}" as an integer value.`,
      details: { field: fieldName, received: value },
    });
  }

  if (numericValue < minimum || (maximum !== undefined && numericValue > maximum)) {
    const rangeText =
      maximum === undefined ? `${minimum}+` : `${minimum} to ${maximum}`;
    throw new ToolError(
      "INVALID_ARGUMENT",
      `Field "${fieldName}" must be in range ${rangeText}.`,
      {
        hint: `Adjust "${fieldName}" to stay within the supported range.`,
        details: { field: fieldName, received: numericValue, minimum, maximum },
      },
    );
  }

  return numericValue;
}
