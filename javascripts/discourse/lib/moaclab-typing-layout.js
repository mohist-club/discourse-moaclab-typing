export function visibleRows(height, rowHeight, gap) {
  return Math.max(1, Math.min(6, Math.floor((height + gap) / (rowHeight + gap))));
}

export function wordWindow(lengths, cursor, columns, rows) {
  let offset = 0;
  let active = lengths.length - 1;
  for (let i = 0; i < lengths.length; i++) {
    if (cursor <= offset + lengths[i]) {
      active = i;
      break;
    }
    offset += lengths[i] + 1;
  }
  const count = columns * rows;
  const start = Math.floor(Math.max(0, active) / count) * count;
  return { start, end: Math.min(lengths.length, start + count) };
}

export function speedMilestone(wpm, elapsed) {
  return elapsed < 3000 ? 0 : Math.min(180, Math.floor(wpm / 30) * 30);
}

export function tokenIndexAtOffset(lengths, offset) {
  let cursor = 0;
  for (let index = 0; index < lengths.length; index++) {
    const end = cursor + lengths[index];
    if (offset <= end) return index;
    cursor = end + 1;
  }
  return Math.max(0, lengths.length - 1);
}

export function completedRowAt(lengths, cursor, columns) {
  let offset = 0;
  for (let start = 0; start < lengths.length; start += columns) {
    const end = Math.min(lengths.length, start + columns);
    let rowEnd = offset;
    for (let index = start; index < end; index++) {
      rowEnd += lengths[index];
      if (index < lengths.length - 1) rowEnd += 1;
    }
    if (cursor === rowEnd - (end < lengths.length ? 1 : 0)) {
      return { start, end, key: `${columns}:${start}:${end}` };
    }
    offset = rowEnd;
  }
  return null;
}
