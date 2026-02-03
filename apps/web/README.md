# Credora Web App

Production-ready Next.js frontend for the Credora decentralized credit scoring protocol.

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

- `NEXT_PUBLIC_SUBGRAPH_URL` - The Graph subgraph endpoint
- `NEXT_PUBLIC_CHAIN_ID` - Default chain (421614 = Arbitrum Sepolia)
- `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` - From cloud.walletconnect.com
