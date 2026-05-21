import { type Entity, Commands } from "@rovy/core";
import { Airborne, Grounded, PhysicsBody, PhysicsControllerConfig } from "../components";
import { PhysicsRuntimeEntry, PhysicsRuntimeStore } from "../resources";
import { createRuntimeEntry, updateController } from "./controller";
import { refreshGrounded } from "./grounding";

export function isValidControlledBody(body: PhysicsBody): boolean {
	return body.rootPart.Parent !== undefined;
}

export function ensureRuntime(
	store: PhysicsRuntimeStore,
	entity: Entity,
	body: PhysicsBody,
	controller: PhysicsControllerConfig,
): PhysicsRuntimeEntry {
	const existing = store.entries[entity];
	if (existing !== undefined && existing.rootPart === body.rootPart) {
		updateController(existing, controller);
		return existing;
	}
	if (existing !== undefined) {
		destroyRuntime(existing);
	}

	const runtime = createRuntimeEntry(body);
	updateController(runtime, controller);
	refreshGrounded(runtime);
	runtime.wasGroundedLastFrame = false;
	runtime.airborneSinceLastBounce = true;
	store.entries[entity] = runtime;
	return runtime;
}

export function destroyRuntime(runtime: PhysicsRuntimeEntry): void {
	if (runtime.groundSensor.Parent !== undefined) {
		runtime.groundSensor.Destroy();
	}
	if (runtime.manager.Parent !== undefined) {
		runtime.manager.Destroy();
	}
}

export function removeRuntime(store: PhysicsRuntimeStore, entity: Entity): boolean {
	const runtime = store.entries[entity];
	if (runtime === undefined) {
		return false;
	}
	destroyRuntime(runtime);
	store.entries[entity] = undefined;
	return true;
}

export function cleanupRuntimes(
	commands: Commands,
	store: PhysicsRuntimeStore,
	active: ReadonlySet<Entity>,
): void {
	for (const [entityKey, runtime] of pairs(store.entries)) {
		if (runtime === undefined) {
			continue;
		}
		const entity = tonumber(entityKey) as Entity;
		if (entity === undefined || active.has(entity)) {
			continue;
		}
		destroyRuntime(runtime);
		store.entries[entity] = undefined;
		commands.remove(entity, Grounded);
		commands.remove(entity, Airborne);
	}
}
