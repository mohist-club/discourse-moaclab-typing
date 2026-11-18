import { apiInitializer } from "discourse/lib/api";
import HSK_WORDS from "../lib/moaclab-typing-words";
import { completedRowAt, overdriveActive, speedMilestone, tokenIndexAtOffset, visibleRows, wordWindow } from "../lib/moaclab-typing-layout";

export default apiInitializer((api) => {
  const NS = "moaclab-typing";
  const I18N_NS = "moaclab_typing";
  const modalId = `${NS}-modal`;
  const themeSettings = typeof settings !== "undefined" ? settings : {};
  const setting = (name, fallback) => themeSettings[name] ?? fallback;
  const t = (key, fallback) => {
    try {
      return I18n.t(`${I18N_NS}.${key}`, { defaultValue: fallback });
    } catch {
      return fallback;
    }
  };
  const reducedMotion = () => Boolean(window.matchMedia?.("(prefers-reduced-motion: reduce)").matches);
  const comboMilestones = [10, 25, 50, 100, 150, 200, 300, 400, 500];
  const escape = (value) => String(value || "").replace(/[&<>"']/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[ch]));
  const iconPaths = {
    restart: '<path d="M20 11a8 8 0 1 1-2.34-5.66L20 8M20 3v5h-5"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    shuffle: '<path d="M3 6h3c4 0 4 12 8 12h7M18 15l3 3-3 3M3 18h3c1.5 0 2.5-1.4 3.5-3M14.5 9C15.5 7.4 16.5 6 18 6h3M18 3l3 3-3 3"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.4 2.5 3.6 5.5 3.6 9S14.4 18.5 12 21M12 3C9.6 5.5 8.4 8.5 8.4 12S9.6 18.5 12 21"/>',
    bolt: '<path d="m13 2-8 12h7l-1 8 8-12h-7l1-8Z"/>',
    spark: '<path d="m12 3 1.2 3.8L17 8l-3.8 1.2L12 13l-1.2-3.8L7 8l3.8-1.2L12 3ZM18.5 14l.7 2.3 2.3.7-2.3.7-.7 2.3-.7-2.3-2.3-.7 2.3-.7.7-2.3ZM5 14l.8 2.2L8 17l-2.2.8L5 20l-.8-2.2L2 17l2.2-.8L5 14Z"/>',
    sound: '<path d="M5 10v4h3l4 3V7L8 10H5ZM16 9.5a4 4 0 0 1 0 5M18.5 7a7 7 0 0 1 0 10"/>',
    bump: '<path d="M4 15c3-8 5 4 8-4s5 4 8-4"/>',
    wave: '<path d="M3 12h3l2-6 4 12 3-9 2 3h4"/>',
    space: '<path d="M5 8v8h14V8M8 13h8"/>',
  };
  const icon = (name) => `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${iconPaths[name] || iconPaths.spark}</svg>`;
  const craftPairs = [
    ["机械", "jixie"], ["键盘", "jianpan"], ["轴体", "zhouti"],
    ["键帽", "jianmao"], ["手感", "shougan"], ["声音", "shengyin"],
    ["调音", "tiaoyin"], ["配列", "peilie"], ["固件", "gujian"],
    ["消音", "xiaoyin"], ["结构", "jiegou"], ["敲击", "qiaoji"],
    ["回弹", "huitan"], ["触发", "chufa"], ["定位板", "dingweiban"],
    ["电路板", "dianluban"], ["套件", "taojian"], ["卫星轴", "weixingzhou"],
  ];
  const pinyin = Object.fromEntries([...HSK_WORDS, ...craftPairs].map(([word, pronunciation]) => [word, pronunciation]));
  const allWords = HSK_WORDS.map(([word]) => word);
  const chineseGroups = {
    random: { label: "全部", words: allWords },
    basic: { label: "基础", words: HSK_WORDS.filter(([, , level]) => level <= 2).map(([word]) => word) },
    life: { label: "常用", words: HSK_WORDS.filter(([, , level]) => level <= 5).map(([word]) => word) },
    craft: { label: "键盘", words: craftPairs.map(([word]) => word) },
  };
  const englishWords = "thock switch keycap gasket firmware plate foam spacebar layout build quiet deep poppy type fast clean every press is tuned by hand".split(" ");
  const durations = String(setting("durations", "15|30|60|90")).split("|").map(Number).filter((n) => n > 0);
  const defaultDuration = Number(setting("default_duration", 30)) || durations[0] || 30;
  const rowCount = 6;
  const getColumnCount = () => {
    const width = document.querySelector(`.${NS}-modal__text`)?.clientWidth || window.innerWidth;
    return width >= 960 ? 5 : width >= 720 ? 4 : width >= 520 ? 3 : 2;
  };
  const effectStorageKey = `${NS}:effects`;
  const flowBestKey = `${NS}:flow-best`;
  const readStorage = (key, fallback) => {
    try { return localStorage.getItem(key) ?? fallback; } catch { return fallback; }
  };
  const writeStorage = (key, value) => {
    try { localStorage.setItem(key, value); } catch { /* storage may be unavailable */ }
  };
  const loadEffects = () => {
    try {
      return { pinyinBump: true, awesomenessBoost: true, spaceFeedback: true, ...JSON.parse(readStorage(effectStorageKey, "{}")) };
    } catch {
      return { pinyinBump: true, awesomenessBoost: true, spaceFeedback: true };
    }
  };
  const effectIds = ["pinyinBump", "awesomenessBoost", "spaceFeedback"];
  const enabledEffectCount = () => effectIds.filter((id) => Boolean(state.effects[id])).length;
  const state = { open: false, duration: defaultDuration, rows: rowCount, columns: getColumnCount(), group: "random", language: "zh", hard: false, tokens: [], target: "", display: "", pinyin: "", typed: "", running: false, finished: false, startedAt: 0, elapsed: 0, correct: 0, total: 0, muted: true, timer: null, audio: null, streak: 0, bestStreak: Number(readStorage(flowBestKey, "0")) || 0, flowPower: 0, lastInputAt: 0, cadence: 0, effects: loadEffects(), resizeFrame: null, mistakeTokens: new Set(), celebratedRows: new Set(), restartArmed: false, overdrive: false };
  let routeObserver = null;
  let reconcileFrame = null;
  let layoutObserver = null;
  let renderedTokens = null;
  let renderedWindow = "";
  let reachedSpeed = 0;

  const isTypingRoute = () => {
    const url = new URL(window.location.href);
    return url.pathname === "/typing";
  };

  if (setting("show_sidebar_link", false)) {
    api.addCommunitySectionLink((BaseCommunitySectionLink) => class MoaclabTypingSectionLink extends BaseCommunitySectionLink {
      get name() { return "moaclab-typing"; }
      get href() { return "/typing"; }
      get currentWhen() { return "moaclab-typing"; }
      get title() { return t("open", "Typing"); }
      get text() { return t("open", "Typing"); }
      get prefixValue() { return "keyboard"; }
    });
  }

  const randomText = () => {
    let pool = state.language === "en" ? englishWords : (chineseGroups[state.group] || chineseGroups.random).words.filter((word) => pinyin[word]);
    if (state.hard && state.language === "zh") pool = pool.filter((word) => pinyin[word].length >= 8);
    const visibleWordCount = rowCount * state.columns;
    const selected = Array.from({ length: visibleWordCount }, (_, i) => pool[(i * 7 + Math.floor(Math.random() * pool.length)) % pool.length]);
    const display = selected.join(" ");
    const pronunciation = state.language === "zh" ? selected.map((word) => pinyin[word]).join(" ") : "";
    return { tokens: selected, target: state.language === "zh" ? pronunciation : display, display, pinyin: pronunciation };
  };
  const bestKey = () => `${NS}:best:${state.duration}`;
  const best = () => Number(readStorage(bestKey(), "0")) || 0;
  const format = (n) => Math.max(0, Math.round(n));
  const wpm = () => {
    const minutes = Math.max(state.elapsed / 60000, 1 / 60);
    return format(state.correct / 5 / minutes);
  };
  const accuracy = () => state.total ? format((state.correct / state.total) * 100) : 100;
  const errorCount = () => Math.max(0, state.total - state.correct);

  function playClick() {
    if (state.muted) return;
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    if (!state.audio) state.audio = new AudioContext();
    const ctx = state.audio;
    if (ctx.state === "suspended") ctx.resume();
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = "sine";
    osc.frequency.setValueAtTime(180, now);
    osc.frequency.exponentialRampToValueAtTime(75, now + 0.06);
    gain.gain.setValueAtTime(0.001, now);
    gain.gain.exponentialRampToValueAtTime(0.14, now + 0.004);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
    osc.connect(gain).connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.1);
  }

  function renderText() {
    const root = document.getElementById(modalId);
    const el = root?.querySelector(`.${NS}-modal__text`);
    if (!el) return;
    root.style.setProperty("--typing-columns", String(state.columns));
    root.style.setProperty("--typing-rows", String(state.rows));
    const pronunciations = state.tokens.map((word) => state.language === "zh" ? (pinyin[word] || word) : word);
    const { start: first, end: last } = wordWindow(pronunciations.map((word) => word.length), state.typed.length, state.columns, state.rows);
    const windowKey = `${first}:${last}:${state.language}`;
    const rebuilt = renderedTokens !== state.tokens || renderedWindow !== windowKey;
    if (rebuilt) {
      let cursor = 0;
      el.innerHTML = state.tokens.map((word, wi) => {
        const py = pronunciations[wi];
        const start = cursor;
        cursor += py.length + 1;
        if (wi < first || wi >= last) return "";
        const chars = Array.from(py).map((ch, i) => `<span class="${NS}-modal__char" data-index="${start + i}">${escape(ch)}</span>`).join("");
        const lengthClass = py.length > 11 ? " is-long" : py.length > 8 ? " is-medium" : "";
        return `<span class="${NS}-modal__word${lengthClass}" data-token-index="${wi}" data-word-start="${start}" data-word-end="${start + py.length}" style="--typing-chars: ${py.length}"><span class="${NS}-modal__hanzi">${state.language === "zh" ? escape(word) : ""}</span><span class="${NS}-modal__pinyin">${chars}</span></span>`;
      }).join("");
      renderedTokens = state.tokens;
      renderedWindow = windowKey;
    }
    // Keep character nodes alive so one keystroke does not cancel the previous impact.
    el.querySelectorAll("[data-index]").forEach((char) => {
      const index = Number(char.dataset.index);
      const status = index < state.typed.length ? (state.typed[index] === state.target[index] ? "is-done" : "is-wrong") : index === state.typed.length ? "is-current" : "";
      char.className = `${NS}-modal__char ${status}`;
    });
    el.querySelectorAll(`.${NS}-modal__word`).forEach((word) => {
      word.classList.toggle("is-active", state.typed.length >= Number(word.dataset.wordStart) && state.typed.length <= Number(word.dataset.wordEnd));
      // A letter typed where the separating space belongs has no glyph of its own; mark it after the word.
      const spaceInput = state.typed[Number(word.dataset.wordEnd)];
      word.classList.toggle("has-space-error", spaceInput !== undefined && spaceInput !== " ");
    });
    root.querySelector("[data-space-key]").classList.toggle("is-current", state.target[state.typed.length] === " ");
    placeCursor(rebuilt);
  }

  // One block cursor glides between letters (and across rows) instead of
  // jumping; the current letter is drawn on top of it in the page colour.
  function placeCursor(instant = false) {
    const root = document.getElementById(modalId);
    const cursor = root?.querySelector("[data-cursor]");
    const stage = root?.querySelector(`.${NS}-modal__stage`);
    if (!cursor || !stage) return;
    const index = state.typed.length;
    let box = root.querySelector(`[data-index="${index}"]`)?.getBoundingClientRect();
    if (!box) {
      // Waiting for a space: sit just after the word that was finished.
      const previous = root.querySelector(`[data-index="${index - 1}"]`)?.getBoundingClientRect();
      if (!previous) {
        cursor.dataset.ready = "false";
        return;
      }
      const width = Math.max(4, previous.width * .45);
      box = { left: previous.right + 2, top: previous.top, width, height: previous.height };
    }
    const stageBox = stage.getBoundingClientRect();
    if (!instant && cursor.dataset.ready === "true") leaveCursorGhost(cursor, stage);
    cursor.classList.toggle("is-instant", instant || cursor.dataset.ready !== "true");
    cursor.style.setProperty("--cursor-x", `${box.left - stageBox.left}px`);
    cursor.style.setProperty("--cursor-y", `${box.top - stageBox.top}px`);
    cursor.style.setProperty("--cursor-w", `${box.width}px`);
    cursor.style.setProperty("--cursor-h", `${box.height}px`);
    cursor.dataset.ready = "true";
    if (cursor.classList.contains("is-instant")) {
      cursor.getBoundingClientRect();
      requestAnimationFrame(() => cursor.classList.remove("is-instant"));
    }
  }

  // Afterimage left behind when the cursor glides away during a strong flow.
  function leaveCursorGhost(cursor, stage) {
    if (!state.effects.awesomenessBoost || state.flowPower < 50 || reducedMotion()) return;
    const layer = stage.querySelector("[data-impact-layer]");
    if (!layer) return;
    const ghost = document.createElement("i");
    ghost.className = `${NS}-modal__cursor-ghost`;
    ["--cursor-x", "--cursor-y", "--cursor-w", "--cursor-h"].forEach((name) => ghost.style.setProperty(name, cursor.style.getPropertyValue(name)));
    layer.appendChild(ghost);
    const animation = ghost.animate([
      { opacity: Math.min(.55, state.flowPower / 160) },
      { opacity: 0 },
    ], { duration: 260, easing: "ease-out" });
    animation.finished.then(() => ghost.remove(), () => ghost.remove());
  }

  // Short text that floats up from a point on the stage (combo milestones).
  function floatLabel(root, text, x, y, className) {
    const layer = root.querySelector("[data-impact-layer]");
    if (!layer) return;
    const label = document.createElement("b");
    label.className = `${NS}-modal__float-label ${className || ""}`;
    label.textContent = text;
    label.style.left = `${x}px`;
    label.style.top = `${y}px`;
    layer.appendChild(label);
    const animation = label.animate([
      { opacity: 0, transform: "translate(-50%, 0) scale(.6)" },
      { opacity: 1, transform: "translate(-50%, -14px) scale(1.12)", offset: .25 },
      { opacity: 0, transform: "translate(-50%, -46px) scale(1)" },
    ], { duration: 820, easing: "cubic-bezier(.22,1,.36,1)" });
    animation.finished.then(() => label.remove(), () => label.remove());
  }

  function renderFlow() {
    const root = document.getElementById(modalId);
    if (!root) return;
    const meter = root.querySelector("[data-flow-meter]");
    const track = root.querySelector("[data-flow-track]");
    root.querySelector("[data-flow]").textContent = `×${state.streak}`;
    root.querySelector("[data-flow-best]").textContent = `×${state.bestStreak}`;
    if (meter) meter.style.transform = `scaleX(${state.effects.awesomenessBoost ? state.flowPower / 100 : 0})`;
    if (track) {
      track.setAttribute("aria-valuenow", String(Math.round(state.flowPower)));
      track.setAttribute("aria-valuetext", `${Math.round(state.flowPower)}%`);
    }
    root.classList.toggle("is-flow-hot", state.effects.awesomenessBoost && state.flowPower >= 70);
    root.style.setProperty("--flow-glow", String(state.effects.awesomenessBoost ? state.flowPower / 100 : 0));
    const overdrive = state.effects.awesomenessBoost && overdriveActive(state.flowPower, state.overdrive);
    if (overdrive !== state.overdrive) {
      state.overdrive = overdrive;
      root.classList.toggle("is-overdrive", overdrive);
      if (overdrive) burstOverdrive(root);
    }
    root.querySelectorAll("[data-effect]").forEach((button) => {
      const enabled = Boolean(state.effects[button.dataset.effect]);
      button.classList.toggle("is-active", enabled);
      button.setAttribute("aria-pressed", String(enabled));
    });
  }

  function burstOverdrive(root) {
    const status = root.querySelector("[data-batch-status]");
    if (status) {
      status.textContent = "";
      requestAnimationFrame(() => { status.textContent = t("overdrive", "Overdrive"); });
    }
    if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return;
    const track = root.querySelector("[data-flow-track]");
    const stage = root.querySelector(`.${NS}-modal__stage`);
    const layer = root.querySelector("[data-impact-layer]");
    track?.animate([
      { filter: "brightness(1)", transform: "scaleY(1)" },
      { filter: "brightness(1.9)", transform: "scaleY(2.4)", offset: .3 },
      { filter: "brightness(1)", transform: "scaleY(1)" },
    ], { duration: 520, easing: "cubic-bezier(.22,1,.36,1)" });
    if (!track || !stage || !layer) return;
    const trackBox = track.getBoundingClientRect();
    const stageBox = stage.getBoundingClientRect();
    const originX = trackBox.left - stageBox.left + trackBox.width * Math.min(1, state.flowPower / 100);
    const originY = trackBox.top - stageBox.top + trackBox.height / 2;
    [[-34, -26], [-12, -38], [14, -32], [36, -18], [-40, 10], [-18, 22], [20, 24], [42, 8]].forEach(([x, y], shardIndex) => {
      const shard = document.createElement("i");
      shard.className = `${NS}-modal__overdrive-shard`;
      shard.style.left = `${originX}px`;
      shard.style.top = `${originY}px`;
      layer.appendChild(shard);
      const rotate = Math.atan2(y, x) * 180 / Math.PI;
      const animation = shard.animate([
        { opacity: 1, transform: `rotate(${rotate}deg) translateX(0) scaleX(.6)` },
        { opacity: 0, transform: `rotate(${rotate}deg) translateX(${Math.hypot(x, y) * 1.6}px) scaleX(1.4)` },
      ], { duration: 460, delay: shardIndex * 12, easing: "cubic-bezier(.22,1,.36,1)" });
      animation.finished.then(() => shard.remove(), () => shard.remove());
    });
  }

  function triggerKeystrokeFeedback({ index, char, correct }) {
    const root = document.getElementById(modalId);
    if (!root || window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return;
    const charElement = root.querySelector(`[data-index="${index}"]`);
    const cursor = root.querySelector("[data-cursor]");
    const stageForEffects = root.querySelector(`.${NS}-modal__stage`);

    if (cursor && correct && state.effects.pinyinBump) {
      // Squash and recover on every hit; `scale` composes with the gliding transform.
      cursor.animate([
        { scale: "1 1" },
        { scale: "1.28 .78", offset: .3 },
        { scale: ".94 1.06", offset: .65 },
        { scale: "1 1" },
      ], { duration: 180, easing: "cubic-bezier(.22,1,.36,1)" });
    } else if (cursor && !correct) {
      cursor.animate([
        { translate: "0 0", backgroundColor: "#d33d35" },
        { translate: "-4px 0", offset: .25 },
        { translate: "4px 0", offset: .55 },
        { translate: "0 0" },
      ], { duration: 220, easing: "cubic-bezier(.22,1,.36,1)" });
    }

    if (correct && char === " " && state.effects.pinyinBump) {
      // Finished a word cleanly: lift its hanzi and throw a few sparks.
      const word = root.querySelector(`.${NS}-modal__word[data-word-end="${index}"]`);
      const clean = word && ![...word.querySelectorAll(`.${NS}-modal__char`)].some((ch) => !ch.classList.contains("is-done"));
      const hanzi = clean ? word.querySelector(`.${NS}-modal__hanzi`) : null;
      if (hanzi) {
        hanzi.animate([
          { transform: "translateY(0) scale(1)", backgroundColor: "transparent" },
          { transform: "translateY(-5px) scale(1.06)", backgroundColor: "color-mix(in srgb, var(--typing-accent) 28%, transparent)", offset: .35 },
          { transform: "translateY(0) scale(1)", backgroundColor: "transparent" },
        ], { duration: 360, easing: "cubic-bezier(.22,1,.36,1)" });
        const layer = root.querySelector("[data-impact-layer]");
        if (layer && stageForEffects) {
          const box = hanzi.getBoundingClientRect();
          const stageBox = stageForEffects.getBoundingClientRect();
          [[-18, -16], [0, -24], [18, -16], [26, -2]].forEach(([x, y], sparkIndex) => {
            const spark = document.createElement("i");
            spark.className = `${NS}-modal__word-spark`;
            spark.style.left = `${box.left - stageBox.left + Math.min(box.width, 64) / 2}px`;
            spark.style.top = `${box.top - stageBox.top + box.height / 2}px`;
            layer.appendChild(spark);
            const animation = spark.animate([
              { opacity: 1, transform: "translate(-50%, -50%) scale(1)" },
              { opacity: 0, transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px)) scale(.3)` },
            ], { duration: 380, delay: sparkIndex * 18, easing: "cubic-bezier(.22,1,.36,1)" });
            animation.finished.then(() => spark.remove(), () => spark.remove());
          });
        }
      }
    }

    if (correct && state.effects.awesomenessBoost && comboMilestones.includes(state.streak) && cursor && stageForEffects) {
      const box = cursor.getBoundingClientRect();
      const stageBox = stageForEffects.getBoundingClientRect();
      floatLabel(root, `×${state.streak}`, box.left - stageBox.left + box.width / 2, box.top - stageBox.top - 6, state.streak >= 100 ? "is-big" : "");
    }

    if (charElement && correct && state.effects.pinyinBump) {
      charElement.getAnimations().forEach((animation) => animation.cancel());
      charElement.animate([
        { opacity: 1, transform: "translateY(0) scale(1)" },
        { opacity: 1, transform: "translateY(-9px) scale(1.18)", offset: .34 },
        { opacity: 1, transform: "translateY(0) scale(1)" },
      ], { duration: 170, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });

      const activeWord = charElement.closest(`.${NS}-modal__word`);
      activeWord?.getAnimations().forEach((animation) => {
        if (animation.effect?.target === activeWord) animation.cancel();
      });
      activeWord?.animate([
        { transform: "translate3d(0, 0, 0) scale(1)" },
        { transform: "translate3d(0, -4px, 0) scale(1.026)", offset: .42 },
        { transform: "translate3d(0, 0, 0) scale(1)" },
      ], { duration: 210, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });

      const layer = root.querySelector("[data-impact-layer]");
      const stage = root.querySelector(`.${NS}-modal__stage`);
      if (layer && stage) {
        const box = charElement.getBoundingClientRect();
        const stageBox = stage.getBoundingClientRect();
        const isBurstBeat = state.streak >= 4 && state.streak % 4 === 0;
        const particleVectors = isBurstBeat
          ? [[-24, -14], [26, -11], [8, -24], [-28, 2], [30, 3], [0, -30], [17, -22], [-16, -21]]
          : [[12, -15], [-9, -13], [2, -20]];
        particleVectors.forEach(([x, y], particleIndex) => {
          const particle = document.createElement("i");
          particle.style.left = `${box.left - stageBox.left + box.width / 2}px`;
          particle.style.top = `${box.top - stageBox.top + box.height / 2}px`;
          layer.appendChild(particle);
          const animation = particle.animate([
            { opacity: .98, transform: "translate3d(0, 0, 0) scaleX(1) scaleY(1)" },
            { opacity: .72, transform: `translate3d(${x * .44}px, ${y * .44}px, 0) scaleX(${isBurstBeat ? 2.2 : 1.75}) scaleY(1.15)`, offset: .35 },
            { opacity: 0, transform: `translate3d(${x}px, ${y}px, 0) scaleX(${isBurstBeat ? 3.2 : 2.35}) scaleY(.75)` },
          ], { duration: isBurstBeat ? 310 : 210, delay: particleIndex * 7, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
          animation.finished.then(() => particle.remove(), () => particle.remove());
        });

        if (state.streak >= 8 && state.streak % 4 === 0) {
          const ring = document.createElement("i");
          ring.className = `${NS}-modal__impact-ring`;
          ring.style.left = `${box.left - stageBox.left + box.width / 2}px`;
          ring.style.top = `${box.top - stageBox.top + box.height / 2}px`;
          layer.appendChild(ring);
          const ringAnimation = ring.animate([
            { opacity: .9, transform: "translate(-50%, -50%) scale(.22)" },
            { opacity: .44, transform: "translate(-50%, -50%) scale(1.8)", offset: .42 },
            { opacity: 0, transform: "translate(-50%, -50%) scale(4.4)" },
          ], { duration: 390, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
          ringAnimation.finished.then(() => ring.remove(), () => ring.remove());
        }
      }
    } else if (charElement && !correct) {
      charElement.animate([
        { transform: "translateX(0)" },
        { transform: "translateX(-3px)" },
        { transform: "translateX(3px)" },
        { transform: "translateX(0)" },
      ], { duration: 150, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
    }

    if (correct && char === " " && state.effects.spaceFeedback) {
      const spaceKey = root.querySelector("[data-space-key]");
      const wave = root.querySelector("[data-space-wave]");
      spaceKey?.animate([
        { transform: "translateY(0) scale(1)" },
        { transform: "translateY(-5px) scale(1.04)" },
        { transform: "translateY(2px) scale(.98)" },
        { transform: "translateY(0) scale(1)" },
      ], { duration: 220, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
      wave?.animate([
        { opacity: 0, transform: "scaleX(.04)" },
        { opacity: .7, transform: "scaleX(.72)", offset: .35 },
        { opacity: 0, transform: "scaleX(1)" },
      ], { duration: 280, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
    }

    if (correct && state.effects.awesomenessBoost && state.streak >= 4) {
      const meter = root.querySelector("[data-flow-meter]");
      const track = root.querySelector("[data-flow-track]");
      const flare = root.querySelector("[data-space-wave]");
      const progress = state.flowPower / 100;
      const isBurstBeat = state.streak % 4 === 0;
      meter?.animate([
        { transform: `scaleX(${progress}) scaleY(1)` },
        { transform: `scaleX(${progress}) scaleY(${isBurstBeat ? 3.4 : 2.15})` },
        { transform: `scaleX(${progress}) scaleY(1)` },
      ], { duration: isBurstBeat ? 210 : 140, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });

      if (isBurstBeat) {
        track?.animate([
          { transform: "translateY(0) scaleY(1)" },
          { transform: "translateY(-1px) scaleY(1.65)" },
          { transform: "translateY(0) scaleY(1)" },
        ], { duration: 210, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
        flare?.animate([
          { opacity: 0, transform: "translateX(-46%) scaleX(.06)" },
          { opacity: .95, transform: "translateX(0) scaleX(.52)", offset: .42 },
          { opacity: 0, transform: "translateX(46%) scaleX(.18)" },
        ], { duration: 260, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
      }
    }

    if (correct && state.effects.awesomenessBoost && state.streak >= 12 && state.flowPower >= 70 && state.streak % 4 === 0) {
      const text = root.querySelector(`.${NS}-modal__text`);
      text?.getAnimations().forEach((animation) => animation.cancel());
      text?.animate([
        { transform: "translate3d(0, 0, 0)" },
        { transform: "translate3d(-1.5px, .5px, 0)" },
        { transform: "translate3d(1px, -.5px, 0)" },
        { transform: "translate3d(0, 0, 0)" },
      ], { duration: 90, easing: "linear" });

      const stage = root.querySelector(`.${NS}-modal__stage`);
      stage?.animate([
        { transform: "translate3d(0, 0, 0) scale(1)" },
        { transform: "translate3d(0, -1px, 0) scale(1.003)" },
        { transform: "translate3d(0, 0, 0) scale(1)" },
      ], { duration: 150, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
    }
  }

  function renderStats() {
    const root = document.getElementById(modalId);
    if (!root) return;
    root.querySelector("[data-wpm]").textContent = String(wpm());
    root.querySelector("[data-accuracy]").textContent = `${accuracy()}%`;
    root.querySelector("[data-errors]").textContent = String(errorCount());
    root.querySelector("[data-time]").textContent = `${Math.max(0, state.duration - Math.ceil(state.elapsed / 1000))} ${escape(t("seconds", "sec"))}`;
    root.querySelector("[data-best]").textContent = best() ? `${best()} ${escape(t("wpm", "WPM"))}` : t("no_score", "No score yet");
    renderFlow();
  }

  function clearRestartShortcut() {
    state.restartArmed = false;
    document.getElementById(modalId)?.classList.remove("is-restart-armed");
  }

  function celebratePerfectRow(row) {
    const root = document.getElementById(modalId);
    if (!root) return;
    const status = root.querySelector("[data-batch-status]");
    status.textContent = "";
    requestAnimationFrame(() => { status.textContent = t("perfect_row", "Perfect row"); });
    if (!state.effects.awesomenessBoost || window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return;
    const words = [...root.querySelectorAll(`.${NS}-modal__word`)].filter((word) => {
      const index = Number(word.dataset.tokenIndex);
      return index >= row.start && index < row.end;
    });
    if (!words.length) return;
    words.forEach((word, index) => {
      word.animate([
        { transform: "translateY(0) scale(1)" },
        { transform: "translateY(-7px) scale(1.035)", offset: .42 },
        { transform: "translateY(0) scale(1)" },
      ], { duration: 420, delay: index * 34, easing: "cubic-bezier(.22,1,.36,1)" });
    });
    const stage = root.querySelector(`.${NS}-modal__stage`);
    const layer = root.querySelector("[data-impact-layer]");
    if (!stage || !layer) return;
    const boxes = words.map((word) => word.getBoundingClientRect());
    const stageBox = stage.getBoundingClientRect();
    const left = Math.min(...boxes.map((box) => box.left));
    const top = Math.min(...boxes.map((box) => box.top));
    const band = document.createElement("span");
    band.className = `${NS}-modal__perfect-row`;
    band.style.left = `${left - stageBox.left}px`;
    band.style.top = `${top - stageBox.top}px`;
    band.style.width = `${Math.max(...boxes.map((box) => box.right)) - left}px`;
    band.style.height = `${Math.max(...boxes.map((box) => box.bottom)) - top}px`;
    band.innerHTML = `<b>${escape(t("perfect_row", "Perfect row"))}</b>`;
    layer.appendChild(band);
    const animation = band.animate([
      { opacity: 0, transform: "scaleX(.25)" },
      { opacity: 1, transform: "scaleX(1)", offset: .28 },
      { opacity: .9, transform: "scaleX(1)", offset: .68 },
      { opacity: 0, transform: "scaleX(1.025)" },
    ], { duration: 900, easing: "cubic-bezier(.22,1,.36,1)" });
    animation.finished.then(() => band.remove(), () => band.remove());
  }

  function reset() {
    clearInterval(state.timer);
    clearRestartShortcut();
    reachedSpeed = 0;
    const generated = randomText();
    state.tokens = generated.tokens;
    state.target = generated.target;
    state.display = generated.display;
    state.pinyin = generated.pinyin;
    state.typed = "";
    state.running = false;
    state.finished = false;
    state.startedAt = 0;
    state.elapsed = 0;
    state.correct = 0;
    state.total = 0;
    state.streak = 0;
    state.flowPower = 0;
    state.overdrive = false;
    document.getElementById(modalId)?.classList.remove("is-overdrive");
    state.lastInputAt = 0;
    state.cadence = 0;
    state.mistakeTokens.clear();
    state.celebratedRows.clear();
    renderText();
    renderStats();
    const root = document.getElementById(modalId);
    if (root) {
      const result = root.querySelector("[data-result]");
      result.dataset.open = "false";
      result.hidden = true;
      root.querySelectorAll("[data-restart-label]").forEach((label) => { label.textContent = t("restart", "Restart"); });
      root.querySelector("[data-batch-status]").textContent = "";
    }
  }

  function advanceBatch() {
    const generated = randomText();
    state.tokens = generated.tokens;
    state.target = generated.target;
    state.display = generated.display;
    state.pinyin = generated.pinyin;
    state.typed = "";
    state.mistakeTokens.clear();
    state.celebratedRows.clear();
    renderText();
    const root = document.getElementById(modalId);
    if (!root) return;
    const status = root.querySelector("[data-batch-status]");
    status.textContent = "";
    requestAnimationFrame(() => { status.textContent = t("batch_updated", "New words loaded"); });
    const text = root.querySelector(`.${NS}-modal__text`);
    if (!window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) {
      text?.animate([
        { opacity: .45, transform: "translateY(6px)" },
        { opacity: 1, transform: "translateY(0)" },
      ], { duration: 160, easing: "cubic-bezier(0.22, 1, 0.36, 1)" });
    }
  }

  function finish() {
    clearInterval(state.timer);
    state.running = false;
    state.finished = true;
    state.elapsed = Math.min(state.elapsed, state.duration * 1000);
    const score = wpm();
    if (score > best()) writeStorage(bestKey(), String(score));
    const root = document.getElementById(modalId);
    if (!root) return;
    const result = root.querySelector("[data-result]");
    closeSettingPanels();
    renderStats();
    result.querySelector("[data-final-wpm]").textContent = String(score);
    result.querySelector("[data-final-accuracy]").textContent = `${accuracy()}%`;
    result.querySelector("[data-final-errors]").textContent = String(errorCount());
    result.querySelector("[data-final-best]").textContent = `${best()} ${t("wpm", "WPM")}`;
    result.querySelector("[data-final-streak]").textContent = `×${state.bestStreak}`;
    result.hidden = false;
    requestAnimationFrame(() => { result.dataset.open = "true"; });
    root.querySelectorAll("[data-restart-label]").forEach((label) => { label.textContent = t("next", "Next run"); });
    result.querySelector("[data-result-restart]")?.focus();
  }

  function startClock() {
    if (state.running) return;
    state.running = true;
    state.startedAt = Date.now();
    state.timer = setInterval(() => {
      state.elapsed = Date.now() - state.startedAt;
      const idleFor = state.lastInputAt ? performance.now() - state.lastInputAt : 0;
      if (idleFor > 260) {
        state.flowPower = Math.max(0, state.flowPower - (idleFor > 850 ? 4.2 : 1.6));
        if (idleFor > 1200) state.streak = 0;
      }
      renderStats();
      if (state.elapsed >= state.duration * 1000) finish();
    }, 100);
  }

  function processInput(chars) {
    if (!chars || state.finished) return;
    startClock();
    const feedback = [];
    const completedRows = [];
    const lengths = state.tokens.map((word) => (state.language === "zh" ? (pinyin[word] || word) : word).length);
    for (const rawChar of chars) {
      if (state.typed.length >= state.target.length) break;
      const inputAt = performance.now();
      const interval = state.lastInputAt ? inputAt - state.lastInputAt : 0;
      if (interval) state.cadence = state.cadence ? state.cadence * .72 + interval * .28 : interval;
      const char = rawChar.toLowerCase();
      const index = state.typed.length;
      const expected = state.target[index];
      const correct = char === expected;
      state.total += 1;
      if (correct) {
        state.correct += 1;
        state.streak += 1;
        const speedScore = interval ? Math.max(0, Math.min(100, 112 - interval / 4.5)) : 20;
        state.flowPower = Math.min(100, state.flowPower * .72 + speedScore * .28 + (state.streak >= 10 ? 2 : 0));
        if (state.streak > state.bestStreak) {
          state.bestStreak = state.streak;
          writeStorage(flowBestKey, String(state.bestStreak));
        }
      } else {
        state.mistakeTokens.add(tokenIndexAtOffset(lengths, index));
        state.streak = 0;
        state.flowPower = Math.max(0, state.flowPower * .78 - 7);
      }
      state.lastInputAt = inputAt;
      feedback.push({ index, char, correct });
      playClick();
      // Wrong keys are accepted and marked; Backspace corrects them.
      state.typed += char;
      const row = correct ? completedRowAt(lengths, state.typed.length, state.columns) : null;
      const rowHasMistake = row && [...state.mistakeTokens].some((token) => token >= row.start && token < row.end);
      if (row && !rowHasMistake && !state.celebratedRows.has(row.key)) {
        state.celebratedRows.add(row.key);
        completedRows.push(row);
      }
    }
    renderText();
    renderStats();
    feedback.forEach(triggerKeystrokeFeedback);
    completedRows.forEach(celebratePerfectRow);
    const milestone = speedMilestone(wpm(), state.elapsed);
    if (milestone > reachedSpeed) {
      reachedSpeed = milestone;
      const root = document.getElementById(modalId);
      if (state.effects.awesomenessBoost && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        root?.querySelector("[data-wpm]")?.animate([
          { transform: "scale(1)", color: "var(--typing-ink)" },
          { transform: "scale(1.16)", color: "var(--typing-accent)", offset: .35 },
          { transform: "scale(1)", color: "var(--typing-ink)" },
        ], { duration: 450, easing: "cubic-bezier(.22,1,.36,1)" });
      }
    }
    if (state.typed.length >= state.target.length) advanceBatch();
  }

  function onResize() {
    cancelAnimationFrame(state.resizeFrame);
    state.resizeFrame = requestAnimationFrame(() => {
      if (!state.open) return;
      const root = document.getElementById(modalId);
      if (!root) return;
      const viewport = window.visualViewport;
      const available = Math.max(0, (viewport?.height || window.innerHeight) - Math.max(0, root.getBoundingClientRect().top + window.scrollY));
      root.style.setProperty("--typing-available-height", `${available}px`);
      const text = root.querySelector(`.${NS}-modal__text`);
      const style = getComputedStyle(text);
      const word = root.querySelector(`.${NS}-modal__word`);
      const nextRows = visibleRows(text.clientHeight - 8, word?.offsetHeight || 80, parseFloat(style.rowGap) || 0);
      const nextColumns = getColumnCount();
      if (nextColumns === state.columns && nextRows === state.rows) {
        placeCursor(true);
        return;
      }
      state.columns = nextColumns;
      state.rows = nextRows;
      // Reflow the current batch without discarding an in-progress result.
      if (state.running || state.typed.length || state.finished) renderText();
      else reset();
    });
  }

  function onKeyDown(event) {
    if (!state.open || event.metaKey || event.ctrlKey || event.altKey) return;
    const root = document.getElementById(modalId);
    const interactiveTarget = event.target.closest?.("button, a, input, select, textarea");
    if (event.key === "Tab" && !event.shiftKey && !interactiveTarget) {
      event.preventDefault();
      closeSettingPanels();
      state.restartArmed = true;
      root?.classList.add("is-restart-armed");
      root?.querySelector("[data-start]:not([data-result-restart])")?.focus({ preventScroll: true });
      return;
    }
    if (event.key === "Enter" && state.restartArmed) {
      event.preventDefault();
      reset();
      root?.querySelector(`.${NS}-modal__text`)?.focus({ preventScroll: true });
      return;
    }
    if (event.key === "Escape") {
      event.preventDefault();
      clearRestartShortcut();
      if (closeSettingPanels()) document.querySelector(`.${NS}-modal__text`)?.focus({ preventScroll: true });
      else close();
      return;
    }
    if (state.finished) return;
    if (interactiveTarget) return;
    if (event.code === "Backspace" || event.key === "Backspace") {
      event.preventDefault();
      state.typed = state.typed.slice(0, -1);
      state.streak = 0;
      state.flowPower = Math.max(0, state.flowPower - 9);
      renderText();
      renderStats();
      return;
    }
    let character = event.key;
    if (state.language === "zh") {
      const physicalLetter = /^Key([A-Z])$/.exec(event.code);
      character = physicalLetter ? physicalLetter[1].toLowerCase() : event.code === "Space" ? " " : "";
    }
    if (character.length !== 1) return;
    event.preventDefault();
    processInput(character);
  }

  function closeSettingPanels() {
    const root = document.getElementById(modalId);
    if (!root) return false;
    const openPanels = [...root.querySelectorAll("[data-settings-panel][data-open='true']")];
    if (!openPanels.length) return false;
    openPanels.forEach((panel) => {
      panel.dataset.open = "false";
      window.setTimeout(() => { if (panel.dataset.open !== "true") panel.hidden = true; }, 120);
    });
    root.querySelectorAll("[data-panel-toggle]").forEach((button) => button.setAttribute("aria-expanded", "false"));
    return true;
  }

  function toggleSettingPanel(name, trigger) {
    const root = document.getElementById(modalId);
    const panel = root?.querySelector(`[data-settings-panel="${name}"]`);
    if (!root || !panel) return;
    const shouldOpen = panel.hidden || panel.dataset.open !== "true";
    closeSettingPanels();
    if (!shouldOpen) return;
    panel.hidden = false;
    panel.dataset.open = "false";
    requestAnimationFrame(() => { panel.dataset.open = "true"; });
    trigger.setAttribute("aria-expanded", "true");
  }

  function modalHtml() {
    const pills = durations.map((duration) => `<button type="button" class="${NS}-modal__choice${duration === state.duration ? " is-active" : ""}" data-duration="${duration}">${icon("clock")}<span>${duration}s</span></button>`).join("");
    const groups = Object.entries(chineseGroups).map(([id, group]) => `<button type="button" class="${NS}-modal__choice${state.group === id ? " is-active" : ""}" data-group="${id}">${icon("shuffle")}<span>${escape(t(`group_${id}`, group.label))}</span></button>`).join("");
    const effects = [
      ["pinyinBump", "bump", "effect_bump", "Pinyin bump", "effect_bump_description", "Light character impact and particles"],
      ["awesomenessBoost", "wave", "effect_flow", "Flow boost", "effect_flow_description", "Impact and light waves while typing continuously"],
      ["spaceFeedback", "space", "effect_space", "Space feedback", "effect_space_description", "Space key lift and landing feedback"],
    ].map(([id, iconName, labelKey, labelFallback, descriptionKey, descriptionFallback]) => `<button type="button" class="${NS}-modal__effect-choice${state.effects[id] ? " is-active" : ""}" data-effect="${id}" aria-pressed="${state.effects[id]}">${icon(iconName)}<span><b>${escape(t(labelKey, labelFallback))}</b><small>${escape(t(descriptionKey, descriptionFallback))}</small></span><i aria-hidden="true"></i></button>`).join("");
    const activeGroup = chineseGroups[state.group] || chineseGroups.random;
    const settingsLabel = escape(t("settings_label", "Typing settings"));
    return `<div class="${NS}-backdrop" data-close></div><section id="${modalId}" class="${NS}-modal" aria-label="${escape(t("title", "Typing Lab"))}">
      <div class="${NS}-modal__stage"><div class="${NS}-modal__flow"><div class="${NS}-modal__flow-meta"><strong>${escape(t("flow_label", "WORD FLOW"))}</strong><span>${escape(t("flow", "flow"))} <b data-flow>×0</b></span><span>${escape(t("flow_best", "best"))} <b data-flow-best>×${state.bestStreak}</b></span><span class="${NS}-modal__space-key" data-space-key>${escape(t("space_key", "SPACE"))}</span></div><div class="${NS}-modal__flow-track" data-flow-track role="progressbar" aria-label="${escape(t("flow_meter", "Flow meter"))}" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><i data-flow-meter></i><span data-space-wave></span></div></div>
      <span class="${NS}-modal__cursor" data-cursor data-ready="false" aria-hidden="true"></span><div class="${NS}-modal__text" tabindex="0" role="textbox" aria-readonly="true" aria-label="${escape(t("hint", "Type the text above. Backspace works."))}"></div><span class="${NS}-modal__impact-layer" data-impact-layer aria-hidden="true"></span><span class="${NS}-sr-only" data-batch-status aria-live="polite"></span>
      <div class="${NS}-modal__stats"><div class="${NS}-modal__stat"><strong data-wpm>0</strong><span>${escape(t("wpm", "WPM"))}</span></div><div class="${NS}-modal__stat"><strong data-accuracy>100%</strong><span>${escape(t("accuracy", "accuracy"))} · <b data-errors>0</b> ${escape(t("errors", "errors"))}</span></div><div class="${NS}-modal__stat"><strong data-time>30 sec</strong><span>${escape(t("best", "best"))}: <b data-best>${escape(t("no_score", "No score yet"))}</b></span></div></div>
      <p class="${NS}-modal__hint">${escape(t("ready", "Start typing directly"))}</p></div>
      <footer class="${NS}-modal__controls"><div class="${NS}-modal__settings" role="toolbar" aria-label="${settingsLabel}">
      <button type="button" class="${NS}-modal__icon-button" data-start data-tooltip="${escape(t("restart", "Restart"))}" aria-label="${escape(t("restart", "Restart"))}">${icon("restart")}<span class="${NS}-sr-only" data-restart-label>${escape(t("restart", "Restart"))}</span><kbd>Tab ↵</kbd></button>
      <span class="${NS}-modal__settings-divider" aria-hidden="true"></span>
      <button type="button" class="${NS}-modal__icon-button" data-panel-toggle="time" data-tooltip="${escape(t("time_label", "Time"))}" aria-label="${escape(t("time_label", "Time"))}" aria-controls="${modalId}-time-panel" aria-expanded="false">${icon("clock")}<span data-current-duration>${state.duration}s</span></button>
      <button type="button" class="${NS}-modal__icon-button" data-panel-toggle="mode" data-tooltip="${escape(t("mode_label", "Mode"))}" aria-label="${escape(t("mode_label", "Mode"))}" aria-controls="${modalId}-mode-panel" aria-expanded="false">${icon("shuffle")}<span data-current-group>${escape(t(`group_${state.group}`, activeGroup.label))}</span></button>
      <button type="button" class="${NS}-modal__icon-button" data-panel-toggle="language" data-tooltip="${escape(t("language_label", "Language"))}" aria-label="${escape(t("language_label", "Language"))}" aria-controls="${modalId}-language-panel" aria-expanded="false">${icon("globe")}<span data-current-language>${state.language === "zh" ? "中" : "EN"}</span></button>
      <button type="button" class="${NS}-modal__icon-button${state.hard ? " is-active" : ""}" data-hard="true" data-tooltip="${escape(t("hard", "Hard"))}" aria-label="${escape(t("hard", "Hard"))}" aria-pressed="${state.hard}">${icon("bolt")}</button>
      <button type="button" class="${NS}-modal__icon-button" data-panel-toggle="effects" data-tooltip="${escape(t("effects_label", "Effects"))}" aria-label="${escape(t("effects_label", "Effects"))}" aria-controls="${modalId}-effects-panel" aria-expanded="false">${icon("spark")}<span data-current-effects>${enabledEffectCount()}</span></button>
      <span class="${NS}-modal__settings-spacer"></span>
      <button type="button" class="${NS}-modal__icon-button${state.muted ? " is-muted" : " is-active"}" data-sound data-tooltip="${escape(t(state.muted ? "sound_off" : "sound_on", state.muted ? "Sound off" : "Sound on"))}" aria-label="${escape(t(state.muted ? "sound_off" : "sound_on", state.muted ? "Sound off" : "Sound on"))}" aria-pressed="${!state.muted}">${icon("sound")}</button>
      </div>
      <div id="${modalId}-time-panel" class="${NS}-modal__settings-panel" data-settings-panel="time" data-open="false" hidden><strong>${escape(t("time_label", "Time"))}</strong><div class="${NS}-modal__choice-grid">${pills}</div></div>
      <div id="${modalId}-mode-panel" class="${NS}-modal__settings-panel" data-settings-panel="mode" data-open="false" hidden><strong>${escape(t("mode_label", "Mode"))}</strong><div class="${NS}-modal__choice-grid">${groups}</div></div>
      <div id="${modalId}-language-panel" class="${NS}-modal__settings-panel" data-settings-panel="language" data-open="false" hidden><strong>${escape(t("language_label", "Language"))}</strong><div class="${NS}-modal__choice-grid"><button type="button" class="${NS}-modal__choice${state.language === "zh" ? " is-active" : ""}" data-language="zh">${icon("globe")}<span>中文</span></button><button type="button" class="${NS}-modal__choice${state.language === "en" ? " is-active" : ""}" data-language="en">${icon("globe")}<span>English</span></button></div></div>
      <div id="${modalId}-effects-panel" class="${NS}-modal__settings-panel ${NS}-modal__settings-panel--effects" data-settings-panel="effects" data-open="false" hidden><strong>${escape(t("effects_label", "Effects"))}</strong><div class="${NS}-modal__effect-list">${effects}</div></div>
      </footer><div class="${NS}-modal__result" data-result data-open="false" role="dialog" aria-modal="true" aria-labelledby="${modalId}-result-title" hidden><div class="${NS}-modal__result-card">${icon("spark")}<small>${escape(t("finished", "Run complete"))}</small><h3 id="${modalId}-result-title">${escape(t("results_title", "Your result"))}</h3><div class="${NS}-modal__result-score"><strong data-final-wpm>0</strong><span>${escape(t("wpm", "WPM"))}</span></div><div class="${NS}-modal__result-grid"><span><b data-final-accuracy>100%</b><small>${escape(t("accuracy", "accuracy"))}</small></span><span><b data-final-errors>0</b><small>${escape(t("errors_label", "errors"))}</small></span><span><b data-final-best>0 WPM</b><small>${escape(t("result_best", "best"))}</small></span><span><b data-final-streak>×0</b><small>${escape(t("flow_best", "best flow"))}</small></span></div><button type="button" class="${NS}-modal__result-restart" data-start data-result-restart>${icon("restart")}<span data-restart-label>${escape(t("next", "Next run"))}</span><kbd>Enter</kbd></button></div></div>
    </section>`;
  }

  function ensureMount() {
    let mount = document.getElementById(`${NS}-page`);
    if (mount) return mount;
    const outlet = document.getElementById("main-outlet");
    if (!outlet) return null;
    outlet.insertAdjacentHTML("beforeend", `<main id="${NS}-page" class="${NS}-page" aria-label="${escape(t("open", "Typing"))}"></main>`);
    return document.getElementById(`${NS}-page`);
  }

  function open() {
    if (state.open && document.getElementById(modalId)) return true;
    if (state.open) {
      clearInterval(state.timer);
      state.open = false;
      document.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("resize", onResize);
      window.visualViewport?.removeEventListener("resize", onResize);
    }
    const mount = ensureMount();
    if (!mount) return false;
    state.open = true;
    mount.insertAdjacentHTML("beforeend", modalHtml());
    document.body.classList.add(`${NS}-route`);
    state.columns = getColumnCount();
    reset();
    const root = document.getElementById(modalId);
    root.querySelectorAll("[data-tooltip]").forEach((button) => {
      button.title = button.dataset.tooltip;
    });
    root.querySelector(`.${NS}-modal__text`)?.focus();
    root.addEventListener("click", (event) => {
      const target = event.target.closest("button[data-close], button[data-start], [data-sound], [data-duration], [data-group], [data-language], [data-hard], [data-effect], [data-panel-toggle]");
      if (!target) {
        if (!event.target.closest("[data-settings-panel], .moaclab-typing-modal__settings")) closeSettingPanels();
        return;
      }
      if (!target.matches("[data-start]")) clearRestartShortcut();
      if (target.matches("[data-close]")) close();
      if (target.matches("[data-start]")) { reset(); root.querySelector(`.${NS}-modal__text`)?.focus(); }
      if (target.matches("[data-panel-toggle]")) { toggleSettingPanel(target.dataset.panelToggle, target); return; }
      if (target.matches("[data-sound]")) {
        state.muted = !state.muted;
        const label = t(state.muted ? "sound_off" : "sound_on", state.muted ? "Sound off" : "Sound on");
        target.classList.toggle("is-muted", state.muted);
        target.classList.toggle("is-active", !state.muted);
        target.setAttribute("aria-pressed", String(!state.muted));
        target.setAttribute("aria-label", label);
        target.dataset.tooltip = label;
        target.title = label;
      }
      if (target.matches("[data-duration]")) {
        state.duration = Number(target.dataset.duration);
        root.querySelectorAll("[data-duration]").forEach((el) => el.classList.toggle("is-active", el === target));
        root.querySelector("[data-current-duration]").textContent = `${state.duration}s`;
        closeSettingPanels();
        reset();
      }
      if (target.matches("[data-group]")) {
        state.group = target.dataset.group;
        state.language = "zh";
        root.querySelectorAll("[data-group]").forEach((el) => el.classList.toggle("is-active", el === target));
        root.querySelectorAll("[data-language]").forEach((el) => el.classList.toggle("is-active", el.dataset.language === state.language));
        root.querySelector("[data-current-group]").textContent = t(`group_${state.group}`, chineseGroups[state.group].label);
        root.querySelector("[data-current-language]").textContent = "中";
        closeSettingPanels();
        reset();
      }
      if (target.matches("[data-language]")) {
        state.language = target.dataset.language;
        root.querySelectorAll("[data-language]").forEach((el) => el.classList.toggle("is-active", el.dataset.language === state.language));
        root.querySelector("[data-current-language]").textContent = state.language === "zh" ? "中" : "EN";
        closeSettingPanels();
        reset();
      }
      if (target.matches("[data-hard]")) {
        state.hard = !state.hard;
        target.classList.toggle("is-active", state.hard);
        target.setAttribute("aria-pressed", String(state.hard));
        reset();
      }
      if (target.matches("[data-effect]")) {
        const id = target.dataset.effect;
        state.effects[id] = !state.effects[id];
        writeStorage(effectStorageKey, JSON.stringify(state.effects));
        root.querySelector("[data-current-effects]").textContent = String(enabledEffectCount());
        renderFlow();
      }
      if (!target.matches("[data-effect]")) root.querySelector(`.${NS}-modal__text`)?.focus({ preventScroll: true });
    });
    document.addEventListener("keydown", onKeyDown);
    window.addEventListener("resize", onResize, { passive: true });
    window.visualViewport?.addEventListener("resize", onResize, { passive: true });
    layoutObserver?.disconnect();
    layoutObserver = new ResizeObserver(onResize);
    layoutObserver.observe(root.querySelector(`.${NS}-modal__text`));
    onResize();
    return true;
  }

  function close() {
    clearInterval(state.timer);
    cancelAnimationFrame(reconcileFrame);
    state.open = false;
    document.querySelector(`#${NS}-page .${NS}-backdrop`)?.remove();
    document.getElementById(modalId)?.remove();
    document.getElementById(`${NS}-page`)?.remove();
    document.body.classList.remove(`${NS}-route`);
    document.removeEventListener("keydown", onKeyDown);
    window.removeEventListener("resize", onResize);
    window.visualViewport?.removeEventListener("resize", onResize);
    renderedTokens = null;
    cancelAnimationFrame(state.resizeFrame);
    layoutObserver?.disconnect();
    layoutObserver = null;
  }

  function syncSidebarSelection(active = isTypingRoute()) {
    if (!setting("show_sidebar_link", false)) return;
    const typingLink = document.querySelector('.sidebar-section-link[data-link-name="moaclab-typing"]');
    if (typingLink) {
      typingLink.classList.toggle(`${NS}-sidebar-selected`, active);
      if (active) typingLink.setAttribute("aria-current", "page");
      else typingLink.removeAttribute("aria-current");
    }
  }

  function reconcileTypingRoute() {
    cancelAnimationFrame(reconcileFrame);
    reconcileFrame = window.requestAnimationFrame(() => {
      if (!isTypingRoute()) return;
      syncSidebarSelection(true);
      open();
    });
  }

  function observeTypingRoute() {
    if (routeObserver || !document.body) return;
    routeObserver = new MutationObserver(() => {
      // Discourse can swap the outlet before onPageChange is delivered. Always
      // reconcile both entering and leaving, otherwise a tool page can survive
      // underneath /t/... and /c/... URLs until a full refresh.
      cancelAnimationFrame(reconcileFrame);
      reconcileFrame = window.requestAnimationFrame(syncRoute);
    });
    routeObserver.observe(document.body, { childList: true, subtree: true });
  }

  function syncRoute() {
    if (isTypingRoute()) {
      document.body.classList.add(`${NS}-route`);
      syncSidebarSelection(true);
      reconcileTypingRoute();
    } else {
      syncSidebarSelection(false);
      close();
    }
  }

  window.addEventListener("popstate", syncRoute);
  observeTypingRoute();
  api.onPageChange(() => {
    cancelAnimationFrame(reconcileFrame);
    reconcileFrame = window.requestAnimationFrame(syncRoute);
  });
  syncRoute();
});
