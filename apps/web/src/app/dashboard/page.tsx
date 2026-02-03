"use client";

import { useAccount } from "wagmi";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useCredora } from "@/hooks/use-credora";
import { ScoreGauge } from "@/components/dashboard/score-gauge";
import { TierBadge } from "@/components/dashboard/tier-badge";
import { ActionCard } from "@/components/dashboard/action-card";
import { useSubgraphScoreUpdates } from "@/hooks/use-subgraph";
import { BadgeDollarSign, KeyRound, ArrowRight, ExternalLink, Wallet } from "lucide-react";

export default function DashboardPage() {
  const router = useRouter();
  const { isConnected } = useAccount();
  const {
    address,
    hasSBT,
    score,
    tier,
    permissions,
    isLoading,
    refetch,
    client,
    hasSigner,
  } = useCredora();
  const { scoreUpdates } = useSubgraphScoreUpdates(5);

  const handleMintSBT = async () => {
    if (!hasSigner) return;
    try {
      const result = await client.mintSBT();
      if (result.success) {
        refetch();
      }
    } catch (err) {
      console.error("Mint failed:", err);
    }
  };

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-20">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-md mx-auto text-center"
        >
          <Wallet className="w-16 h-16 text-muted-foreground mx-auto mb-6 opacity-50" />
          <h1 className="text-2xl font-bold mb-2">Dashboard</h1>
          <p className="text-muted-foreground mb-8">
            Connect your wallet to view your credit score and manage permissions.
          </p>
          <ConnectButton />
        </motion.div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 sm:px-6 py-6 sm:py-8 md:py-12">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <h1 className="text-3xl font-bold mb-2">Dashboard</h1>
        <p className="text-muted-foreground mb-8">
          {address && (
            <span className="font-mono text-sm">
              {address.slice(0, 6)}...{address.slice(-4)}
            </span>
          )}
        </p>

        {isLoading && !score ? (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <Card className="glass-card h-80">
              <div className="h-full flex items-center justify-center">
                <div className="animate-pulse flex flex-col items-center gap-4">
                  <div className="w-32 h-32 rounded-full bg-muted/50" />
                  <div className="h-8 w-16 bg-muted/50 rounded" />
                </div>
              </div>
            </Card>
            <Card className="glass-card h-80 animate-pulse" />
            <Card className="glass-card h-80 animate-pulse" />
          </div>
        ) : (
          <div className="grid gap-6 lg:grid-cols-3">
            {/* Score Card */}
            <Card className="lg:col-span-2 glass-card">
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  Credit Score
                  {tier && <TierBadge tierName={tier.name} />}
                </CardTitle>
                <p className="text-sm text-muted-foreground">
                  {hasSBT
                    ? "Your on-chain credit score (0-1000)"
                    : "Mint your Soulbound credit score to get started"}
                </p>
              </CardHeader>
              <CardContent>
                <div className="flex flex-col md:flex-row items-center gap-8">
                  <ScoreGauge
                    score={hasSBT && score ? Number(score.score) : 0}
                    size={180}
                  />
                  <div className="flex-1 space-y-2">
                    {hasSBT && score && (
                      <>
                        <p className="text-muted-foreground">
                          Last updated:{" "}
                          {new Date(
                            Number(score.lastUpdated) * 1000
                          ).toLocaleDateString()}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          Updates: {Number(score.updateCount)}
                        </p>
                      </>
                    )}
                    {!hasSBT && (
                      <p className="text-muted-foreground">
                        Mint your SBT to receive a credit score based on your
                        on-chain activity.
                      </p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Quick Actions */}
            <div className="space-y-4">
              {!hasSBT && (
                <ActionCard
                  title="Mint SBT"
                  description="Create your Soulbound credit score NFT"
                  icon={BadgeDollarSign}
                  onAction={handleMintSBT}
                  actionLabel="Mint SBT"
                  disabled={!hasSigner}
                />
              )}
              <ActionCard
                title="Grant Access"
                description="Allow a protocol to read your score"
                icon={KeyRound}
                onAction={() => router.push("/permissions")}
                actionLabel="Manage Permissions"
              />
              <Link href="/score">
                <Button variant="outline" className="w-full">
                  View Score Details
                  <ArrowRight size={16} />
                </Button>
              </Link>
            </div>
          </div>
        )}

        {/* Permissions Preview */}
        {permissions.length > 0 && (
          <motion.div
            className="mt-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            <Card className="glass-card">
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  Active Permissions
                  <Link href="/permissions">
                    <Button variant="ghost" size="sm">
                      View All
                      <ExternalLink size={14} />
                    </Button>
                  </Link>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {permissions.slice(0, 3).map((perm, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between py-2 border-b border-border/40 last:border-0"
                    >
                      <span className="font-mono text-sm">
                        {perm.protocol.slice(0, 6)}...{perm.protocol.slice(-4)}
                      </span>
                      <span className="text-sm text-muted-foreground">
                        {Number(perm.usedRequests)}/{Number(perm.maxRequests)} used
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {/* Recent Activity */}
        {scoreUpdates.length > 0 && (
          <motion.div
            className="mt-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
          >
            <Card className="glass-card">
              <CardHeader>
                <CardTitle>Recent Score Updates</CardTitle>
                <p className="text-sm text-muted-foreground">
                  History from The Graph
                </p>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {scoreUpdates.map((update: { id: string; oldScore: string; newScore: string; timestamp: string }) => (
                    <div
                      key={update.id}
                      className="flex items-center justify-between py-2 border-b border-border/40 last:border-0"
                    >
                      <span className="text-sm">
                        {update.oldScore} → {update.newScore}
                      </span>
                      <span className="text-sm text-muted-foreground">
                        {new Date(parseInt(update.timestamp) * 1000).toLocaleDateString()}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {!hasSBT && !isLoading && (
          <motion.div
            className="mt-12 text-center"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
          >
            <p className="text-muted-foreground mb-4">
              Get started by minting your Soulbound credit score
            </p>
            <Button onClick={handleMintSBT} disabled={!hasSigner} size="lg">
              <BadgeDollarSign size={18} />
              Mint Your Credit Score SBT
            </Button>
          </motion.div>
        )}
      </motion.div>
    </div>
  );
}
