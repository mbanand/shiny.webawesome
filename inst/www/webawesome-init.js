import { setBasePath } from "./webawesome/utilities/base-path.js";
import { startLoader } from "./webawesome/utilities/autoloader.js";

const basePath = new URL("./webawesome/", import.meta.url).toString();

setBasePath(basePath);

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startLoader, { once: true });
} else {
  startLoader();
}
