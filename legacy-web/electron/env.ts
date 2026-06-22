import fs from "node:fs";

/** Parse a simple .env file into key/value pairs. Returns null if the file is missing. */
export function loadEnvFile(filePath: string): Record<string, string> | null {
  if (!fs.existsSync(filePath)) return null;

  const result: Record<string, string> = {};
  const lines = fs.readFileSync(filePath, "utf-8").split("\n");

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;

    const eqIndex = line.indexOf("=");
    if (eqIndex === -1) continue;

    const key = line.slice(0, eqIndex).trim();
    let value = line.slice(eqIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    result[key] = value;
  }

  return result;
}
