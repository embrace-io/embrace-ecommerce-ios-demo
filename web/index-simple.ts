import {
  appInstanceId,
  base,
  initClicks,
  initDocumentLoad,
  initExceptions,
  initLoaf,
  post,
} from './embrace';

function initWebVitalsSimple(): void {
  const rate = (v: number, good: number, poor: number) =>
    v <= good ? 'good' : v <= poor ? 'needs-improvement' : 'poor';

  const nav = performance.getEntriesByType('navigation')[0] as
    | PerformanceNavigationTiming
    | undefined;
  const navType = nav?.type.replace(/_/g, '-') || 'navigate';

  let idCounter = 0;
  const emit = (name: string, value: number, good: number, poor: number) => {
    post({
      'emb.type': 'ux.web_vital_simple',
      'emb.web_vital.name': name,
      'emb.web_vital.value': Math.round(value),
      'emb.web_vital.rating': rate(value, good, poor),
      'emb.web_vital.id': `s-${appInstanceId}-${idCounter++}`,
      'emb.web_vital.navigation_type': navType,
      ...base(),
    });
  };

  const obs = (
    type: string,
    cb: (entries: PerformanceEntryList) => void,
  ): PerformanceObserver | undefined => {
    try {
      if (!PerformanceObserver.supportedEntryTypes?.includes(type)) return;
      const o = new PerformanceObserver((l) => cb(l.getEntries()));
      o.observe({ type, buffered: true });
      return o;
    } catch {}
  };

  const hiddenCallbacks: (() => void)[] = [];
  const onHidden = (fn: () => void) => hiddenCallbacks.push(fn);
  let flushed = false;
  const flushAll = () => {
    if (flushed) return;
    flushed = true;
    for (const fn of hiddenCallbacks) fn();
  };
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') flushAll();
  });
  window.addEventListener('pagehide', flushAll);

  // TTFB + FCP from paint/navigation entries
  if (nav) emit('TTFB', Math.max(nav.responseStart, 0), 800, 1800);

  const paintEntries = performance.getEntriesByType('paint');
  const fcpEntry = paintEntries.find(
    (e) => e.name === 'first-contentful-paint',
  );
  if (fcpEntry) emit('FCP', fcpEntry.startTime, 1800, 3000);

  // LCP — finalized on first input or hidden
  let lcpValue = 0;
  let lcpDone = false;
  const lcpObs = obs('largest-contentful-paint', (entries) => {
    const last = entries.at(-1);
    if (last) lcpValue = last.startTime;
  });
  if (lcpObs) {
    const finalizeLcp = () => {
      if (lcpDone) return;
      lcpDone = true;
      lcpObs.disconnect();
      if (lcpValue) emit('LCP', lcpValue, 2500, 4000);
    };
    onHidden(finalizeLcp);
    for (const evt of ['keydown', 'click'] as const) {
      addEventListener(evt, finalizeLcp, { once: true, capture: true });
    }
  }

  // CLS
  let clsValue = 0;
  let sessionValue = 0;
  let sessionEntries: PerformanceEntry[] = [];
  obs('layout-shift', (entries) => {
    for (const entry of entries) {
      const e = entry as PerformanceEntry & {
        hadRecentInput: boolean;
        value: number;
      };
      if (e.hadRecentInput) continue;
      const first = sessionEntries[0];
      const last = sessionEntries.at(-1);
      if (
        first &&
        last &&
        e.startTime - last.startTime < 1000 &&
        e.startTime - first.startTime < 5000
      ) {
        sessionValue += e.value;
      } else {
        sessionValue = e.value;
        sessionEntries = [];
      }
      sessionEntries.push(e);
      if (sessionValue > clsValue) clsValue = sessionValue;
    }
  });
  onHidden(() => emit('CLS', clsValue, 0.1, 0.25));
}

try {
  for (const fn of [
    initExceptions,
    initWebVitalsSimple,
    initDocumentLoad,
    initLoaf,
    initClicks,
  ]) {
    try {
      fn();
    } catch {}
  }
} catch {}
