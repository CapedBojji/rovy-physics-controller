import { Commands, Entity, Query, ResMut, system } from "@rovy/core";
import { PhysicsBody, PhysicsControllerConfig } from "../components";
import { PhysicsRuntimeStore } from "../resources";
import { ensureRuntime, isValidControlledBody, removeRuntime } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeAttachSet } from "../state";
import { Airborne, Grounded } from "../components";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeAttachSet })
export class AttachPhysicsRuntime {
	run(
		commands: Commands,
		entities: Query<[Entity, PhysicsControllerConfig, PhysicsBody]>,
		store: ResMut<PhysicsRuntimeStore>,
	) {
		entities.forEach((entity, controller, body) => {
			if (!isValidControlledBody(body)) {
				removeRuntime(store, entity);
				commands.remove(entity, Grounded);
				commands.remove(entity, Airborne);
				return;
			}
			ensureRuntime(store, entity, body, controller);
		});
	}
}
