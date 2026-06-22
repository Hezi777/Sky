import { Logo } from "@/components/logo";
import { SettingsDialog } from "@/components/settings-dialog";

// Single-page app: no in-page navigation. Slim rail = logo (top) + settings (bottom).
export function Sidebar() {
  return (
    <aside className="sticky top-0 flex h-screen w-14 shrink-0 flex-col items-center justify-between border-r border-sidebar-border bg-sidebar py-3">
      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-sidebar-accent">
        <Logo className="h-5 w-5" />
      </div>

      <SettingsDialog triggerClassName="text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground" />
    </aside>
  );
}
