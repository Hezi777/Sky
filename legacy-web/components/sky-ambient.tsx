"use client";

import Image from "next/image";
import { motion, AnimatePresence } from "framer-motion";
import type { CloudState } from "@/lib/cloud-state";

const SKY_IMAGES: Record<CloudState, string> = {
  sleeping:   "/assets/sky/sky-sleeping.jpg",
  stretching: "/assets/sky/sky-stretching.jpg",
  happy:      "/assets/sky/sky-happy.jpg",
  confident:  "/assets/sky/sky-confident.jpg",
  droopy:     "/assets/sky/sky-droopy.jpg",
  calm:       "/assets/sky/sky-calm.jpg",
  hero:       "/assets/sky/sky-hero.jpg",
};

const HERO_FILTER = "saturate(0.7) brightness(0.9)";

export function SkyAmbient({ state }: { state: CloudState }) {
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute inset-x-0 top-0 z-0 overflow-hidden"
      style={{ height: "55vh" }}
    >
      <AnimatePresence mode="popLayout">
        <motion.div
          key={state}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.8 }}
          style={{
            position: "absolute",
            inset: 0,
            filter: state === "hero" ? HERO_FILTER : undefined,
            maskImage: "linear-gradient(to bottom, black 0%, black 40%, transparent 100%)",
            WebkitMaskImage: "linear-gradient(to bottom, black 0%, black 40%, transparent 100%)",
          }}
        >
          <Image
            src={SKY_IMAGES[state]}
            alt=""
            fill
            priority
            sizes="100vw"
            className="object-cover object-center"
            unoptimized
          />
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
