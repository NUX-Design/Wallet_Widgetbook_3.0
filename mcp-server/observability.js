const LOG_LEVELS = {
  silent: -1,
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
};

function normalizeLevel(level) {
  if (typeof level !== "string") return "silent";
  const normalized = level.trim().toLowerCase();
  return Object.hasOwn(LOG_LEVELS, normalized) ? normalized : "silent";
}

function serializeValue(value) {
  if (value === undefined) return undefined;
  if (value === null) return null;
  if (value instanceof Error) {
    return {
      name: value.name,
      message: value.message,
    };
  }
  if (Array.isArray(value)) {
    return value.map((entry) => serializeValue(entry));
  }
  if (typeof value === "object") {
    const result = {};
    for (const [key, nestedValue] of Object.entries(value)) {
      const serialized = serializeValue(nestedValue);
      if (serialized !== undefined) result[key] = serialized;
    }
    return result;
  }
  if (typeof value === "function") return undefined;
  return value;
}

function defaultSink(entry) {
  console.error(JSON.stringify(entry));
}

export function createStructuredLogger({
  level = process.env.MCP_LOG_LEVEL ?? "silent",
  sink = defaultSink,
  baseContext = {},
} = {}) {
  const normalizedLevel = normalizeLevel(level);
  const threshold = LOG_LEVELS[normalizedLevel];

  function emit(entryLevel, event, fields = {}) {
    if (LOG_LEVELS[entryLevel] > threshold) return;

    sink({
      ts: new Date().toISOString(),
      level: entryLevel,
      event,
      ...serializeValue(baseContext),
      ...serializeValue(fields),
    });
  }

  return {
    level: normalizedLevel,
    debug(event, fields) {
      emit("debug", event, fields);
    },
    info(event, fields) {
      emit("info", event, fields);
    },
    warn(event, fields) {
      emit("warn", event, fields);
    },
    error(event, fields) {
      emit("error", event, fields);
    },
  };
}

export function createInMemoryLogger() {
  const entries = [];
  const logger = createStructuredLogger({
    level: "debug",
    sink(entry) {
      entries.push(entry);
    },
  });

  return {
    logger,
    entries,
  };
}

export function measureDurationMs(startTime) {
  return Number((performance.now() - startTime).toFixed(3));
}
