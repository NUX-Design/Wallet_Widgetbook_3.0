// Figma file-link parsing + canonical component-URL building.
//
// No Figma dependencies so it can be unit-tested in isolation
// (see scripts/test-figma-url.mjs).
//
// Why this exists: public Community plugins cannot read `figma.fileKey` (it is
// only exposed to private plugins via `enablePrivatePluginApi`). So the user must
// supply the file's URL, and we parse the key out of it.

// Parse the file key from a pasted Figma URL. Handles the URL shapes Figma uses:
//   https://www.figma.com/design/:fileKey/:name?node-id=...
//   https://www.figma.com/file/:fileKey/:name              (legacy)
//   https://www.figma.com/board|slides|proto/:fileKey/...
//   https://www.figma.com/design/:fileKey/branch/:branchKey/:name
// For branch URLs the branch key is what addresses the live document, so it wins.
// A bare key pasted on its own is also accepted. Returns null when no key is found.
export function parseFigmaFileKey(input: string | null | undefined): string | null {
  if (input == null) return null;
  const s = String(input).trim();
  if (!s) return null;
  const m = s.match(
    /figma\.com\/(?:design|file|board|slides|proto)\/([A-Za-z0-9]+)(?:\/branch\/([A-Za-z0-9]+))?/i
  );
  if (m) return m[2] || m[1];
  // Bare key fallback (Figma keys are alphanumeric, ~22 chars).
  if (/^[A-Za-z0-9]{16,128}$/.test(s)) return s;
  return null;
}

// Build a canonical component deep link from a file key, the document name, and a
// node id. Node ids use ':' in the API but '-' in URLs.
export function buildFigmaUrl(fileKey: string, fileName: string, nodeId: string): string {
  const slug =
    String(fileName || '')
      .trim()
      .replace(/\s+/g, '-')
      .replace(/[^A-Za-z0-9._-]/g, '') || 'file';
  const node = String(nodeId).replace(/:/g, '-');
  return `https://www.figma.com/design/${fileKey}/${slug}?node-id=${node}`;
}
