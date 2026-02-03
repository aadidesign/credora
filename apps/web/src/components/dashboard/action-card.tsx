"use client";

import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { LucideIcon } from "lucide-react";

interface ActionCardProps {
  title: string;
  description: string;
  icon: LucideIcon;
  onAction: () => void;
  actionLabel: string;
  disabled?: boolean;
  loading?: boolean;
}

export function ActionCard({
  title,
  description,
  icon: Icon,
  onAction,
  actionLabel,
  disabled = false,
  loading = false,
}: ActionCardProps) {
  return (
    <Card className="glass hover:border-credora-cyan/30 transition-colors">
      <CardHeader>
        <div className="w-10 h-10 rounded-lg bg-credora-cyan/10 flex items-center justify-center mb-2">
          <Icon className="w-5 h-5 text-credora-cyan" />
        </div>
        <h3 className="font-semibold">{title}</h3>
        <p className="text-sm text-muted-foreground">{description}</p>
      </CardHeader>
      <CardContent>
        <Button
          onClick={onAction}
          disabled={disabled || loading}
          className="w-full"
        >
          {loading ? "Processing..." : actionLabel}
        </Button>
      </CardContent>
    </Card>
  );
}
