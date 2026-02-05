"use client";

import { useState } from "react";
import { Check, Copy } from "lucide-react";
import { Button } from "./button";
import { toast } from "./toaster";
import { cn } from "@/lib/utils";

interface CopyButtonProps {
  value: string;
  className?: string;
  successMessage?: string;
}

export function CopyButton({
  value,
  className,
  successMessage = "Copied to clipboard",
}: CopyButtonProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      toast.success(successMessage);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      toast.error("Failed to copy");
    }
  };

  return (
    <Button
      variant="ghost"
      size="icon"
      className={cn("h-8 w-8", className)}
      onClick={handleCopy}
      aria-label={copied ? "Copied" : "Copy to clipboard"}
    >
      {copied ? (
        <Check className="h-4 w-4 text-green-500" />
      ) : (
        <Copy className="h-4 w-4" />
      )}
    </Button>
  );
}

export function CopyableAddress({
  address,
  truncate = true,
  className,
}: {
  address: string;
  truncate?: boolean;
  className?: string;
}) {
  const displayAddress = truncate
    ? `${address.slice(0, 6)}...${address.slice(-4)}`
    : address;

  return (
    <span className={cn("inline-flex items-center gap-1 font-mono text-sm", className)}>
      <span>{displayAddress}</span>
      <CopyButton value={address} successMessage="Address copied" />
    </span>
  );
}
