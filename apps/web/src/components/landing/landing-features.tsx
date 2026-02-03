"use client";

import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Shield, Key, Database, TrendingUp, ShieldCheck } from "lucide-react";

const features = [
  {
    icon: Shield,
    title: "Soulbound Credit Scores",
    description:
      "Non-transferable ERC-721 tokens storing credit scores (0–1000). Your score travels with your identity, not your wallet balance.",
  },
  {
    icon: Key,
    title: "Permissioned Access",
    description:
      "Time-limited, quota-based permission system. You control who sees your score. Grant access to protocols, revoke anytime.",
  },
  {
    icon: Database,
    title: "Oracle System",
    description:
      "Signature-verified score updates with rate limiting. Aggregates on-chain data from multiple protocols via The Graph.",
  },
  {
    icon: TrendingUp,
    title: "Multi-Factor Scoring",
    description:
      "Wallet age (20%), transaction volume (25%), repayment history (35%), protocol diversity (20%). Transparent and manipulation-resistant.",
  },
  {
    icon: ShieldCheck,
    title: "Emergency Recovery",
    description:
      "7-day cooldown recovery mechanism for lost keys. Regain access to your Soulbound score safely.",
  },
];

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 },
};

export function LandingFeatures() {
  return (
    <div className="container mx-auto px-4">
      <motion.div
        className="text-center mb-16"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
      >
        <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold mb-4">
          Built for DeFi&apos;s Future
        </h2>
        <p className="text-muted-foreground max-w-2xl mx-auto text-sm sm:text-base">
          Credora creates decentralized credit infrastructure that bridges
          traditional lending concepts with Web3 transparency and composability.
        </p>
      </motion.div>

      <motion.div
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        variants={container}
        initial="hidden"
        whileInView="show"
        viewport={{ once: true, margin: "-50px" }}
      >
        {features.map((feature) => (
          <motion.div
            key={feature.title}
            variants={item}
            whileHover={{ y: -4 }}
            transition={{ duration: 0.2 }}
          >
            <Card className="h-full glass-card group">
              <CardHeader>
                <div className="w-12 h-12 rounded-xl bg-credora-cyan/10 flex items-center justify-center mb-3 group-hover:bg-credora-cyan/15 transition-colors">
                  <feature.icon className="w-6 h-6 text-credora-cyan" />
                </div>
                <CardTitle className="text-lg">{feature.title}</CardTitle>
                <CardDescription className="text-muted-foreground/90">{feature.description}</CardDescription>
              </CardHeader>
            </Card>
          </motion.div>
        ))}
      </motion.div>
    </div>
  );
}
