import Link from "next/link";
import { Github, Twitter, BookOpen } from "lucide-react";

const footerLinks = {
  product: [
    { label: "Dashboard", href: "/dashboard" },
    { label: "Score", href: "/score" },
    { label: "Permissions", href: "/permissions" },
  ],
  resources: [
    { label: "Documentation", href: "#" },
    { label: "GitHub", href: "https://github.com" },
    { label: "Whitepaper", href: "#" },
  ],
};

export function Footer() {
  return (
    <footer className="border-t border-border/40 bg-background/50">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="md:col-span-2">
            <Link
              href="/"
              className="inline-block font-bold text-xl bg-gradient-to-r from-credora-cyan to-credora-green bg-clip-text text-transparent mb-4"
            >
              Credora
            </Link>
            <p className="text-sm text-muted-foreground max-w-md">
              Decentralized credit scoring protocol for Web3. Soulbound tokens
              that bridge DeFi lending with verifiable on-chain reputation.
            </p>
            <div className="flex gap-4 mt-4">
              <a
                href="https://github.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-muted-foreground hover:text-credora-cyan transition-colors"
              >
                <Github size={20} />
              </a>
              <a
                href="https://twitter.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-muted-foreground hover:text-credora-cyan transition-colors"
              >
                <Twitter size={20} />
              </a>
            </div>
          </div>
          <div>
            <h4 className="font-semibold text-sm mb-3">Product</h4>
            <ul className="space-y-2">
              {footerLinks.product.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="font-semibold text-sm mb-3">Resources</h4>
            <ul className="space-y-2">
              {footerLinks.resources.map((link) => (
                <li key={link.label}>
                  <a
                    href={link.href}
                    className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-2"
                  >
                    {link.label === "Documentation" && <BookOpen size={14} />}
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <div className="mt-12 pt-8 border-t border-border/40 flex flex-col sm:flex-row justify-between items-center gap-4">
          <p className="text-xs text-muted-foreground">
            © {new Date().getFullYear()} Credora. Built for the decentralized
            future.
          </p>
        </div>
      </div>
    </footer>
  );
}
