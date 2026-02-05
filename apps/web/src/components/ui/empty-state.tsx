"use client";

import { ReactNode } from "react";
import { motion } from "framer-motion";
import {
  Wallet,
  Shield,
  TrendingUp,
  FileQuestion,
  Search,
  AlertCircle,
  type LucideIcon,
} from "lucide-react";
import { Button, buttonVariants } from "./button";
import { cn } from "@/lib/utils";
import Link from "next/link";

interface EmptyStateProps {
  icon?: LucideIcon;
  title: string;
  description: string;
  action?: {
    label: string;
    href?: string;
    onClick?: () => void;
  };
  className?: string;
  children?: ReactNode;
}

export function EmptyState({
  icon: Icon = FileQuestion,
  title,
  description,
  action,
  className,
  children,
}: EmptyStateProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className={cn(
        "flex flex-col items-center justify-center text-center py-12 px-4",
        className
      )}
    >
      <div className="w-16 h-16 rounded-full bg-muted/50 flex items-center justify-center mb-4">
        <Icon className="w-8 h-8 text-muted-foreground" />
      </div>
      <h3 className="text-lg font-semibold mb-2">{title}</h3>
      <p className="text-muted-foreground max-w-sm mb-6">{description}</p>
      {action && (
        action.href ? (
          <Link href={action.href} className={cn(buttonVariants({ variant: "default" }))}>
            {action.label}
          </Link>
        ) : (
          <Button onClick={action.onClick}>{action.label}</Button>
        )
      )}
      {children}
    </motion.div>
  );
}

export function NoWalletConnected({ className }: { className?: string }) {
  return (
    <EmptyState
      icon={Wallet}
      title="Connect Your Wallet"
      description="Connect your wallet to view your credit score, manage permissions, and interact with the Credora protocol."
      className={className}
    />
  );
}

export function NoScoreYet({ className }: { className?: string }) {
  return (
    <EmptyState
      icon={TrendingUp}
      title="No Credit Score Yet"
      description="You haven't minted your Credora SBT yet. Mint your soulbound token to start building your on-chain credit history."
      action={{
        label: "Mint SBT",
        href: "/score",
      }}
      className={className}
    />
  );
}

export function NoPermissions({ className }: { className?: string }) {
  return (
    <EmptyState
      icon={Shield}
      title="No Permissions Granted"
      description="You haven't granted any protocols access to your credit score yet. Grant access to start using your score in DeFi."
      action={{
        label: "Grant Access",
        href: "/permissions",
      }}
      className={className}
    />
  );
}

export function NoResults({ className }: { className?: string }) {
  return (
    <EmptyState
      icon={Search}
      title="No Results Found"
      description="Try adjusting your search or filter criteria to find what you're looking for."
      className={className}
    />
  );
}

export function ErrorState({
  message = "Something went wrong",
  onRetry,
  className,
}: {
  message?: string;
  onRetry?: () => void;
  className?: string;
}) {
  return (
    <EmptyState
      icon={AlertCircle}
      title="Error"
      description={message}
      action={onRetry ? { label: "Try Again", onClick: onRetry } : undefined}
      className={className}
    />
  );
}
