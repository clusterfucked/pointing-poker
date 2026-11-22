// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "topbar";
import "./theme";

const NAME_STORAGE_KEY = "pointing_poker:name";

const Hooks = {
  RememberName: {
    mounted() {
      const saved = localStorage.getItem(NAME_STORAGE_KEY);
      if (saved && saved.trim() !== "") {
        this.el.value = saved;
        this.pushEvent("set_name", { name: saved });
      }
      this.el.addEventListener("input", (e) => {
        localStorage.setItem(NAME_STORAGE_KEY, e.target.value);
      });
    },
  },
  CopyRoomUrl: {
    mounted() {
      let resetTimer = null;

      this.el.addEventListener("click", async () => {
        try {
          await navigator.clipboard.writeText(window.location.href);
          this.pushEvent("link_copied", {});

          const copyIcon = this.el.querySelector("[data-copy-icon]");
          const copiedIcon = this.el.querySelector("[data-copied-icon]");
          if (copyIcon && copiedIcon) {
            copyIcon.classList.add("hidden");
            copiedIcon.classList.remove("hidden");
            clearTimeout(resetTimer);
            resetTimer = setTimeout(() => {
              copiedIcon.classList.add("hidden");
              copyIcon.classList.remove("hidden");
            }, 2000);
          }
        } catch (_err) {
          // Clipboard API unavailable
        }
      });
    },
  },
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket;

if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      reloader.enableServerLogs();

      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}
