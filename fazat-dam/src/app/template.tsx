/** Re-mounts on every navigation, so each page settles in with a short enter motion. */
export default function Template({ children }: { children: React.ReactNode }) {
  return <div className="fd-page">{children}</div>;
}
