import { app, Menu, MenuItemConstructorOptions } from "electron";

/** Build the application menu, including a "Launch at Login" toggle when packaged. */
export function buildMenu(): Menu {
  const template: MenuItemConstructorOptions[] = [];

  if (process.platform === "darwin") {
    const submenu: MenuItemConstructorOptions[] = [
      { role: "about" },
      { type: "separator" },
      { role: "services" },
      { type: "separator" },
      { role: "hide" },
      { role: "hideOthers" },
      { role: "unhide" },
      { type: "separator" },
      { role: "quit" },
    ];
    if (app.isPackaged) {
      submenu.splice(1, 0, { type: "separator" }, buildLaunchAtLoginItem());
    }
    template.push({ role: "appMenu", submenu });
  } else if (app.isPackaged) {
    template.push({
      label: "File",
      submenu: [buildLaunchAtLoginItem(), { type: "separator" }, { role: "quit" }],
    });
  }

  template.push({ role: "editMenu" }, { role: "viewMenu" }, { role: "windowMenu" });

  return Menu.buildFromTemplate(template);
}

function buildLaunchAtLoginItem(): MenuItemConstructorOptions {
  return {
    label: "Launch at Login",
    type: "checkbox",
    checked: app.getLoginItemSettings().openAtLogin,
    click: (item) => {
      app.setLoginItemSettings({ openAtLogin: item.checked });
    },
  };
}
