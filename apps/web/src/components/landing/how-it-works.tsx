"use client";

import { motion } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import { BadgeDollarSign, RefreshCw, KeyRound } from "lucide-react";

const steps = [
  {
    icon: BadgeDollarSign,
    title: "Mint SBT",
    description: "Connect your wallet and mint your Soulbound credit score NFT. Your score is calculated from on-chain behavior.",
  },
  {
    icon: RefreshCw,
    title: "Score Updates",
    description: "Oracles aggregate data via The Graph and update scores. Rate limiting: minimum 1-hour interval between updates.",
  },
  {
    icon: KeyRound,
    title: "Grant Access",
    description: "Grant lending protocols permission to read your score. Set duration and max requests. Revoke anytime.",
  },
];

export function HowItWorks() {
  return (
    <div className="container mx-auto px-4">
      <motion.div
        className="text-center mb-16"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
      >
        <h2 id="how-it-works" className="text-2xl sm:text-3xl md:text-4xl font-bold mb-4">
          How It Works
        </h2>
        <p className="text-muted-foreground max-w-2xl mx-auto text-sm sm:text-base">
          Three simple steps to unlock uncollateralized lending with your
          on-chain reputation.
        </p>
      </motion.div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {steps.map((step, index) => (
          <motion.div
            key={step.title}
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: index * 0.1 }}
            className="relative"
          >
            <Card className="h-full glass-card border-credora-cyan/20">
              <CardContent className="pt-8 pb-8">
                <div className="flex items-center gap-4 mb-4">
                  <div className="w-14 h-14 rounded-full bg-credora-cyan/20 flex items-center justify-center text-credora-cyan font-bold text-xl">
                    {index + 1}
                  </div>
                  <div className="w-12 h-12 rounded-lg bg-credora-cyan/10 flex items-center justify-center">
                    <step.icon className="w-6 h-6 text-credora-cyan" />
                  </div>
                </div>
                <h3 className="text-xl font-semibold mb-2">{step.title}</h3>
                <p className="text-muted-foreground">{step.description}</p>
              </CardContent>
            </Card>
            {index < steps.length - 1 && (
              <div className="hidden md:block absolute top-1/2 -right-4 w-8 h-0.5 bg-credora-cyan/30 -translate-y-1/2" />
            )}
          </motion.div>
        ))}
      </div>
    </div>
  );
}
