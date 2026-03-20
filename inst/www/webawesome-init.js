import { setBasePath } from "./webawesome/utilities/base-path.js";

const basePath = new URL("./webawesome/", import.meta.url).toString();

setBasePath(basePath);
void import("./webawesome/webawesome.loader.js");
