import type { Metric } from 'web-vitals';
import { onCLS, onFCP, onLCP, onTTFB } from 'web-vitals';

/**
 * Adds new browser features not yet in TypeScript's DOM lib (as of Oct 2025):
 * - deliveryType: Chromium only (experimental) https://developer.mozilla.org/en-US/docs/Web/API/PerformanceResourceTiming/deliveryType
 * - renderBlockingStatus: Chromium only https://developer.mozilla.org/en-US/docs/Web/API/PerformanceResourceTiming/renderBlockingStatus
 */
type EmbracePerformanceResourceTiming = PerformanceResourceTiming & {
  deliveryType?: 'cache' | '';
  renderBlockingStatus?: 'blocking' | 'non-blocking';
};

interface EmbracePayload {
  'emb.type': string;
  'emb.app_instance_id': string;
  [key: string]: string | number | undefined;
}

const appInstanceId = (() => {
  const buf = new Uint8Array(16);
  crypto.getRandomValues(buf);
  return Array.from(buf, (b) => b.toString(16).padStart(2, '0')).join('');
})();

function post(payload: EmbracePayload): void {
  try {
    console.debug(payload['emb.type'], payload);
    window.webkit?.messageHandlers.embrace.postMessage(payload);
  } catch {
    // Not in a WKWebView
  }
}

function base(): Pick<
  EmbracePayload,
  'emb.app_instance_id' | 'browser.url.full' | 'user_agent.original'
> {
  return {
    'emb.app_instance_id': appInstanceId,
    'browser.url.full': location.href,
    'user_agent.original': navigator.userAgent,
  };
}

// --- Web Vitals ---

function initWebVitals(): void {
  const report = (metric: Metric) => {
    post({
      'emb.type': 'ux.web_vital',
      'emb.web_vital.name': metric.name,
      'emb.web_vital.value': Math.round(metric.value),
      'emb.web_vital.delta': Math.round(metric.delta),
      'emb.web_vital.rating': metric.rating,
      'emb.web_vital.id': metric.id,
      'emb.web_vital.navigation_type': metric.navigationType,
      ...base(),
    });
  };

  onLCP(report);
  onFCP(report);
  onCLS(report);
  onTTFB(report);
}

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

// --- Document Load ---

function initDocumentLoad(): void {
  let retries = 0;
  const emit = () => {
    const nav = performance.getEntriesByType('navigation')[0] as
      | PerformanceNavigationTiming
      | undefined;
    if (!nav) return;
    if (nav.loadEventEnd === 0 && retries < 5) {
      retries++;
      setTimeout(emit, 100);
      return;
    }

    const paint = performance.getEntriesByType('paint');
    const fp = paint.find((e) => e.name === 'first-paint')?.startTime;
    const fcp = paint.find(
      (e) => e.name === 'first-contentful-paint',
    )?.startTime;

    post({
      'emb.type': 'ux.document_load',
      dom_interactive: Math.round(nav.domInteractive),
      dom_content_loaded_event_end: Math.round(nav.domContentLoadedEventEnd),
      load_event_end: Math.round(nav.loadEventEnd),
      redirect_duration: Math.round(nav.redirectEnd - nav.redirectStart),
      dns_duration: Math.round(nav.domainLookupEnd - nav.domainLookupStart),
      connect_duration: Math.round(nav.connectEnd - nav.connectStart),
      request_duration: Math.round(nav.responseStart - nav.requestStart),
      response_duration: Math.round(nav.responseEnd - nav.responseStart),
      first_paint: fp !== undefined ? Math.round(fp) : undefined,
      first_contentful_paint: fcp !== undefined ? Math.round(fcp) : undefined,
      ...base(),
    });

    const resources = performance.getEntriesByType(
      'resource',
    ) as EmbracePerformanceResourceTiming[];
    for (const r of resources) {
      const payload: EmbracePayload = {
        'emb.type': 'ux.resource_fetch',
        'url.full': r.name,
        'http.response.body.size': r.encodedBodySize,
        'http.response.size': r.transferSize,
        'http.response.decoded_body_size': r.decodedBodySize,
        duration: Math.round(r.duration),
        ...base(),
      };
      if (r.initiatorType) {
        payload['http.request.initiator_type'] = r.initiatorType;
      }
      if (r.deliveryType) {
        payload['http.response.delivery_type'] = r.deliveryType;
      }
      if (r.renderBlockingStatus) {
        payload['http.request.render_blocking_status'] = r.renderBlockingStatus;
      }

      const hasNoSizeData =
        r.transferSize === 0 &&
        r.decodedBodySize === 0 &&
        r.encodedBodySize === 0;
      const hasTimingData = r.fetchStart > 0 && r.responseEnd > 0;
      if (hasNoSizeData && hasTimingData) {
        payload['http.response.cors_opaque'] = 1;
      }

      post(payload);
    }
  };

  if (document.readyState === 'complete') {
    setTimeout(emit, 0);
  } else {
    window.addEventListener('load', () => setTimeout(emit, 0));
  }
}

// --- Exceptions ---

