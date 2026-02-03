import Link from "next/link";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { ArrowRight } from "lucide-react";
import { GradientMesh } from "@/components/shared/gradient-mesh";
import { AuroraBackground } from "@/components/shared/aurora-background";
import { LandingFeatures } from "@/components/landing/landing-features";
import { HowItWorks } from "@/components/landing/how-it-works";
import { ScoreTiers } from "@/components/landing/score-tiers";
import { LandingHero } from "@/components/landing/landing-hero";

export default function HomePage() {
  return (
    <div className="min-h-screen relative">
      {/* Hero */}
      <section className="relative overflow-hidden py-16 sm:py-24 md:py-32 lg:py-40">
        <GradientMesh />
        <AuroraBackground />
        <LandingHero />
      </section>

      {/* Features */}
      <section id="features" className="relative py-16 sm:py-20 md:py-28 border-t border-border/40 bg-background/50">
        <LandingFeatures />
      </section>

      {/* How it works */}
      <section id="how-it-works" className="relative py-16 sm:py-20 md:py-28 border-t border-border/40">
        <HowItWorks />
      </section>

      {/* Score Tiers */}
      <section id="score-tiers" className="relative py-16 sm:py-20 md:py-28 border-t border-border/40 bg-background/50">
        <ScoreTiers />
      </section>

      {/* CTA */}
      <section className="relative py-16 sm:py-20 md:py-28 border-t border-border/40 overflow-hidden">
        <div className="absolute inset-0 bg-credora-cyan/5" aria-hidden />
        <div className="container relative mx-auto px-4 py-12 sm:py-16 text-center">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold mb-4">
            Ready to Build Your On-Chain Reputation?
          </h2>
          <p className="text-muted-foreground max-w-xl mx-auto mb-8 text-sm sm:text-base">
            Connect your wallet, mint your Soulbound credit score, and unlock
            uncollateralized lending opportunities across DeFi.
          </p>
          <Link
            href="/dashboard"
            className={cn(
              buttonVariants({ size: "xl" }),
              "shadow-glow glow-cyan-sm hover:glow-cyan inline-flex transition-shadow"
            )}
          >
            Get Started
            <ArrowRight size={18} />
          </Link>
        </div>
      </section>
    </div>
  );
}
