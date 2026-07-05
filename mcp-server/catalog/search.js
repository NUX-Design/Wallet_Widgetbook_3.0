import { normalize } from "./shared.js";

export function buildSearchIndex(widget, docMetadata) {
  return {
    name: normalize(widget.name),
    category: normalize(widget.category),
    tags: widget.tags.map(normalize),
    headings: docMetadata.headings.map(normalize),
    props: widget.props.map((prop) => normalize(prop.name)),
    dependencies: widget.dependencies.map(normalize),
    docs: normalize(docMetadata.searchText),
    source: normalize(widget.sourceText),
  };
}

export function scoreWidget(widget, query, tokens) {
  let score = 0;
  const { name, category, tags, headings, props, dependencies, docs, source } = widget.searchIndex;

  if (name === query) score += 260;
  if (name.startsWith(query)) score += 180;
  if (name.includes(query)) score += 140;
  if (category === query) score += 80;
  if (category.includes(query)) score += 40;
  if (tags.some((tag) => tag === query)) score += 90;
  if (tags.some((tag) => tag.includes(query))) score += 36;
  if (headings.some((heading) => heading === query)) score += 70;
  if (props.some((prop) => prop === query)) score += 65;
  if (dependencies.some((dependency) => dependency === query)) score += 45;

  for (const token of tokens) {
    if (!token) continue;
    if (name.includes(token)) score += 30;
    if (tags.some((tag) => tag.includes(token))) score += 18;
    if (category.includes(token)) score += 12;
    if (headings.some((heading) => heading.includes(token))) score += 12;
    if (props.some((prop) => prop.includes(token))) score += 10;
    if (dependencies.some((dependency) => dependency.includes(token))) score += 8;
    if (docs.includes(token)) score += 6;
    if (source.includes(token)) score += 3;
  }

  return score;
}
