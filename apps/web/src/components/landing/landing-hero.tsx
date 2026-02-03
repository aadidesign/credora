"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { ArrowRight } from "lucide-react";

export function LandingHero() {
  return (
    <div className="container relative mx-auto px-4 sm:px-6 text-center">
      <motion.h1
        className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-bold tracking-tight mb-6 sm:mb-8"
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      >
        <span className="block bg-gradient-to-r from-credora-cyan via-credora-green to-credora-cyan bg-clip-text text-transparent">
          Decentralized Credit
        </span>
        <span className="block text-foreground mt-2">Scoring for Web3</span>
      </motion.h1>
      <motion.p
        className="text-base sm:text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto mb-8 sm:mb-10 px-2"
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.15, ease: [0.22, 1, 0.36, 1] }}
      >
        Trustless, on-chain credit scoring using Soulbound Tokens. Enable
        uncollateralized lending at scale with privacy-preserving, composable
        credit scores.
      </motion.p>
      <motion.div
        className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center"
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.25, ease: [0.22, 1, 0.36, 1] }}
      >
        <Link
          href="/dashboard"
          className={cn(
            buttonVariants({ size: "xl" }),
            "shadow-glow glow-cyan-sm hover:glow-cyan w-full sm:w-auto inline-flex group"
          )}
        >
          Launch App
          <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
        </Link>
        <Link
          href="#how-it-works"
          className={cn(
            buttonVariants({ variant: "outline", size: "xl" }),
            "w-full sm:w-auto inline-flex border-white/20 hover:border-credora-cyan/50"
          )}
        >
          How it Works
        </Link>
      </motion.div>
    </div>
  );
}
