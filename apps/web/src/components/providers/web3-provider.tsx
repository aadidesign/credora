"use client";

import { RainbowKitProvider, darkTheme } from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Provider as UrqlProvider } from "urql";
import { config } from "@/lib/wagmi";
import { graphqlClient } from "@/lib/graphql/client";
import "@rainbow-me/rainbowkit/styles.css";

const queryClient = new QueryClient();

export function Web3Provider({ children }: { children: React.ReactNode }) {
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
          {children}
        </RainbowKitProvider>
        </UrqlProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
