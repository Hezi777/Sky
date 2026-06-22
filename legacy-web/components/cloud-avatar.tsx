"use client";

import { useState } from "react";
import Image from "next/image";
import { AnimatePresence, motion } from "framer-motion";

import { CLOUD_ASSET_MAP, type CloudState } from "@/lib/cloud-state";

const SIZES = { sm: 48, md: 96, lg: 160, hero: 280 } as const;

interface CloudAvatarProps {
  state: CloudState;
  size?: "sm" | "md" | "lg" | "hero";
  className?: string;
}

export function CloudAvatar({ state, size = "md", className }: CloudAvatarProps) {
  const px = SIZES[size];
  const [errorSrc, setErrorSrc] = useState<string | null>(null);
  const src = errorSrc ?? CLOUD_ASSET_MAP[state];

  return (
    <div className={className} style={{ width: px, height: px, position: "relative" }}>
      <motion.div
        initial={{ opacity: 0, scale: 0.85, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.45, ease: "easeOut" }}
        style={{ width: px, height: px, position: "relative" }}
      >
        <motion.div
          animate={{ y: [0, -6, 0] }}
          transition={{ duration: 3, ease: "easeInOut", repeat: Infinity }}
          style={{ width: px, height: px, position: "relative" }}
        >
          <AnimatePresence mode="popLayout">
            <motion.div
              key={src}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.3 }}
              style={{ position: "absolute", inset: 0 }}
            >
              <Image
                src={src}
                alt="Sky cloud avatar"
                width={px}
                height={px}
                priority
                onError={() => {
                  if (!errorSrc) setErrorSrc(CLOUD_ASSET_MAP.hero);
                }}
              />
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </motion.div>
    </div>
  );
}
