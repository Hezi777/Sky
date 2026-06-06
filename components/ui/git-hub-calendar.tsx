"use client";

import { useMemo } from "react";
import {
  format,
  subDays,
  addDays,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
} from "date-fns";

interface ContributionDay {
  date: string;
  count: number;
}

interface GitHubCalendarProps {
  data: ContributionDay[];
  colors?: string[];
  density?: "compact" | "spacious";
}

const DEFAULT_COLORS = [
  "var(--github-0)",
  "var(--github-1)",
  "var(--github-2)",
  "var(--github-3)",
  "var(--github-4)",
];

const GitHubCalendar = ({
  data,
  colors = DEFAULT_COLORS,
  density = "compact",
}: GitHubCalendarProps) => {
  const cellSize = density === "spacious" ? "clamp(0.75rem,0.9vw,1rem)" : "0.75rem";
  const labelColumn = density === "spacious" ? "2.75rem" : "2.5rem";
  const monthRow = density === "spacious" ? "1.15rem" : "1rem";

  const contributionsByDate = useMemo(
    () => new Map(data.map((item) => [item.date, item.count])),
    [data],
  );

  const today = new Date();
  const startDate = startOfWeek(subDays(today, 364), { weekStartsOn: 0 });
  const endDate = endOfWeek(today, { weekStartsOn: 0 });

  const weeks = useMemo(() => {
    const result: Date[][] = [];
    let currentWeekStart = startDate;

    while (currentWeekStart <= endDate) {
      result.push(
        eachDayOfInterval({
          start: currentWeekStart,
          end: endOfWeek(currentWeekStart, { weekStartsOn: 0 }),
        }),
      );
      currentWeekStart = addDays(currentWeekStart, 7);
    }

    return result;
  }, [endDate, startDate]);

  const monthLabels = useMemo(() => {
    const labels: { label: string; column: number }[] = [];
    let seenMonth = "";

    weeks.forEach((week, index) => {
      const firstOfMonth = week.find((day) => day.getDate() === 1);
      const labelDate = firstOfMonth ?? (index === 0 ? week[0] : null);
      if (!labelDate) return;

      const monthKey = format(labelDate, "yyyy-MM");
      if (monthKey === seenMonth) return;

      seenMonth = monthKey;
      labels.push({ label: format(labelDate, "MMM"), column: index + 1 });
    });

    return labels;
  }, [weeks]);

  const getColor = (count: number) => {
    if (count === 0) return colors[0];
    if (count === 1) return colors[1];
    if (count === 2) return colors[2];
    if (count === 3) return colors[3];
    return colors[4] ?? colors[colors.length - 1];
  };

  const dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return (
    <div className="flex h-full w-full flex-col justify-center">
      <div className="min-w-0 overflow-x-auto pb-1">
        <div
          className="grid w-max gap-1"
          style={{
            gridTemplateColumns: `${labelColumn} repeat(${weeks.length}, ${cellSize})`,
            gridTemplateRows: `${monthRow} repeat(7, ${cellSize})`,
          }}
        >
          {monthLabels.map((month) => (
            <span
              key={`${month.label}-${month.column}`}
              className="text-xs leading-4 text-muted-foreground"
              style={{
                gridColumn: `${month.column + 1} / span 4`,
                gridRow: 1,
              }}
            >
              {month.label}
            </span>
          ))}

          {dayLabels.map((day, i) => (
            <span
              key={day}
              className="text-xs leading-3 text-muted-foreground"
              style={{
                gridColumn: 1,
                gridRow: i + 2,
              }}
            >
              {day}
            </span>
          ))}

          {weeks.map((week, weekIndex) =>
            week.map((day, dayIndex) => {
              const key = format(day, "yyyy-MM-dd");
              const count = contributionsByDate.get(key) ?? 0;

              return (
                <div
                  key={key}
                  className="rounded-[4px]"
                  style={{
                    backgroundColor: getColor(count),
                    gridColumn: weekIndex + 2,
                    gridRow: dayIndex + 2,
                    height: cellSize,
                    width: cellSize,
                  }}
                  title={`${format(day, "PPP")}: ${count} contributions`}
                />
              );
            }),
          )}
        </div>
      </div>
      <div className="mt-4 flex items-center justify-center gap-2 text-xs text-muted-foreground">
        <span>Less</span>
        {colors.map((color, i) => (
          <div
            key={i}
            className="h-3 w-3 rounded-[4px]"
            style={{ backgroundColor: color }}
          />
        ))}
        <span>More</span>
      </div>
    </div>
  );
};

export { GitHubCalendar };
