import path from "node:path";
import { app, BrowserWindow, Menu, shell } from "electron";
import { loadEnvFile } from "./env";
import { ensureEnvFile } from "./first-run";
import { buildMenu } from "./menu";
import { startServer } from "./server";

let mainWindow: BrowserWindow | null = null;
let appOrigin: string | null = null;

function createWindow(url: string): void {
  appOrigin = new URL(url).origin;

  const isMac = process.platform === "darwin";

  mainWindow = new BrowserWindow({
    width: 1440,
    height: 900,
    backgroundColor: "#050505",
    ...(isMac && {
      titleBarStyle: "hiddenInset",
      vibrancy: "sidebar",
      transparent: true,
    }),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.webContents.setWindowOpenHandler(({ url: targetUrl }) => {
    shell.openExternal(targetUrl);
    return { action: "deny" };
  });

  mainWindow.webContents.on("will-navigate", (event, targetUrl) => {
    if (new URL(targetUrl).origin !== appOrigin) {
      event.preventDefault();
      shell.openExternal(targetUrl);
    }
  });

  mainWindow.on("closed", () => {
    mainWindow = null;
  });

  mainWindow.loadURL(url);
}

async function start(): Promise<void> {
  Menu.setApplicationMenu(buildMenu());

  const devUrl = process.env.SKY_DEV_URL;
  if (devUrl) {
    createWindow(devUrl);
    return;
  }

  if (!ensureEnvFile()) return;

  const envPath = path.join(app.getPath("userData"), ".env");
  const parsedEnv = loadEnvFile(envPath) ?? {};

  const { port } = await startServer(parsedEnv);
  createWindow(`http://127.0.0.1:${port}`);
}

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on("second-instance", () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  app.whenReady().then(() => {
    void start();
  });

  app.on("window-all-closed", () => {
    if (process.platform !== "darwin") {
      app.quit();
    }
  });

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      const devUrl = process.env.SKY_DEV_URL;
      if (devUrl) {
        createWindow(devUrl);
      } else if (appOrigin) {
        createWindow(appOrigin);
      }
    }
  });
}
