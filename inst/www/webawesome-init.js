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
  debug(message) {
    if (!this.isEnabled("command_layer_debug")) {
      return;
    }

    console.debug(`[shiny.webawesome] ${message}`);
  },
  warn({ key, message }) {
    if (!this.isEnabled(key)) {
      return;
    }

    console.warn(`[shiny.webawesome] ${message}`);
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

function handleSetPropertyCommand(message) {
  const id = typeof message?.id === "string" ? message.id : "";
  const propertyName = typeof message?.payload?.name === "string"
    ? message.payload.name
    : "";
  const target = document.getElementById(id);

  if (!id || !target) {
    window.ShinyWebawesomeWarn.warn({
      key: "command_layer",
      message: `Could not find command target with id "${id}".`
    });
    return;
  }

  if (!propertyName) {
    window.ShinyWebawesomeWarn.warn({
      key: "command_layer",
      message: "Missing property name for set_property command."
    });
    return;
  }

  target[propertyName] = message.payload.value;
  window.ShinyWebawesomeWarn.debug(
    `set_property applied "${propertyName}" on target "${id}".`
  );
}

function handleCallMethodCommand(message) {
  const id = typeof message?.id === "string" ? message.id : "";
  const methodName = typeof message?.payload?.name === "string"
    ? message.payload.name
    : "";
  const methodArgs = Array.isArray(message?.payload?.args)
    ? message.payload.args
    : [];
  const target = document.getElementById(id);

  if (!id || !target) {
    window.ShinyWebawesomeWarn.warn({
      key: "command_layer",
      message: `Could not find command target with id "${id}".`
    });
    return;
  }

  if (!methodName) {
    window.ShinyWebawesomeWarn.warn({
      key: "command_layer",
      message: "Missing method name for call_method command."
    });
    return;
  }

  if (typeof target[methodName] !== "function") {
    window.ShinyWebawesomeWarn.warn({
      key: "command_layer",
      message: `Method "${methodName}" is not available on target "${id}".`
    });
    return;
  }

  target[methodName](...methodArgs);
  window.ShinyWebawesomeWarn.debug(
    `call_method invoked "${methodName}" on target "${id}".`
  );
}

function registerShinyWebawesomeCommands() {
  if (!window.Shiny || typeof window.Shiny.addCustomMessageHandler !== "function") {
    return false;
  }

  if (window.__shinyWebawesomeCommandsRegistered) {
    return true;
  }

  window.__shinyWebawesomeCommandsRegistered = true;

  window.Shiny.addCustomMessageHandler("shiny.webawesome.command", (message) => {
    switch (message?.command) {
      case "set_property":
        handleSetPropertyCommand(message);
        break;
      case "call_method":
        handleCallMethodCommand(message);
        break;
      default:
        window.ShinyWebawesomeWarn.warn({
          key: "command_layer",
          message: `Unsupported command "${message?.command || ""}".`
        });
    }
  });

  return true;
}

setBasePath(basePath);

if (!registerShinyWebawesomeCommands()) {
  document.addEventListener("shiny:connected", registerShinyWebawesomeCommands, {
    once: true
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startLoader, { once: true });
} else {
  startLoader();
}
