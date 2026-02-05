"use client";

import { useMemo } from "react";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Legend,
  Tooltip,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface PermissionsChartProps {
  activeCount: number;
  expiredCount: number;
  revokedCount: number;
  className?: string;
}

const COLORS = {
  active: "#00d4aa",
  expired: "#f59e0b",
  revoked: "#ef4444",
};

export function PermissionsChart({
  activeCount,
  expiredCount,
  revokedCount,
  className,
}: PermissionsChartProps) {
  const data = useMemo(
    () => [
      { name: "Active", value: activeCount, color: COLORS.active },
      { name: "Expired", value: expiredCount, color: COLORS.expired },
      { name: "Revoked", value: revokedCount, color: COLORS.revoked },
    ].filter((d) => d.value > 0),
    [activeCount, expiredCount, revokedCount]
  );

  const total = activeCount + expiredCount + revokedCount;

  if (total === 0) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="text-lg">Permissions Overview</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[180px] flex items-center justify-center text-muted-foreground">
            No permissions granted yet
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={className}>
      <CardHeader>
        <CardTitle className="text-lg">Permissions Overview</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={180}>
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              innerRadius={40}
              outerRadius={60}
              paddingAngle={2}
              dataKey="value"
            >
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>
            <Tooltip
              contentStyle={{
                backgroundColor: "hsl(var(--card))",
                border: "1px solid hsl(var(--border))",
                borderRadius: "8px",
                color: "hsl(var(--foreground))",
              }}
            />
            <Legend
              formatter={(value) => (
                <span style={{ color: "hsl(var(--foreground))" }}>{value}</span>
              )}
            />
          </PieChart>
        </ResponsiveContainer>
        <div className="text-center text-sm text-muted-foreground mt-2">
          {total} total permission{total !== 1 ? "s" : ""}
        </div>
      </CardContent>
    </Card>
  );
}
