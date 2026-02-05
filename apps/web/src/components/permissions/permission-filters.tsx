"use client";

import { useState } from "react";
import { Search, Filter, X } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

export type PermissionStatus = "all" | "active" | "expired" | "revoked";

interface PermissionFiltersProps {
  onSearchChange: (search: string) => void;
  onStatusChange: (status: PermissionStatus) => void;
  activeStatus: PermissionStatus;
  className?: string;
}

const statusOptions: { value: PermissionStatus; label: string; color: string }[] = [
  { value: "all", label: "All", color: "bg-muted" },
  { value: "active", label: "Active", color: "bg-green-500/20 text-green-500" },
  { value: "expired", label: "Expired", color: "bg-yellow-500/20 text-yellow-500" },
  { value: "revoked", label: "Revoked", color: "bg-red-500/20 text-red-500" },
];

export function PermissionFilters({
  onSearchChange,
  onStatusChange,
  activeStatus,
  className,
}: PermissionFiltersProps) {
  const [search, setSearch] = useState("");

  const handleSearchChange = (value: string) => {
    setSearch(value);
    onSearchChange(value);
  };

  const clearSearch = () => {
    setSearch("");
    onSearchChange("");
  };

  return (
    <div className={cn("flex flex-col sm:flex-row gap-4", className)}>
      {/* Search */}
      <div className="relative flex-1">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search by protocol address..."
          value={search}
          onChange={(e) => handleSearchChange(e.target.value)}
          className="pl-9 pr-9"
        />
        {search && (
          <Button
            variant="ghost"
            size="icon"
            className="absolute right-1 top-1/2 -translate-y-1/2 h-7 w-7"
            onClick={clearSearch}
          >
            <X className="h-4 w-4" />
          </Button>
        )}
      </div>

      {/* Status Filter */}
      <div className="flex items-center gap-2 flex-wrap">
        <Filter className="h-4 w-4 text-muted-foreground hidden sm:block" />
        {statusOptions.map((option) => (
          <Badge
            key={option.value}
            variant="outline"
            className={cn(
              "cursor-pointer transition-colors",
              activeStatus === option.value
                ? option.color
                : "hover:bg-muted/50"
            )}
            onClick={() => onStatusChange(option.value)}
          >
            {option.label}
          </Badge>
        ))}
      </div>
    </div>
  );
}
