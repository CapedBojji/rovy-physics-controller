import type { App, Plugin } from "@rovy/core";

export function createPhysicsControllerPlugin(): Plugin {
	return {
		build(_app: App): void {
			// TODO: register schedules, resources, and controller systems here.
		},
	};
}

export function configurePhysicsController(app: App): App {
	return app.addPlugin(createPhysicsControllerPlugin());
}
