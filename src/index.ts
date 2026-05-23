import type { App } from "@rovy/core";
import { createPhysicsControllerPlugin } from "./runtime/plugin";

export { App, rovy } from "@rovy/core";
export * from "./state";

import "./systems";

export function configurePhysicsController(app: App): App {
	return app.addPlugin(createPhysicsControllerPlugin());
}
