import { App } from "@rovy/core";
import {
	PhysicsControllerUpdate,
	PhysicsRuntimeAttachSet,
	PhysicsRuntimeCleanupSet,
	PhysicsRuntimeEventSet,
	PhysicsRuntimeInputSet,
	PhysicsRuntimeStateSet,
} from "./state";

export function configurePhysicsController(app: App): App {
	app.configureSets(PhysicsControllerUpdate, [
		PhysicsRuntimeAttachSet,
		PhysicsRuntimeInputSet,
		PhysicsRuntimeEventSet,
		PhysicsRuntimeStateSet,
		PhysicsRuntimeCleanupSet,
	]);
	return app;
}
