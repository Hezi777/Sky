"use client";

import { animate, motion, useMotionValue, useReducedMotion, useTransform } from "framer-motion";
import { useEffect } from "react";

export function AnimatedNumber({
  value,
  format,
  className,
  duration = 1,
}: {
  value: number;
  format: (value: number) => string;
  className?: string;
  duration?: number;
}) {
  const reducedMotion = useReducedMotion();
  const motionValue = useMotionValue(reducedMotion ? value : 0);
  const formatted = useTransform(motionValue, format);

  useEffect(() => {
    if (reducedMotion) {
      motionValue.set(value);
      return;
    }

    const controls = animate(motionValue, value, {
      duration,
      ease: [0.22, 1, 0.36, 1],
    });

    return controls.stop;
  }, [duration, motionValue, reducedMotion, value]);

  return <motion.span className={className}>{formatted}</motion.span>;
}
