"use client";

import { useEffect, useState } from "react";
import {
  formatDistanceToNow,
  format,
  isAfter,
  isBefore,
  addDays,
} from "date-fns";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

interface RelativeTimeProps {
  timestamp: number | Date;
  className?: string;
  showTooltip?: boolean;
  prefix?: string;
  suffix?: string;
}

export function RelativeTime({
  timestamp,
  className,
  showTooltip = true,
  prefix = "",
  suffix = "",
}: RelativeTimeProps) {
  const [mounted, setMounted] = useState(false);
  const date = typeof timestamp === "number" ? new Date(timestamp * 1000) : timestamp;

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <span className={className}>--</span>;
  }

  const relativeTime = formatDistanceToNow(date, { addSuffix: true });
  const fullDate = format(date, "PPpp");

  const content = (
    <span className={cn("text-muted-foreground", className)}>
      {prefix}
      {relativeTime}
      {suffix}
    </span>
  );

  if (!showTooltip) return content;

  return (
    <Tooltip>
      <TooltipTrigger asChild>{content}</TooltipTrigger>
      <TooltipContent>
        <p>{fullDate}</p>
      </TooltipContent>
    </Tooltip>
  );
}

interface ExpiryTimeProps {
  expiresAt: number;
  className?: string;
}

export function ExpiryTime({ expiresAt, className }: ExpiryTimeProps) {
  const [mounted, setMounted] = useState(false);
  const expiryDate = new Date(expiresAt * 1000);
  const now = new Date();

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <span className={className}>--</span>;
  }

  const isExpired = isBefore(expiryDate, now);
  const isExpiringSoon = !isExpired && isBefore(expiryDate, addDays(now, 7));

  const relativeTime = formatDistanceToNow(expiryDate, { addSuffix: true });
  const fullDate = format(expiryDate, "PPpp");

  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <span
          className={cn(
            className,
            isExpired && "text-red-500",
            isExpiringSoon && !isExpired && "text-yellow-500"
          )}
        >
          {isExpired ? "Expired " : "Expires "}
          {relativeTime}
        </span>
      </TooltipTrigger>
      <TooltipContent>
        <p>{fullDate}</p>
      </TooltipContent>
    </Tooltip>
  );
}
