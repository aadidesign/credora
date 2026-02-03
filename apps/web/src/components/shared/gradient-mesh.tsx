"use client";

import { motion } from "framer-motion";

/** Enhanced gradient mesh - Web3 crypto aesthetic */
export function GradientMesh() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      <div className="absolute -top-1/2 -left-1/2 w-full h-full bg-credora-cyan/25 rounded-full blur-3xl" />
      <div className="absolute top-1/2 -right-1/2 w-full h-full bg-credora-green/12 rounded-full blur-3xl" />
      <div className="absolute -bottom-1/2 left-1/3 w-1/2 h-full bg-credora-blue/12 rounded-full blur-3xl" />
      <motion.div
        className="absolute top-0 left-1/2 w-[600px] h-[600px] bg-credora-cyan/8 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2"
        animate={{
          scale: [1, 1.15, 1],
          opacity: [0.4, 0.6, 0.4],
        }}
        transition={{
          duration: 8,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      />
      <motion.div
        className="absolute bottom-0 right-1/4 w-[400px] h-[400px] bg-credora-green/5 rounded-full blur-3xl"
        animate={{
          scale: [1, 1.1, 1],
          opacity: [0.3, 0.5, 0.3],
        }}
        transition={{
          duration: 10,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      />
    </div>
  );
}
