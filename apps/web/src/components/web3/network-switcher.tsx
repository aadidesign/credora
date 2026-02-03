"use client";

import { useSwitchChain, useChainId } from "wagmi";
import { arbitrum, arbitrumSepolia, sepolia } from "wagmi/chains";
import { Button } from "@/components/ui/button";
import { Network } from "lucide-react";
import { cn } from "@/lib/utils";

/** Supported chains for network switching */
const SUPPORTED_CHAINS = [
  { id: arbitrumSepolia.id, name: "Arbitrum Sepolia" },
  { id: arbitrum.id, name: "Arbitrum" },
  { id: sepolia.id, name: "Sepolia" },
] as const;

export function NetworkSwitcher({ className }: { className?: string }) {
  const chainId = useChainId();
  const { switchChain, isPending } = useSwitchChain();

  const currentChain = SUPPORTED_CHAINS.find((c) => c.id === chainId);

  return (
    <div className={cn("flex items-center gap-2", className)}>
      <Network size={16} className="text-muted-foreground" />
      <span className="text-sm text-muted-foreground hidden sm:inline">
        {currentChain?.name ?? `Chain ${chainId}`}
      </span>
      {chainId !== 421614 && chainId !== 42161 && chainId !== 11155111 && (
        <Button
          variant="outline"
          size="sm"
          onClick={() => switchChain({ chainId: 421614 })}
          disabled={isPending}
        >
          {isPending ? "Switching..." : "Switch to Arbitrum Sepolia"}
        </Button>
      )}
    </div>
  );
}
