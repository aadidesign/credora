import type { Metadata } from "next";
import { JetBrains_Mono, Space_Grotesk } from "next/font/google";
import { Web3Provider } from "@/components/providers/web3-provider";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import "./globals.css";

const spaceGrotesk = Space_Grotesk({
  subsets: ["latin"],
  variable: "--font-sans",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: {
    default: "Credora | Decentralized Credit Scoring for Web3",
    template: "%s | Credora",
  },
  description:
    "Trustless, on-chain credit scoring using Soulbound Tokens. Enable uncollateralized lending at scale with privacy-preserving, composable credit scores.",
  keywords: ["Credora", "DeFi", "credit score", "Soulbound", "Web3", "lending"],
  authors: [{ name: "Credora" }],
  openGraph: {
    title: "Credora | Decentralized Credit Scoring for Web3",
    description:
      "Trustless, on-chain credit scoring using Soulbound Tokens. Enable uncollateralized lending at scale.",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Credora | Decentralized Credit Scoring for Web3",
    description: "Trustless, on-chain credit scoring using Soulbound Tokens.",
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${spaceGrotesk.variable} ${jetbrainsMono.variable} font-sans min-h-screen flex flex-col`}
      >
        <Web3Provider>
          <Header />
          <main className="flex-1">{children}</main>
          <Footer />
        </Web3Provider>
      </body>
    </html>
  );
}
