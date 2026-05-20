import { Commands, Entity, Query, ResMut, system } from "@rovy/core";
import { PhysicsBody, PhysicsControllerConfig } from "../components";
import { PhysicsRuntimeStore } from "../resources";
import { cleanupRuntimes, isValidControlledBody } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeCleanupSet, PhysicsRuntimeEventSet } from "../state";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeCleanupSet, after: [PhysicsRuntimeEventSet] })
export class CleanupPhysicsRuntime {
	run(
		commands: Commands,
		entities: Query<[Entity, PhysicsControllerConfig, PhysicsBody]>,
		store: ResMut<PhysicsRuntimeStore>,
	) {
		const active = new Set<Entity>();
		entities.forEach((entity, _controller, body) => {
			if (!isValidControlledBody(body)) {
				return;
			}
			active.add(entity);
		});
		cleanupRuntimes(commands, store, active);
	}
}
