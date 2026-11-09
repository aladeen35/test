import type { Metadata, Viewport } from "next";
import "@fontsource/ibm-plex-sans-arabic/400.css";
import "@fontsource/ibm-plex-sans-arabic/600.css";
import "@fontsource/ibm-plex-sans-arabic/700.css";
import "@fontsource-variable/inter";
import "./globals.css";
import { getDict } from "@/lib/i18n/server";
import { dirOf } from "@/lib/i18n";
import { I18nProvider } from "@/lib/i18n/client";
import { SiteHeader, SiteFooter } from "@/components/site-header";
import { BottomNav } from "@/components/bottom-nav";
import { OfflineBanner, ServiceWorkerRegister } from "@/components/pwa";
import { Splash, SPLASH_SCRIPT } from "@/components/splash";
import { IntroCards } from "@/components/intro-cards";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return {
    metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"),
    title: { default: t.meta.title, template: `%s · ${t.meta.name}` },
    description: t.meta.description,
    applicationName: t.meta.name,
    appleWebApp: { capable: true, title: t.meta.name, statusBarStyle: "default" },
    formatDetection: { telephone: false },
    openGraph: { title: t.meta.title, description: t.meta.description, images: ["/brand/logo-full.png"] },
  };
}

export const viewport: Viewport = {
  themeColor: "#C62828",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const { locale, t } = await getDict();
  return (
    <html lang={locale} dir={dirOf(locale)} className="h-full antialiased" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: SPLASH_SCRIPT }} />
      </head>
      <body className="flex min-h-full flex-col">
        <Splash t={t} />
        <I18nProvider locale={locale}>
          <OfflineBanner />
          <SiteHeader />
          <main id="main" className="mx-auto w-full max-w-6xl flex-1 px-4 py-5">{children}</main>
          <SiteFooter />
          <BottomNav />
          <ServiceWorkerRegister />
          <IntroCards />
        </I18nProvider>
      </body>
    </html>
  );
}
