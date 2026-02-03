"use client";

import { useEffect } from "react";
import { RainbowKitProvider, darkTheme } from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Provider as UrqlProvider } from "urql";
import { TooltipProvider } from "@/components/ui/tooltip";
import { config } from "@/lib/wagmi";
import { validateEnv } from "@/config/validate";
import { graphqlClient } from "@/lib/graphql/client";
import "@rainbow-me/rainbowkit/styles.css";

const queryClient = new QueryClient();

/** Suppress WalletConnect "Connection interrupted" when project ID is invalid/missing */
function useWalletConnectErrorHandler() {
  useEffect(() => {
    const handler = (event: PromiseRejectionEvent) => {
      const msg = event.reason?.message ?? String(event.reason);
      if (typeof msg === "string" && msg.includes("Connection interrupted while trying to subscribe")) {
        event.preventDefault();
        event.stopPropagation();
        if (process.env.NODE_ENV === "development") {
          console.warn(
            "[WalletConnect] Connection interrupted. Get a free Project ID from https://cloud.walletconnect.com and set NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID"
          );
        }
      }
    };
    window.addEventListener("unhandledrejection", handler);
    return () => window.removeEventListener("unhandledrejection", handler);
  }, []);
}

export function Web3Provider({ children }: { children: React.ReactNode }) {
  useWalletConnectErrorHandler();

  useEffect(() => {
    validateEnv();
  }, []);

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <UrqlProvider value={graphqlClient}>
        <RainbowKitProvider
          theme={darkTheme({
            accentColor: "#00d4aa",
            accentColorForeground: "#0f0f23",
            borderRadius: "medium",
          })}
          modalSize="compact"
        >
          <TooltipProvider delayDuration={300}>
            {children}
          </TooltipProvider>
        </RainbowKitProvider>
        </UrqlProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