function initExceptions(): void {
  let handling = false;

  window.addEventListener('error', (e) => {
    if (handling) return;
    handling = true;
    try {
      const err = e.error;
      post({
        'emb.type': 'sys.exception',
        'emb.exception_handling': 'unhandled_error',
        'exception.message': e.message || '',
        'exception.stacktrace': err?.stack ?? '',
        'exception.type': err?.constructor?.name || typeof err || 'Error',
        'exception.name': err?.name ?? 'Error',
        ...base(),
      });
    } catch {
      /* prevent recursive error handling */
    }
    handling = false;
  });

  window.addEventListener('unhandledrejection', (e) => {
    if (handling) return;
    handling = true;
    try {
      let message: string;
      try {
        message =
          e.reason instanceof Error ? e.reason.message : String(e.reason);
      } catch {
        message = 'unserializable rejection reason';
      }
      const reason = e.reason;
      const isError = reason instanceof Error;
      post({
        'emb.type': 'sys.exception',
        'emb.exception_handling': 'unhandled_rejection',
        'exception.message': message,
        'exception.stacktrace': isError ? (reason.stack ?? '') : '',
        'exception.type': isError
          ? reason.constructor?.name || typeof reason
          : typeof reason,
        'exception.name': isError
          ? (reason.name ?? 'Error')
          : 'UnhandledRejection',
        ...base(),
      });
    } catch {
      /* prevent recursive error handling */
    }
    handling = false;
  });
}

// --- LoAF (Long Animation Frames) ---

interface LoafEntry {
  duration: number;
  blockingDuration: number;
  styleAndLayoutStart: number;
  renderStart: number;
  startTime: number;
  firstUIEventTimestamp: number;
}

function initLoaf(): void {
  if (
    typeof PerformanceObserver === 'undefined' ||
    !PerformanceObserver.supportedEntryTypes?.includes('long-animation-frame')
  ) {
    return;
  }

  let totalBlockingDuration = 0;
  let totalDuration = 0;
  let workDuration = 0;
  let totalStyleAndLayoutDuration = 0;
  let count = 0;
  let longestDuration = 0;
  let longestDurationExcludingFirst = 0;
  let isFirstEntry = true;

  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      const loaf = entry as unknown as LoafEntry;
      count++;
      totalDuration += loaf.duration;
      workDuration += loaf.renderStart
        ? loaf.renderStart - loaf.startTime
        : loaf.duration;

      if (loaf.styleAndLayoutStart) {
        totalStyleAndLayoutDuration += Math.max(
          0,
          loaf.startTime + loaf.duration - loaf.styleAndLayoutStart,
        );
      }

      if (loaf.duration > longestDuration) {
        longestDuration = loaf.duration;
      }

      if (isFirstEntry) {
        isFirstEntry = false;
      } else {
        if (loaf.duration > longestDurationExcludingFirst) {
          longestDurationExcludingFirst = loaf.duration;
        }
        if (loaf.firstUIEventTimestamp === 0) {
          totalBlockingDuration += loaf.blockingDuration;
        }
      }
    }
  });

  observer.observe({ type: 'long-animation-frame', buffered: true });

  const flush = () => {
    if (count === 0) return;

    let rating: 'good' | 'needs-improvement' | 'poor';
    if (totalBlockingDuration <= 200) rating = 'good';
    else if (totalBlockingDuration <= 600) rating = 'needs-improvement';
    else rating = 'poor';

    post({
      'emb.type': 'ux.web_vital',
      'emb.web_vital.name': 'TBD',
      'emb.web_vital.value': Math.round(totalBlockingDuration),
      'emb.web_vital.rating': rating,
      'emb.tbd.loaf_total_duration': Math.round(totalDuration),
      'emb.tbd.loaf_work_duration': Math.round(workDuration),
      'emb.tbd.loaf_style_and_layout_duration': Math.round(
        totalStyleAndLayoutDuration,
      ),
      'emb.tbd.loaf_count': count,
      'emb.tbd.loaf_longest_duration': Math.round(longestDuration),
      'emb.tbd.loaf_longest_duration_excluding_first': Math.round(
        longestDurationExcludingFirst,
      ),
      ...base(),
    });

    totalBlockingDuration = 0;
    totalDuration = 0;
    workDuration = 0;
    totalStyleAndLayoutDuration = 0;
    count = 0;
    longestDuration = 0;
    longestDurationExcludingFirst = 0;
  };

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') flush();
  });
  window.addEventListener('pagehide', flush);
}

// --- Clicks ---

function elementName(el: HTMLElement): string {
  const tag = el.tagName.toLowerCase();
  const className =
    el.className && typeof el.className === 'string'
      ? ` class="${el.className}"`
      : '';
  const innerText = (el.innerText || '').substring(0, 30);
  const ellipsis = (el.innerText || '').length > 30 ? '...' : '';
  return `<${tag}${className}>${innerText}${ellipsis}</${tag}>`;
}

function initClicks(): void {
  document.addEventListener('click', (e) => {
    const target = e.target as HTMLElement | null;
    if (!target?.tagName) return;
    post({
      'emb.type': 'ux.tap',
      'view.name': elementName(target),
      'tap.coords': `${Math.round(e.clientX)},${Math.round(e.clientY)}`,
      ...base(),
    });
  });
}

// --- Init ---

try {
  for (const fn of [
    initExceptions, // 1.25
    // initWebVitals, // 4.86
    initWebVitalsSimple, // 1.86 - no INP
    initDocumentLoad, // 2.1
    initLoaf, // 1.64
    initClicks, // .84
  ]) {
    try {
      fn();
    } catch {}
  }
} catch {}
