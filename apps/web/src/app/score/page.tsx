"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAccount } from "wagmi";
import { motion } from "framer-motion";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useCredora } from "@/hooks/use-credora";
import { useSubgraphScoreUpdates } from "@/hooks/use-subgraph";
import { ScoreGauge } from "@/components/dashboard/score-gauge";
import { TierBadge } from "@/components/dashboard/tier-badge";
import { ArrowLeft } from "lucide-react";

export default function ScorePage() {
  const router = useRouter();
  const { isConnected } = useAccount();
  const { address, hasSBT, score, tier, isLoading } = useCredora();
  const { scoreUpdates, isLoading: historyLoading } = useSubgraphScoreUpdates(20);

  useEffect(() => {
    if (!isConnected && typeof window !== "undefined") {
      router.replace("/");
    }
  }, [isConnected, router]);

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-20 text-center">
        <p className="text-muted-foreground">Connecting...</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 md:py-12">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <Link
          href="/dashboard"
          className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6"
        >
          <ArrowLeft size={16} />
          Back to Dashboard
        </Link>

        <h1 className="text-3xl font-bold mb-2">Score Details</h1>
        <p className="text-muted-foreground mb-8">
          Your credit score breakdown and update history
        </p>

        {!hasSBT ? (
          <Card className="glass">
            <CardContent className="py-16 text-center">
              <p className="text-muted-foreground mb-6">
                You haven&apos;t minted your Soulbound credit score yet.
              </p>
              <Link href="/dashboard">
                <Button>Mint SBT on Dashboard</Button>
              </Link>
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-6 lg:grid-cols-2">
            <Card className="glass">
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  Current Score
                  {tier && <TierBadge tierName={tier.name} />}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-col items-center gap-6">
                  <ScoreGauge
                    score={score ? Number(score.score) : 0}
                    size={220}
                  />
                  {score && (
                    <div className="text-center space-y-1">
                      <p className="text-sm text-muted-foreground">
                        Last updated:{" "}
                        {new Date(
                          Number(score.lastUpdated) * 1000
                        ).toLocaleString()}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        Data version: {Number(score.dataVersion)}
                      </p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            <Card className="glass">
              <CardHeader>
                <CardTitle>Scoring Factors</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Your score is calculated from:
                </p>
              </CardHeader>
              <CardContent>
                <ul className="space-y-4">
                  <li className="flex justify-between py-2 border-b border-border/40">
                    <span>Wallet Age</span>
                    <span className="text-muted-foreground">20% weight</span>
                  </li>
                  <li className="flex justify-between py-2 border-b border-border/40">
                    <span>Transaction Volume</span>
                    <span className="text-muted-foreground">25% weight</span>
                  </li>
                  <li className="flex justify-between py-2 border-b border-border/40">
                    <span>Repayment History</span>
                    <span className="text-muted-foreground">35% weight</span>
                  </li>
                  <li className="flex justify-between py-2">
                    <span>Protocol Diversity</span>
                    <span className="text-muted-foreground">20% weight</span>
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Score History */}
        <div className="mt-8">
          <Card className="glass">
            <CardHeader>
              <CardTitle>Score Update History</CardTitle>
              <p className="text-sm text-muted-foreground">
                From The Graph indexer
              </p>
            </CardHeader>
            <CardContent>
              {historyLoading ? (
                <p className="text-muted-foreground py-8 text-center">
                  Loading history...
                </p>
              ) : scoreUpdates.length === 0 ? (
                <p className="text-muted-foreground py-8 text-center">
                  No score updates yet
                </p>
              ) : (
                <div className="space-y-2">
                  {scoreUpdates.map((update: { id: string; oldScore: string; newScore: string; timestamp: string }) => (
                    <div
                      key={update.id}
                      className="flex items-center justify-between py-3 border-b border-border/40 last:border-0"
                    >
                      <span className="font-mono">
                        {update.oldScore} → {update.newScore}
                      </span>
                      <span className="text-sm text-muted-foreground">
                        {new Date(
                          parseInt(update.timestamp) * 1000
                        ).toLocaleString()}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </motion.div>
    </div>
  );
}
