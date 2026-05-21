import { Entity, Optional, Query, ResMut, system } from "@rovy/core";
import { AirStrafeIntent, PhysicsBody, PhysicsControllerConfig } from "../components";
import { PhysicsControllerTime, PhysicsRuntimeStore } from "../resources";
import { applyAirStrafe, applyAirborneFallSlowdown } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeInputSet } from "../state";
import { ApplyPhysicsInput } from "./apply-input";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeInputSet, after: [ApplyPhysicsInput] })
export class ApplyAirStrafe {
	run(
		entities: Query<[Entity, PhysicsControllerConfig, PhysicsBody, Optional<AirStrafeIntent>]>,
		store: ResMut<PhysicsRuntimeStore>,
		time: ResMut<PhysicsControllerTime>,
	) {
		const now = os.clock();
		const dt = time.lastClock === undefined ? 0 : math.max(0, now - time.lastClock);
		time.lastClock = now;

		entities.forEach((entity, controller, _body, intent) => {
			const runtime = store.entries[entity];
			if (runtime !== undefined) {
				applyAirStrafe(runtime, intent, controller.airStrafe, dt);
				applyAirborneFallSlowdown(runtime, controller.airStrafe?.fallSlowdown, dt);
			}
		});
	}
}
