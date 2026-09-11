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
