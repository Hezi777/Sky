import { DashboardGrid } from "@/components/dashboard-grid";
import { GreetingCard } from "@/components/widgets/greeting-card";

export default function Home() {
  return (
    <div className="mx-auto flex max-w-7xl flex-col gap-4">
      <GreetingCard />
      <DashboardGrid />
    </div>
  );
}
