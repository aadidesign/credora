"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { motion } from "framer-motion";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useCredora } from "@/hooks/use-credora";
import { GrantAccessModal } from "@/components/permissions/grant-access-modal";
import { KeyRound, Plus, ArrowLeft, Trash2, Wallet } from "lucide-react";

export default function PermissionsPage() {
  const { isConnected } = useAccount();
  const {
    permissions,
    isLoading,
    refetch,
    client,
    hasSigner,
  } = useCredora();
  const [modalOpen, setModalOpen] = useState(false);

  const handleGrant = async (
    protocol: string,
    _durationDays: number,
    maxRequests: number
  ) => {
    const duration = _durationDays * 24 * 60 * 60; // seconds
    await client.grantAccess({
      protocol,
      duration,
      maxRequests,
    });
    refetch();
  };

  const handleRevoke = async (protocol: string) => {
    await client.revokeAccess(protocol);
    refetch();
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
          <h1 className="text-2xl font-bold mb-2">Permissions</h1>
          <p className="text-muted-foreground mb-8">
            Connect your wallet to manage protocol access permissions.
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
        <Link
          href="/dashboard"
          className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6"
        >
          <ArrowLeft size={16} />
          Back to Dashboard
        </Link>

        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
          <div>
            <h1 className="text-3xl font-bold mb-2">Permissions</h1>
            <p className="text-muted-foreground">
              Manage which protocols can read your credit score
            </p>
          </div>
          <Button
            onClick={() => setModalOpen(true)}
            disabled={!hasSigner}
          >
            <Plus size={18} />
            Grant Access
          </Button>
        </div>

        <Card className="glass-card">
          <CardHeader>
            <CardTitle>Active Permissions</CardTitle>
            <p className="text-sm text-muted-foreground">
              Protocols you&apos;ve granted access to read your score
            </p>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <p className="text-muted-foreground py-8 text-center">
                Loading...
              </p>
            ) : permissions.length === 0 ? (
              <div className="py-16 text-center">
                <KeyRound className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-50" />
                <p className="text-muted-foreground mb-6">
                  No active permissions yet
                </p>
                <Button onClick={() => setModalOpen(true)} disabled={!hasSigner}>
                  <Plus size={18} />
                  Grant Your First Access
                </Button>
              </div>
            ) : (
              <div className="space-y-2">
                {permissions.map((perm) => {
                  const isExpired = Number(perm.expiresAt) * 1000 < Date.now();
                  return (
                    <div
                      key={perm.permissionHash}
                      className="flex items-center justify-between py-4 border-b border-border/40 last:border-0"
                    >
                      <div>
                        <p className="font-mono text-sm">
                          {perm.protocol.slice(0, 6)}...
                          {perm.protocol.slice(-4)}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          Expires:{" "}
                          {new Date(
                            Number(perm.expiresAt) * 1000
                          ).toLocaleDateString()}
                          {" · "}
                          {Number(perm.usedRequests)}/{Number(perm.maxRequests)}{" "}
                          used
                        </p>
                      </div>
                      {perm.isActive && !isExpired && (
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleRevoke(perm.protocol)}
                          disabled={!hasSigner}
                        >
                          <Trash2 size={14} />
                          Revoke
                        </Button>
                      )}
                      {isExpired && (
                        <span className="text-xs text-muted-foreground">
                          Expired
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>
      </motion.div>

      <GrantAccessModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onGrant={handleGrant}
      />
    </div>
  );
}
