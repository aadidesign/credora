"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { X } from "lucide-react";

interface GrantAccessModalProps {
  open: boolean;
  onClose: () => void;
  onGrant: (protocol: string, durationDays: number, maxRequests: number) => Promise<void>;
}

export function GrantAccessModal({
  open,
  onClose,
  onGrant,
}: GrantAccessModalProps) {
  const [protocol, setProtocol] = useState("");
  const [durationDays, setDurationDays] = useState(30);
  const [maxRequests, setMaxRequests] = useState(1000);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (!protocol || !/^0x[a-fA-F0-9]{40}$/.test(protocol)) {
      setError("Enter a valid Ethereum address");
      return;
    }
    setLoading(true);
    try {
      const durationSeconds = durationDays * 24 * 60 * 60;
      await onGrant(protocol, durationDays, maxRequests);
      onClose();
      setProtocol("");
      setDurationDays(30);
      setMaxRequests(1000);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to grant access");
    } finally {
      setLoading(false);
    }
  };

  if (!open) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <motion.div
          className="absolute inset-0 bg-black/60 backdrop-blur-sm"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
        />
        <motion.div
          className="relative w-full max-w-md"
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
        >
          <Card className="glass-card">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>Grant Access</CardTitle>
              <Button variant="ghost" size="icon" onClick={onClose}>
                <X size={18} />
              </Button>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="text-sm font-medium mb-2 block">
                    Protocol Address
                  </label>
                  <Input
                    type="text"
                    value={protocol}
                    onChange={(e) => setProtocol(e.target.value)}
                    placeholder="0x..."
                    className="font-mono"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium mb-2 block">
                    Duration (days)
                  </label>
                  <Input
                    type="number"
                    min={1}
                    max={365}
                    value={durationDays}
                    onChange={(e) =>
                      setDurationDays(parseInt(e.target.value) || 30)
                    }
                  />
                </div>
                <div>
                  <label className="text-sm font-medium mb-2 block">
                    Max Requests
                  </label>
                  <Input
                    type="number"
                    min={1}
                    value={maxRequests}
                    onChange={(e) =>
                      setMaxRequests(parseInt(e.target.value) || 1000)
                    }
                  />
                </div>
                {error && (
                  <p className="text-sm text-destructive">{error}</p>
                )}
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Granting..." : "Grant Access"}
                </Button>
              </form>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
