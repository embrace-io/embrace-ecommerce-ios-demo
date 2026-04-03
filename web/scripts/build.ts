import { join } from 'node:path';

const ROOT = join(import.meta.dir, '..');
const OUTDIR = join(ROOT, '..', 'Embrace Ecommerce', 'Resources');

const jsBuild = await Bun.build({
  entrypoints: [join(ROOT, 'index.ts')],
  minify: true,
  target: 'browser',
});

const jsCode = await jsBuild.outputs[0]?.text();

const sourceHtml = await Bun.file(join(ROOT, 'index.html')).text();

const rewriter = new HTMLRewriter().on('script[src="./index.ts"]', {
  element(el) {
    el.removeAttribute('src');
    // el.removeAttribute('type');
    el.setInnerContent(jsCode ?? '// error', { html: true });
  },
});

const outputHtml = rewriter.transform(sourceHtml);

await Bun.write(join(OUTDIR, 'index.html'), outputHtml);

console.log(`Built index.html → ${OUTDIR}`);
