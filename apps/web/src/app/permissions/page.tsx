"use client";

import { useState, useMemo } from "react";
import { useAccount } from "wagmi";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import dynamic from "next/dynamic";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button, toast, NoWalletConnected, NoPermissions, NoResults } from "@/components/ui";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useCredora } from "@/hooks/use-credora";
import { useDebounce } from "@/hooks";
import { GrantAccessModal, PermissionFilters, PermissionCard, type PermissionStatus } from "@/components/permissions";
import { Plus, ArrowLeft } from "lucide-react";

// Lazy load chart
const PermissionsChart = dynamic(
  () => import("@/components/charts/permissions-chart").then((m) => m.PermissionsChart),
  { ssr: false, loading: () => <div className="h-[250px] animate-pulse bg-muted/20 rounded-lg" /> }
);

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
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<PermissionStatus>("all");
  const debouncedSearch = useDebounce(search, 300);

  // Filter permissions
  const filteredPermissions = useMemo(() => {
    const now = Math.floor(Date.now() / 1000);
    return permissions.filter((perm) => {
      // Search filter
      if (debouncedSearch && !perm.protocol.toLowerCase().includes(debouncedSearch.toLowerCase())) {
        return false;
      }
      // Status filter
      const isExpired = Number(perm.expiresAt) < now;
      const status = !perm.isActive ? "revoked" : isExpired ? "expired" : "active";
      if (statusFilter !== "all" && status !== statusFilter) {
        return false;
      }
      return true;
    });
  }, [permissions, debouncedSearch, statusFilter]);

  // Stats for chart
  const stats = useMemo(() => {
    const now = Math.floor(Date.now() / 1000);
    let active = 0, expired = 0, revoked = 0;
    permissions.forEach((perm) => {
      if (!perm.isActive) revoked++;
      else if (Number(perm.expiresAt) < now) expired++;
      else active++;
    });
    return { active, expired, revoked };
  }, [permissions]);

  const handleGrant = async (
    protocol: string,
    _durationDays: number,
    maxRequests: number
  ) => {
    try {
      toast.loading("Granting access...");
      const duration = _durationDays * 24 * 60 * 60;
      await client.grantAccess({ protocol, duration, maxRequests });
      toast.success("Access granted successfully!");
      refetch();
    } catch (err) {
      console.error(err);
      toast.error("Failed to grant access");
    }
  };

  const handleRevoke = async (protocol: string) => {
    try {
      toast.loading("Revoking access...");
      await client.revokeAccess(protocol);
      toast.success("Access revoked");
      refetch();
    } catch (err) {
      console.error(err);
      toast.error("Failed to revoke access");
    }
  };

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-20">
        <NoWalletConnected />
        <div className="flex justify-center mt-6">
          <ConnectButton />
        </div>
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

        {/* Stats Chart */}
        {permissions.length > 0 && (
          <div className="mb-8">
            <PermissionsChart
              activeCount={stats.active}
              expiredCount={stats.expired}
              revokedCount={stats.revoked}
            />
          </div>
        )}

        {/* Filters */}
        {permissions.length > 0 && (
          <PermissionFilters
            onSearchChange={setSearch}
            onStatusChange={setStatusFilter}
            activeStatus={statusFilter}
            className="mb-6"
          />
        )}

        {/* Permissions List */}
        {isLoading ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {[1, 2, 3].map((i) => (
              <Card key={i} className="glass-card h-64 animate-pulse" />
            ))}
          </div>
        ) : permissions.length === 0 ? (
          <NoPermissions />
        ) : filteredPermissions.length === 0 ? (
          <NoResults />
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <AnimatePresence mode="popLayout">
              {filteredPermissions.map((perm) => (
                <PermissionCard
                  key={perm.permissionHash}
                  permission={{
                    id: perm.permissionHash,
                    protocol: perm.protocol,
                    grantedAt: Number(perm.grantedAt || 0),
                    expiresAt: Number(perm.expiresAt),
                    maxRequests: Number(perm.maxRequests),
                    usedRequests: Number(perm.usedRequests),
                    isActive: perm.isActive,
                    permissionHash: perm.permissionHash,
                  }}
                  onRevoke={
                    perm.isActive && Number(perm.expiresAt) * 1000 > Date.now()
                      ? () => handleRevoke(perm.protocol)
                      : undefined
                  }
                />
              ))}
            </AnimatePresence>
          </div>
        )}
      </motion.div>

      <GrantAccessModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onGrant={handleGrant}
      />
    </div>
  );
}
