"use client";

import { Badge } from "@/components/ui/badge";

const tierVariantMap = {
  Newcomer: "newcomer" as const,
  Established: "established" as const,
  Trusted: "trusted" as const,
  Prime: "prime" as const,
};

interface TierBadgeProps {
  tierName: string;
  className?: string;
}

export function TierBadge({ tierName, className = "" }: TierBadgeProps) {
  const variant = tierVariantMap[tierName as keyof typeof tierVariantMap] ?? "secondary";
  return (
    <Badge variant={variant} className={className}>
      {tierName}
    </Badge>
  );
}
