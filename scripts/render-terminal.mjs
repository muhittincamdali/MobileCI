#!/usr/bin/env node
// Renders a terminal session (a command and the output it printed) as a PNG in the blue
// palette of the repository graphics, light and dark, with headless Chrome. Text is placed as
// it was printed: the only change is wrapping lines longer than the column limit.
//
//   node scripts/render-terminal.mjs <session.txt> <output-prefix>
//
// <session.txt> holds the command on the first line and the output after it. Writes
// <output-prefix>-light.png and <output-prefix>-dark.png. Set CHROME_PATH to use another
// Chromium-based browser.
import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const COLUMNS = 112;
const WIDTH = 1200;
const LINE_HEIGHT = 22;
const PADDING = 28;
const TITLE_BAR = 40;

const THEMES = {
  light: { page: '#FFFFFF', window: '#F5F9FF', border: '#D0E2F7', bar: '#EAF4FF', text: '#0B1F33', muted: '#5A6B80', accent: '#0071E3', strong: '#0058D4', dots: ['#8CC4FF', '#4DA3FF', '#0071E3'] },
  dark: { page: '#0D1117', window: '#04111F', border: '#1C3557', bar: '#0B1626', text: '#D0E2F7', muted: '#8FA3BC', accent: '#64D2FF', strong: '#4DA3FF', dots: ['#0E4A8F', '#0062CC', '#0A84FF'] },
};

const CHROME = [
  process.env.CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
].find((path) => path && existsSync(path));

function wrap(line) {
  if (line.length <= COLUMNS) return [line];
  const parts = [];
  let rest = line;
  while (rest.length > COLUMNS) {
    let cut = rest.lastIndexOf(' ', COLUMNS);
    if (cut <= COLUMNS / 2) cut = COLUMNS;
    parts.push(rest.slice(0, cut));
    rest = '    ' + rest.slice(cut).trimStart();
  }
  parts.push(rest);
  return parts;
}

const escape = (text) => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// Colours the parts a reader scans for: severities, rule identifiers, file positions, `wrote`.
function highlight(line) {
  return escape(line)
    .replace(/\b(error|warning|note)(\[MCI\d{3}\])/g, '<b class="sev">$1</b><span class="accent">$2</span>')
    .replace(/^([^\s:]+\.ya?ml:\d+:\d+:)/, '<span class="muted">$1</span>')
    .replace(/^(wrote|updated|would update) /, '<b class="sev">$1</b> ')
    .replace(/(\d+ files? checked: .*)$/, '<b>$1</b>');
}

function page(command, output, theme) {
  const colours = THEMES[theme];
  const lines = output.replace(/\s+$/, '').split('\n').flatMap(wrap);
  const height = TITLE_BAR + PADDING * 2 + LINE_HEIGHT * (lines.length + 2);
  const dots = colours.dots.map((colour) => `<i style="background:${colour}"></i>`).join('');
  const html = `<!doctype html><meta charset="utf-8"><style>
  html, body { margin: 0; background: ${colours.page}; }
  .window { box-sizing: border-box; width: ${WIDTH}px; height: ${height}px; background: ${colours.window};
    border: 1px solid ${colours.border}; border-radius: 12px; overflow: hidden; }
  .bar { height: ${TITLE_BAR}px; background: ${colours.bar}; border-bottom: 1px solid ${colours.border};
    display: flex; align-items: center; gap: 8px; padding: 0 16px; }
  .bar i { width: 12px; height: 12px; border-radius: 6px; display: block; }
  pre { margin: 0; padding: ${PADDING}px; font: 15px/${LINE_HEIGHT}px Menlo, "DejaVu Sans Mono", monospace;
    color: ${colours.text}; white-space: pre; }
  .prompt { color: ${colours.accent}; font-weight: bold; }
  .muted { color: ${colours.muted}; }
  .accent { color: ${colours.accent}; }
  .sev { color: ${colours.strong}; }
</style><div class="window"><div class="bar">${dots}</div><pre><span class="prompt">$</span> ${escape(command)}
${lines.map(highlight).join('\n')}</pre></div>`;
  return { html, height };
}

const [sessionPath, prefix] = process.argv.slice(2);
if (!sessionPath || !prefix) {
  console.error('Usage: node scripts/render-terminal.mjs <session.txt> <output-prefix>');
  process.exit(2);
}
if (!CHROME) {
  console.error('No Chrome or Chromium found; set CHROME_PATH.');
  process.exit(1);
}
const [command, ...output] = readFileSync(sessionPath, 'utf8').split('\n');
const work = mkdtempSync(join(tmpdir(), 'mobileci-terminal-'));
try {
  for (const theme of Object.keys(THEMES)) {
    const { html, height } = page(command, output.join('\n'), theme);
    const htmlPath = join(work, `${theme}.html`);
    writeFileSync(htmlPath, html);
    const png = `${prefix}-${theme}.png`;
    execFileSync(CHROME, [
      '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--no-default-browser-check',
      '--force-device-scale-factor=2', `--user-data-dir=${join(work, 'profile')}`,
      `--window-size=${WIDTH},${height}`, `--screenshot=${png}`, pathToFileURL(htmlPath).href,
    ], { stdio: 'ignore', timeout: 60000 });
    if (!existsSync(png)) throw new Error(`Chrome did not write ${png}`);
    console.log(`wrote ${png}`);
  }
} finally {
  rmSync(work, { recursive: true, force: true });
}
