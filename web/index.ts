import type { Metric } from 'web-vitals';
import { onCLS, onFCP, onLCP, onTTFB } from 'web-vitals';
import {
  base,
  initClicks,
  initDocumentLoad,
  initExceptions,
  initLoaf,
  post,
} from './embrace';

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

try {
  for (const fn of [
    initExceptions,
    initWebVitals,
    initDocumentLoad,
    initLoaf,
    initClicks,
  ]) {
    try {
      fn();
    } catch {}
  }
} catch {}
