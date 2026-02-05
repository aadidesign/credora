"use client";

import { useState, useEffect, ComponentType } from "react";

/**
 * Hook for lazy loading components with intersection observer
 * Useful for charts and heavy components below the fold
 */
export function useLazyComponent<T extends ComponentType<unknown>>(
  importFn: () => Promise<{ default: T }>,
  options?: IntersectionObserverInit
) {
  const [Component, setComponent] = useState<T | null>(null);
  const [ref, setRef] = useState<HTMLDivElement | null>(null);
  const [isIntersecting, setIsIntersecting] = useState(false);

  useEffect(() => {
    if (!ref) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsIntersecting(true);
          observer.disconnect();
        }
      },
      { threshold: 0.1, ...options }
    );

    observer.observe(ref);
    return () => observer.disconnect();
  }, [ref, options]);

  useEffect(() => {
    if (isIntersecting && !Component) {
      importFn().then((mod) => setComponent(() => mod.default));
    }
  }, [isIntersecting, Component, importFn]);

  return { Component, ref: setRef, isLoading: isIntersecting && !Component };
}
