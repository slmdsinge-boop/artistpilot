import type { Metadata, Viewport } from "next";
import "./globals.css";
import { AppNavigation } from "@/components/app-navigation";

export const metadata: Metadata = {
  title: "ArtistPilot",
  description: "Le copilote administratif, financier et professionnel des artistes.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr">
      <body>{children}<AppNavigation/></body>
    </html>
  );
}
