import { OfflineIcon } from "@/components/icons";

// Static and bilingual: pre-cached by the service worker and shown when a page can't be reached.
export const dynamic = "force-static";

export default function OfflinePage() {
  return (
    <div className="mx-auto flex max-w-md flex-col items-center gap-4 py-10 text-center">
      <OfflineIcon className="h-14 w-14 text-muted" />
      <h1 className="page-title">أنت غير متصل بالإنترنت</h1>
      <p lang="en" dir="ltr" className="text-muted">You are offline</p>
      <p className="text-sm text-muted">ستعود الصفحة عند عودة الاتصال. مسودات الطلبات محفوظة على جهازك.</p>
      <p lang="en" dir="ltr" className="text-sm text-muted">The page will load when you are back online. Request drafts are kept on this device.</p>
      {/* a full page load is intended here: the client router may be unavailable offline */}
      {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
      <a href="/" className="btn-primary">الرئيسية · Home</a>
    </div>
  );
}
