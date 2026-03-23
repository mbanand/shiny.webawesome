import { setBasePath } from "./wa/utilities/base-path.js";
import { startLoader } from "./wa/utilities/autoloader.js";

const basePath = new URL("./wa/", import.meta.url).toString();

setBasePath(basePath);

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startLoader, { once: true });
} else {
  startLoader();
}
