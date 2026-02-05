"use client";

import { motion } from "framer-motion";
import { Shield, Clock, Hash, ExternalLink } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CopyableAddress } from "@/components/ui/copy-button";
import { ExpiryTime, RelativeTime } from "@/components/ui/relative-time";
import { cn } from "@/lib/utils";

interface Permission {
  id: string;
  protocol: string;
  grantedAt: number;
  expiresAt: number;
  maxRequests: number;
  usedRequests: number;
  isActive: boolean;
  permissionHash: string;
}

interface PermissionCardProps {
  permission: Permission;
  onRevoke?: () => void;
  className?: string;
}

export function PermissionCard({
  permission,
  onRevoke,
  className,
}: PermissionCardProps) {
  const now = Math.floor(Date.now() / 1000);
  const isExpired = permission.expiresAt < now;
  const usagePercent = (permission.usedRequests / permission.maxRequests) * 100;

  const status = !permission.isActive
    ? "revoked"
    : isExpired
    ? "expired"
    : "active";

  const statusColors = {
    active: "bg-green-500/20 text-green-500 border-green-500/30",
    expired: "bg-yellow-500/20 text-yellow-500 border-yellow-500/30",
    revoked: "bg-red-500/20 text-red-500 border-red-500/30",
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
    >
      <Card className={cn("glass-card", className)}>
        <CardHeader className="pb-2">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-2">
              <Shield className="h-5 w-5 text-credora-cyan" />
              <CardTitle className="text-base">Protocol Access</CardTitle>
            </div>
            <Badge variant="outline" className={statusColors[status]}>
              {status.charAt(0).toUpperCase() + status.slice(1)}
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Protocol Address */}
          <div>
            <p className="text-xs text-muted-foreground mb-1">Protocol</p>
            <CopyableAddress address={permission.protocol} />
          </div>

          {/* Timing */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-muted-foreground mb-1">Granted</p>
              <RelativeTime timestamp={permission.grantedAt} className="text-sm" />
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Expires</p>
              <ExpiryTime expiresAt={permission.expiresAt} className="text-sm" />
            </div>
          </div>

          {/* Usage */}
          <div>
            <div className="flex justify-between text-xs text-muted-foreground mb-1">
              <span>Usage</span>
              <span>
                {permission.usedRequests.toLocaleString()} /{" "}
                {permission.maxRequests.toLocaleString()} requests
              </span>
            </div>
            <div className="h-2 bg-muted rounded-full overflow-hidden">
              <div
                className="h-full bg-credora-cyan transition-all"
                style={{ width: `${Math.min(usagePercent, 100)}%` }}
              />
            </div>
          </div>

          {/* Permission Hash */}
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <Hash className="h-3 w-3" />
            <span className="font-mono truncate">{permission.permissionHash}</span>
          </div>

          {/* Actions */}
          {status === "active" && onRevoke && (
            <Button
              variant="destructive"
              size="sm"
              className="w-full"
              onClick={onRevoke}
            >
              Revoke Access
            </Button>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );
}
