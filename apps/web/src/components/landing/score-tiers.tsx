"use client";

import { motion } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import { SCORE_TIERS } from "@credora/sdk";

const tierColors: Record<string, string> = {
  Newcomer: "from-gray-500/20 to-gray-600/10 border-gray-500/30",
  Established: "from-blue-500/20 to-blue-600/10 border-blue-500/30",
  Trusted: "from-credora-cyan/20 to-credora-cyan/10 border-credora-cyan/30",
  Prime: "from-credora-green/20 to-credora-green/10 border-credora-green/30",
};

export function ScoreTiers() {
  return (
    <div className="container mx-auto px-4">
      <motion.div
        className="text-center mb-16"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
      >
        <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold mb-4">Score Tiers</h2>
        <p className="text-muted-foreground max-w-2xl mx-auto text-sm sm:text-base">
          Your credit score (0–1000) maps to a tier. Higher tiers unlock better
          lending terms across integrated protocols.
        </p>
      </motion.div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {SCORE_TIERS.map((tier, index) => (
          <motion.div
            key={tier.name}
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.4, delay: index * 0.08 }}
          >
            <Card
              className={`h-full glass bg-gradient-to-br ${tierColors[tier.name] || "from-muted to-muted/50"} border`}
            >
              <CardContent className="pt-6 pb-6">
                <div className="text-sm font-mono text-muted-foreground mb-1">
                  {tier.minScore} – {tier.maxScore}
                </div>
                <h3 className="text-xl font-bold mb-2">{tier.name}</h3>
                <p className="text-sm text-muted-foreground">
                  {tier.description}
                </p>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
