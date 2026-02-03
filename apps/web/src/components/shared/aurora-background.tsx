"use client";

import { motion } from "framer-motion";

/** Aurora-style gradient background - Web3/Crypto aesthetic */
export function AuroraBackground() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {/* Base gradient orbs */}
      <div className="absolute -top-40 -right-40 w-80 h-80 bg-credora-cyan/20 rounded-full blur-[100px]" />
      <div className="absolute top-1/2 -left-40 w-96 h-96 bg-credora-green/15 rounded-full blur-[120px]" />
      <div className="absolute -bottom-40 left-1/3 w-72 h-72 bg-credora-blue/10 rounded-full blur-[90px]" />
      {/* Animated orbs */}
      <motion.div
        className="absolute top-1/4 left-1/4 w-[500px] h-[500px] bg-credora-cyan/8 rounded-full blur-[100px]"
        animate={{
          x: [0, 30, 0],
          y: [0, -20, 0],
          scale: [1, 1.1, 1],
        }}
        transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] bg-credora-green/6 rounded-full blur-[80px]"
        animate={{
          x: [0, -25, 0],
          y: [0, 15, 0],
          scale: [1, 1.15, 1],
        }}
        transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
      />
      {/* Subtle grid overlay */}
      <div
        className="absolute inset-0 bg-grid-pattern opacity-30"
        aria-hidden
      />
    </div>
  );
}
