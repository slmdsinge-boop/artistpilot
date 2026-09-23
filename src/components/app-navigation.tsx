"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, FolderKanban, CircleDollarSign, CalendarDays, Building2 } from "lucide-react";

const items = [
  { label: "Accueil", href: "/", icon: Home },
  { label: "Projets", href: "/projects", icon: FolderKanban },
  { label: "Financements", href: "/funding", icon: CircleDollarSign },
  { label: "Concerts", href: "/concerts", icon: CalendarDays },
  { label: "Structures", href: "/organizations", icon: Building2 },
] as const;

export function AppNavigation() {
  const pathname = usePathname();
  if (pathname === "/login" || pathname.startsWith("/auth/")) return null;

  return (
    <nav aria-label="Navigation principale" className="fixed inset-x-0 bottom-0 z-10 mx-auto max-w-md border-t border-neutral-200 bg-white/95 px-3 pb-[max(.5rem,env(safe-area-inset-bottom))] pt-2 backdrop-blur">
      <div className="grid grid-cols-5">
        {items.map(({ label, href, icon: Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <Link key={href} href={href} aria-current={active ? "page" : undefined} className={`flex min-h-12 flex-col items-center justify-center gap-1 rounded-xl text-[10px] font-semibold transition ${active ? "text-neutral-950" : "text-neutral-400"}`}>
              <Icon size={20} strokeWidth={active ? 2.4 : 1.8} />
              <span>{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
