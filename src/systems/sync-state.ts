import { Commands, Entity, Query, ResMut, system } from "@rovy/core";
import { PhysicsBody, PhysicsControllerConfig } from "../components";
import { PhysicsRuntimeStore } from "../resources";
import { syncGroundedTags } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeEventSet, PhysicsRuntimeStateSet } from "../state";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeStateSet, after: [PhysicsRuntimeEventSet] })
export class SyncPhysicsState {
	run(
		commands: Commands,
		entities: Query<[Entity, PhysicsControllerConfig, PhysicsBody]>,
		store: ResMut<PhysicsRuntimeStore>,
	) {
		entities.forEach((entity, _controller, _body) => {
			const runtime = store.entries[entity];
			if (runtime !== undefined) {
				syncGroundedTags(commands, entity, runtime);
			}
		});
	}
}
