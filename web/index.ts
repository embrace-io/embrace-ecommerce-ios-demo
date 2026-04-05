interface EmbracePayload {
  type: string;
  severity?: string;
  [key: string]: string | number | undefined;
}

function post(payload: EmbracePayload): void {
  try {
    console.debug('Embrace payload:', payload);
    window.webkit.messageHandlers.embrace.postMessage(payload);
  } catch {
    // Not in a WKWebView — silently ignore
  }
}

// 1. Document load timing
function trackLoadTiming(): void {
  const onLoad = () => {
    const t = performance.timing || {};
    const navEntry =
      (performance.getEntriesByType?.(
        'navigation',
      )[0] as PerformanceNavigationTiming) || {};

    const domContentLoaded =
      navEntry.domContentLoadedEventEnd ||
      t.domContentLoadedEventEnd - t.navigationStart;
    const loadComplete =
      navEntry.loadEventEnd || t.loadEventEnd - t.navigationStart;
    const ttfb = navEntry.responseStart || t.responseStart - t.navigationStart;
    const domInteractive =
      navEntry.domInteractive || t.domInteractive - t.navigationStart;

    post({
      type: 'doc_load',
      ttfb_ms: Math.round(ttfb),
      dom_interactive_ms: Math.round(domInteractive),
      dom_content_loaded_ms: Math.round(domContentLoaded),
      load_complete_ms: Math.round(loadComplete),
      url: document.location.href,
    });

    const status = document.getElementById('status');
    if (status) {
      status.textContent = `Load: ${Math.round(loadComplete)}ms | TTFB: ${Math.round(ttfb)}ms`;
    }
  };

  if (document.readyState === 'complete') {
    setTimeout(onLoad, 0);
  } else {
    window.addEventListener('load', () => setTimeout(onLoad, 0));
  }
}

// 2. Empty content detection
function trackEmptyContent(): void {
  setTimeout(() => {
    const textLength = (document.body.innerText || '').trim().length;
    const imgCount = document.body.querySelectorAll('img').length;
    if (textLength < 50 && imgCount === 0) {
      post({
        type: 'empty_content',
        severity: 'error',
        text_length: textLength,
        img_count: imgCount,
        url: document.location.href,
      });
    }
  }, 2000);
}

// 3. Unhandled errors
function trackErrors(): void {
  window.addEventListener('error', (e) => {
    post({
      type: 'js_error',
      severity: 'error',
      message: e.message || 'unknown',
      filename: e.filename || '',
      lineno: e.lineno || 0,
      colno: e.colno || 0,
    });
  });
}

// 4. Resource load failures (images, scripts, etc.)
function trackResourceErrors(): void {
  document.addEventListener(
    'error',
    (e) => {
      const target = e.target as HTMLElement;
      if (target?.tagName) {
        post({
          type: 'resource_error',
          severity: 'warning',
          tag: target.tagName,
          src:
            (target as HTMLImageElement).src ||
            (target as HTMLLinkElement).href ||
            '',
        });
      }
    },
    true,
  );
}

// 5. Click tracking
function trackClicks(): void {
  document.addEventListener('click', (e) => {
    const target = e.target as HTMLElement;
    post({
      type: 'user_interaction',
      action: 'click',
      tag: target.tagName.toLowerCase(),
      text: target.textContent?.slice(0, 50) ?? '',
      x: Math.round(e.clientX),
      y: Math.round(e.clientY),
    });
  });
}

// 6. Content visibility
function trackVisibility(): void {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          const el = entry.target as HTMLElement;
          post({
            type: 'content_visible',
            tag: el.tagName.toLowerCase(),
            text: el.textContent?.slice(0, 50) ?? '',
          });
          observer.unobserve(el);
        }
      }
    },
    { threshold: 0.5 },
  );

  for (const el of document.querySelectorAll('h1, img, .status')) {
    observer.observe(el);
  }
}

trackLoadTiming();
trackEmptyContent();
trackErrors();
trackResourceErrors();
trackClicks();
trackVisibility();
