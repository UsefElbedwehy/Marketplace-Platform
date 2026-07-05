import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/components/AuthProvider";
import { Nav } from "@/components/Nav";

export const metadata: Metadata = {
  title: "Marketplace Platform — Dashboard",
  description: "White-label marketplace admin: Schema Builder, Config Studio, Theme Studio.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-slate-50 text-slate-900 font-sans">
        <AuthProvider>
          <Nav />
          <main className="flex-1 mx-auto w-full max-w-6xl px-6 py-8">{children}</main>
        </AuthProvider>
      </body>
    </html>
  );
}
