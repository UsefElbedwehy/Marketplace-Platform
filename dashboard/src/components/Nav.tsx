"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { DevIdentitySwitcher } from "./DevIdentitySwitcher";

const LINKS = [
  { href: "/catalog", label: "Schema Builder" },
  { href: "/listings", label: "Listings" },
  { href: "/config", label: "Config Studio" },
  { href: "/theme", label: "Theme Studio" },
  { href: "/users", label: "Users" },
];

export function Nav() {
  const pathname = usePathname();
  return (
    <header className="border-b border-slate-200 bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <div className="flex items-center gap-8">
          <Link href="/" className="font-semibold text-slate-900">
            Marketplace Platform
          </Link>
          <nav className="flex gap-1">
            {LINKS.map((link) => {
              const active = pathname?.startsWith(link.href);
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`rounded px-3 py-1.5 text-sm font-medium ${
                    active ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>
        </div>
        <DevIdentitySwitcher />
      </div>
    </header>
  );
}
