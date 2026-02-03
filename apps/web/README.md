# Credora Web App

Production-ready Next.js frontend for the Credora decentralized credit scoring protocol.

## Backend Integration

The frontend integrates with:

| Data Source | Purpose |
|-------------|---------|
| **@credora/sdk** | Smart contract calls (ScoreSBT, PermissionManager, ScoreOracle) |
| **The Graph** | Indexed data (score history, permissions) via GraphQL |
| **Wagmi/RainbowKit** | Wallet connection |

**To get APIs working:**

1. **Deploy contracts** to your target network (Arbitrum Sepolia, etc.)
2. **Set contract addresses** in `.env.local`:
   ```
   NEXT_PUBLIC_SCORE_SBT_ADDRESS=0x...
   NEXT_PUBLIC_SCORE_ORACLE_ADDRESS=0x...
   NEXT_PUBLIC_PERMISSION_MANAGER_ADDRESS=0x...
   ```
3. **Deploy subgraph** (`packages/subgraph`) to The Graph Network via [Subgraph Studio](https://thegraph.com/studio). The old `api.thegraph.com` hosted service was sunset June 2024. Set `NEXT_PUBLIC_SUBGRAPH_URL` to your deployed endpoint. Leave unset for local dev (app works with empty indexed data).
4. **Local dev**: Use chain 31337, run `anvil` + `forge script` deploy. SDK has preconfigured local addresses.

## Structure

```
src/
├── app/              # Next.js App Router pages and layouts
├── components/       # React components
│   ├── dashboard/    # Dashboard-specific (ScoreGauge, TierBadge, ActionCard)
│   ├── landing/      # Landing page sections
│   ├── layout/       # Header, Footer
│   ├── permissions/  # Grant access modal
│   ├── providers/    # Web3, Query providers
│   ├── shared/       # Reusable (GradientMesh)
│   ├── ui/           # shadcn-style primitives
│   └── web3/         # NetworkSwitcher
├── config/           # Environment and app config
├── constants/        # App-wide constants
├── hooks/            # useCredora, useSubgraph
├── lib/              # Utilities, Wagmi, GraphQL, Credora client
└── types/            # Shared TypeScript types
```

## Development

```bash
npm install
npm run dev
```

## Environment

Copy `.env.example` to `.env.local` and set:

- `NEXT_PUBLIC_SUBGRAPH_URL` - The Graph subgraph endpoint (after deploying to Subgraph Studio). Omit for local dev.
- `NEXT_PUBLIC_CHAIN_ID` - Default chain (421614 = Arbitrum Sepolia, 31337 = Local)
- `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` - From cloud.walletconnect.com
- `NEXT_PUBLIC_SCORE_SBT_ADDRESS`, etc. - Contract addresses (after deploy)

## Troubleshooting

| Console Error | Cause | Fix |
|---------------|-------|-----|
| CORS / `api.thegraph.com` | Deprecated subgraph URL | Leave `NEXT_PUBLIC_SUBGRAPH_URL` unset, or deploy to Subgraph Studio and set the new URL |
| Connection interrupted (WalletConnect) | Invalid/missing project ID | Get a free Project ID from cloud.walletconnect.com and set `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` |
| User rejected / Mint failed | User clicked Reject in wallet | Expected; no fix needed |
| Unchecked runtime.lastError | Browser extension | Usually harmless; can ignore |
