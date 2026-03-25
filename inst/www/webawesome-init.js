import { setBasePath } from "./wa/utilities/base-path.js";
import { startLoader } from "./wa/utilities/autoloader.js";

const basePath = new URL("./wa/", import.meta.url).toString();
const warningConfig = Object.assign(
  {
    missing_tree_item_id: true
  },
  window.shinyWebawesomeWarnings || {}
);
const warningCache = new Set();

window.shinyWebawesomeWarnings = warningConfig;
window.ShinyWebawesomeWarn = {
  isEnabled(key) {
    return warningConfig[key] !== false;
  },
  warnOnce({ key, inputId, message }) {
    const cacheKey = `${key}:${inputId || ""}`;

    if (!this.isEnabled(key) || warningCache.has(cacheKey)) {
      return;
    }

    warningCache.add(cacheKey);

    const suffix = inputId ? ` \`${inputId}\`` : "";
    console.warn(`${message}${suffix}`);
  }
};

setBasePath(basePath);

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startLoader, { once: true });
} else {
  startLoader();
}
