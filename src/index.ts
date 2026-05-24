import { type App, type Plugin, plugin } from "@rovy/core";

export { App, rovy } from "@rovy/core";

@plugin
export class PhysicsControllerPlugin implements Plugin {
	build(_app: App): void {
		require(script.WaitForChild("state") as ModuleScript);
		require(script.WaitForChild("components") as ModuleScript);
		require((script.WaitForChild("systems") as Folder).WaitForChild("setup-rigid-body") as ModuleScript);
		require((script.WaitForChild("systems") as Folder).WaitForChild("process-physics-inputs") as ModuleScript);
	}
}
