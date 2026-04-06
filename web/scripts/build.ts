/** biome-ignore-all lint/suspicious/noConsole: we want build output */
import { join } from 'node:path';
import { exit } from 'node:process';

const ROOT = join(import.meta.dir, '..');
const OUTDIR = join(ROOT, '..', 'Embrace Ecommerce', 'Resources');

const jsBuild = await Bun.build({
  entrypoints: [join(ROOT, 'index.ts')],
  format: 'iife',
  minify: true,
  target: 'browser',
});

if (!jsBuild.success) {
  for (const log of jsBuild.logs) console.error(log);
  exit(1);
}

const jsCode = await jsBuild.outputs[0]?.text();

const sourceHtml = await Bun.file(join(ROOT, 'index.html')).text();

const rewriter = new HTMLRewriter().on('script[src="./index.ts"]', {
  element(el) {
    el.removeAttribute('src');
    el.setInnerContent(jsCode ?? '/* error */', { html: true });
  },
});

const outputHtml = rewriter.transform(sourceHtml);

await Bun.write(join(OUTDIR, 'index.html'), outputHtml);

console.log(`Built index.html → ${OUTDIR}`);
