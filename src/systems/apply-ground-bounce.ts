import { Entity, Query, ResMut, system } from "@rovy/core";
import { PhysicsBody, PhysicsControllerConfig } from "../components";
import { PhysicsRuntimeStore } from "../resources";
import { applyGroundBounce, refreshGrounded } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeEventSet, PhysicsRuntimeStateSet } from "../state";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeStateSet, after: [PhysicsRuntimeEventSet] })
export class ApplyGroundBounce {
	run(
		entities: Query<[Entity, PhysicsControllerConfig, PhysicsBody]>,
		store: ResMut<PhysicsRuntimeStore>,
	) {
		entities.forEach((entity, controller, _body) => {
			const runtime = store.entries[entity];
			if (runtime === undefined) {
				return;
			}
			refreshGrounded(runtime);
			applyGroundBounce(runtime, controller.bounce);
		});
	}
}
