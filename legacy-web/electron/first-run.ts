import fs from "node:fs";
import path from "node:path";
import { app, dialog, shell } from "electron";

/**
 * Ensures a config file exists in userData. If missing, copies the bundled
 * template, prompts the user to fill it in, and quits the app.
 *
 * @returns true if startup should continue, false if the app is quitting.
 */
export function ensureEnvFile(): boolean {
  const envPath = path.join(app.getPath("userData"), ".env");
  if (fs.existsSync(envPath)) return true;

  fs.mkdirSync(app.getPath("userData"), { recursive: true });
  fs.copyFileSync(path.join(process.resourcesPath, "env.example"), envPath);

  const result = dialog.showMessageBoxSync({
    type: "info",
    title: "Sky - Configuration Required",
    message: "A configuration template was created.",
    detail: `Please fill in your API keys and credentials in:\n\n${envPath}\n\nThen restart Sky.`,
    buttons: ["Open Folder", "Quit"],
    defaultId: 0,
    cancelId: 1,
  });

  if (result === 0) {
    shell.showItemInFolder(envPath);
  }

  app.quit();
  return false;
}
