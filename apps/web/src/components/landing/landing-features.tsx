"use client";

import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Shield, Key, Database, TrendingUp } from "lucide-react";

const features = [
  {
    icon: Shield,
    title: "Soulbound Credit Scores",
    description:
      "Non-transferable ERC-721 tokens that represent your on-chain creditworthiness. Your score travels with your identity, not your wallet balance.",
  },
  {
    icon: Key,
    title: "Permissioned Access",
    description:
      "You control who sees your score. Grant time-limited, quota-based access to lending protocols. Revoke anytime.",
  },
  {
    icon: Database,
    title: "Oracle System",
    description:
      "Signature-verified score updates with rate limiting. Aggregates data from multiple protocols via The Graph for accurate scoring.",
  },
  {
    icon: TrendingUp,
    title: "Multi-Factor Scoring",
    description:
      "Wallet age, transaction volume, repayment history, and protocol diversity. Transparent, composable, and manipulation-resistant.",
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
        <h2 className="text-3xl md:text-4xl font-bold mb-4">
          Built for DeFi&apos;s Future
        </h2>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Credora creates decentralized credit infrastructure that bridges
          traditional lending concepts with Web3 transparency and composability.
        </p>
      </motion.div>

      <motion.div
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
        variants={container}
        initial="hidden"
        whileInView="show"
        viewport={{ once: true, margin: "-50px" }}
      >
        {features.map((feature) => (
          <motion.div key={feature.title} variants={item}>
            <Card className="h-full glass hover:border-credora-cyan/30 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 rounded-lg bg-credora-cyan/10 flex items-center justify-center mb-2">
                  <feature.icon className="w-6 h-6 text-credora-cyan" />
                </div>
                <CardTitle className="text-lg">{feature.title}</CardTitle>
                <CardDescription>{feature.description}</CardDescription>
              </CardHeader>
            </Card>
          </motion.div>
        ))}
      </motion.div>
    </div>
  );
}
