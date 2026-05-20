import { EventReader, ResMut, system } from "@rovy/core";
import { ApplyImpulseEvent, JumpEvent } from "../events";
import { PhysicsRuntimeStore } from "../resources";
import { applyImpulse, applyJump } from "../runtime-helpers";
import { PhysicsControllerUpdate, PhysicsRuntimeEventSet, PhysicsRuntimeInputSet } from "../state";

@system({ schedule: PhysicsControllerUpdate, set: PhysicsRuntimeEventSet, after: [PhysicsRuntimeInputSet] })
export class ApplyPhysicsControllerEvents {
  run(
    jumps: EventReader<JumpEvent>,
    impulses: EventReader<ApplyImpulseEvent>,
    store: ResMut<PhysicsRuntimeStore>,
  ) {
    jumps.forEach((event) => {
      const runtime = store.entries[event.target];
      if (runtime !== undefined) {
        applyJump(runtime, event.jumpPower);
      }
    });

    impulses.forEach((event) => {
      const runtime = store.entries[event.target];
      if (runtime !== undefined) {
        applyImpulse(runtime, event.impulse);
      }
    });
  }
}
