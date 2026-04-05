import type { Metric } from 'web-vitals';
import { onCLS, onFCP, onINP, onLCP, onTTFB } from 'web-vitals';

interface EmbracePayload {
  'emb.type': string;
  'emb.webview_id': string;
  [key: string]: string | number | undefined;
}

const pageViewId =
  typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;

function post(payload: EmbracePayload): void {
  try {
    console.log(payload);
    window.webkit.messageHandlers.embrace.postMessage(payload);
  } catch {
    // Not in a WKWebView
  }
}

function base(): Pick<EmbracePayload, 'emb.webview_id' | 'browser.url.full'> {
  return { 'emb.webview_id': pageViewId, 'browser.url.full': location.href };
}

// --- Web Vitals ---

function initWebVitals(): void {
  const report = (metric: Metric) => {
    post({
      'emb.type': 'ux.web_vital',
      'emb.web_vital.name': metric.name,
      'emb.web_vital.value': metric.value,
      'emb.web_vital.delta': metric.delta,
      'emb.web_vital.rating': metric.rating,
      'emb.web_vital.id': metric.id,
      'emb.web_vital.navigation_type': metric.navigationType,
      ...base(),
    });
  };

  onLCP(report);
  onFCP(report);
  onINP(report);
  onCLS(report);
  onTTFB(report);
}

// --- Document Load ---

function initDocumentLoad(): void {
  const emit = () => {
    const nav = performance.getEntriesByType('navigation')[0] as
      | PerformanceNavigationTiming
      | undefined;
    if (!nav) return;

    const paint = performance.getEntriesByType('paint');
    const fp = paint.find((e) => e.name === 'first-paint')?.startTime;
    const fcp = paint.find(
      (e) => e.name === 'first-contentful-paint',
    )?.startTime;

    post({
      'emb.type': 'ux.document_load',
      'user_agent.original': navigator.userAgent,
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
    ) as PerformanceResourceTiming[];
    for (const r of resources) {
      post({
        'emb.type': 'ux.resource_fetch',
        'url.full': r.name,
        'http.request.initiator_type': r.initiatorType,
        'http.response.delivery_type':
          (r as unknown as Record<string, string>).deliveryType ?? '',
        'http.request.render_blocking_status':
          (r as unknown as Record<string, string>).renderBlockingStatus ?? '',
        'http.response.body.size': r.transferSize,
        'http.response.decoded_body_size': r.decodedBodySize,
        duration: Math.round(r.duration),
        ...base(),
      });
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
  window.addEventListener('error', (e) => {
    post({
      'emb.type': 'sys.exception',
      'emb.exception_handling': 'global_exception',
      'exception.message': e.message || 'unknown',
      'exception.stacktrace': e.error?.stack ?? '',
      'exception.type': e.error?.name ?? 'Error',
      ...base(),
    });
  });

  window.addEventListener('unhandledrejection', (e) => {
    const err =
      e.reason instanceof Error
        ? e.reason
        : { message: String(e.reason), stack: '', name: 'UnhandledRejection' };
    post({
      'emb.type': 'sys.exception',
      'emb.exception_handling': 'promise_rejection',
      'exception.message': err.message,
      'exception.stacktrace': err.stack ?? '',
      'exception.type': err.name ?? 'Error',
      ...base(),
    });
  });
}

// --- LoAF (Long Animation Frames) ---

interface LoafEntry {
  duration: number;
  blockingDuration: number;
  styleAndLayoutStart: number;
  startTime: number;
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
  let totalStyleAndLayoutDuration = 0;
  let count = 0;
  let longestDuration = 0;

  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      const loaf = entry as unknown as LoafEntry;
      totalBlockingDuration += loaf.blockingDuration;
      totalDuration += loaf.duration;
      count++;
      if (loaf.duration > longestDuration) {
        longestDuration = loaf.duration;
      }
      const styleDuration =
        loaf.duration - (loaf.styleAndLayoutStart - loaf.startTime);
      if (styleDuration > 0) {
        totalStyleAndLayoutDuration += styleDuration;
      }
    }
  });

  observer.observe({ type: 'long-animation-frame', buffered: true });

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState !== 'hidden' || count === 0) return;

    let rating: 'good' | 'needs-improvement' | 'poor';
    if (totalBlockingDuration <= 200) rating = 'good';
    else if (totalBlockingDuration <= 600) rating = 'needs-improvement';
    else rating = 'poor';

    post({
      'emb.type': 'ux.web_vital',
      'emb.web_vital.name': 'TBD',
      'emb.web_vital.value': totalBlockingDuration,
      'emb.web_vital.rating': rating,
      'emb.tbd.loaf_total_duration': Math.round(totalDuration),
      'emb.tbd.loaf_style_and_layout_duration': Math.round(
        totalStyleAndLayoutDuration,
      ),
      'emb.tbd.loaf_count': count,
      'emb.tbd.loaf_longest_duration': Math.round(longestDuration),
      ...base(),
    });
  });
}

// --- Clicks ---

function elementName(el: HTMLElement): string {
  const tag = el.tagName.toLowerCase();
  if (el.id) return `${tag}#${el.id}`;
  if (el.className && typeof el.className === 'string') {
    const cls = el.className.trim().split(/\s+/)[0];
    if (cls) return `${tag}.${cls}`;
  }
  const text = el.textContent?.trim().slice(0, 30);
  if (text) return `${tag} "${text}"`;
  return tag;
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

initWebVitals();
initDocumentLoad();
initExceptions();
initLoaf();
initClicks();
