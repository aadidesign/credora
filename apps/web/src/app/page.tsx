import Link from "next/link";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { ArrowRight } from "lucide-react";
import { GradientMesh } from "@/components/shared/gradient-mesh";
import { LandingFeatures } from "@/components/landing/landing-features";
import { HowItWorks } from "@/components/landing/how-it-works";
import { ScoreTiers } from "@/components/landing/score-tiers";

export default function HomePage() {
  return (
    <div className="min-h-screen">
      {/* Hero */}
      <section className="relative overflow-hidden py-20 md:py-32">
        <GradientMesh />
        <div className="container relative mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6">
            <span className="bg-gradient-to-r from-credora-cyan via-credora-green to-credora-cyan bg-clip-text text-transparent">
              Decentralized Credit
            </span>
            <br />
            <span className="text-foreground">Scoring for Web3</span>
          </h1>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto mb-10">
            Trustless, on-chain credit scoring using Soulbound Tokens. Enable
            uncollateralized lending at scale with verifiable on-chain
            reputation.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/dashboard"
              className={cn(buttonVariants({ size: "xl" }), "shadow-glow w-full sm:w-auto inline-flex")}
            >
              Launch App
              <ArrowRight size={18} />
            </Link>
            <Link
              href="#how-it-works"
              className={cn(buttonVariants({ variant: "outline", size: "xl" }), "w-full sm:w-auto inline-flex")}
            >
              How it Works
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-20 md:py-28 border-t border-border/40">
        <LandingFeatures />
      </section>

      {/* How it works */}
      <section id="how-it-works" className="py-20 md:py-28 border-t border-border/40">
        <HowItWorks />
      </section>

      {/* Score Tiers */}
      <section id="score-tiers" className="py-20 md:py-28 border-t border-border/40">
        <ScoreTiers />
      </section>

      {/* CTA */}
      <section className="py-20 md:py-28 border-t border-border/40">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Ready to Build Your On-Chain Reputation?
          </h2>
          <p className="text-muted-foreground max-w-xl mx-auto mb-8">
            Connect your wallet, mint your Soulbound credit score, and unlock
            uncollateralized lending opportunities across DeFi.
          </p>
          <Link
            href="/dashboard"
            className={cn(buttonVariants({ size: "xl" }), "shadow-glow inline-flex")}
          >
            Get Started
            <ArrowRight size={18} />
          </Link>
        </div>
      </section>
    </div>
  );
}
