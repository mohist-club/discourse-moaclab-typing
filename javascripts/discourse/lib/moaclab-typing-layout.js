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

// Overdrive switches on near a full flow meter and holds until flow clearly
// drops, so it does not flicker on the threshold.
export function overdriveActive(power, active, on = 88, off = 70) {
  return active ? power >= off : power >= on;
}

// Rolling rows: the row holding the cursor sits at the top of the visible
// area with `rows` unfinished rows in view. One finished row is kept rendered
// above (hidden) so the area can slide up instead of swapping pages.
export function rollingWindow(lengths, cursor, columns, rows) {
  let offset = 0;
  let active = Math.max(0, lengths.length - 1);
  for (let i = 0; i < lengths.length; i++) {
    if (cursor <= offset + lengths[i]) {
      active = i;
      break;
    }
    offset += lengths[i] + 1;
  }
  const currentRow = Math.floor(active / columns);
  const firstRow = Math.max(0, currentRow - 1);
  const needed = (currentRow + rows) * columns;
  return {
    currentRow,
    firstRow,
    hiddenRows: currentRow - firstRow,
    start: firstRow * columns,
    end: Math.min(lengths.length, needed),
    needed,
  };
}
