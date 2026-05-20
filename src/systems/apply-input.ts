import { Commands, Entity, Optional, Query, ResMut, system } from "@rovy/core";
import { Airborne, Grounded, PhysicsBody, PhysicsControllerConfig, PhysicsInput } from "../components";
import { PhysicsRuntimeStore } from "../resources";
import { applyInput, ensureRuntime, isValidControlledBody, removeRuntime } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeAttachSet, PhysicsRuntimeInputSet } from "../state";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeInputSet, after: [PhysicsRuntimeAttachSet] })
export class ApplyPhysicsInput {
	run(
		commands: Commands,
		entities: Query<[Entity, PhysicsControllerConfig, PhysicsBody, Optional<PhysicsInput>]>,
		store: ResMut<PhysicsRuntimeStore>,
	) {
		entities.forEach((entity, controller, body, input) => {
			if (!isValidControlledBody(body)) {
				removeRuntime(store, entity);
				commands.remove(entity, Grounded);
				commands.remove(entity, Airborne);
				return;
			}
			const runtime = ensureRuntime(store, entity, body, controller);
			applyInput(runtime, input);
		});
	}
}
