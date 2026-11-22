const THEME_STORAGE_KEY = "phx:theme";
const prefersDark = window.matchMedia("(prefers-color-scheme: dark)");

function setTheme(theme) {
  if (theme === "system") {
    localStorage.removeItem(THEME_STORAGE_KEY);
    document.documentElement.setAttribute(
      "data-theme",
      prefersDark.matches ? "dark" : "light",
    );
    document.documentElement.setAttribute("data-theme-source", "system");
  } else {
    localStorage.setItem(THEME_STORAGE_KEY, theme);
    document.documentElement.setAttribute("data-theme", theme);
    document.documentElement.setAttribute("data-theme-source", "user");
  }
}

if (!document.documentElement.hasAttribute("data-theme")) {
  setTheme(localStorage.getItem(THEME_STORAGE_KEY) || "system");
}

window.addEventListener("storage", (e) => {
  if (e.key === THEME_STORAGE_KEY) setTheme(e.newValue || "system");
});

prefersDark.addEventListener("change", () => {
  if (!localStorage.getItem(THEME_STORAGE_KEY)) setTheme("system");
});

window.addEventListener("phx:set-theme", (e) => {
  setTheme(e.target.dataset.phxTheme);
});

window.addEventListener("pointing-poker:close-menu", () => {
  document.activeElement?.blur();
});
