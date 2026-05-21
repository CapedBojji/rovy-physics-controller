import { DEFAULT_JUMP_POWER, EPSILON } from "../constants";
import { PhysicsRuntimeEntry } from "../resources";
import { applyJumpCarry } from "./bounce";
import { refreshGrounded } from "./grounding";

export function applyJump(runtime: PhysicsRuntimeEntry, jumpPower = DEFAULT_JUMP_POWER): boolean {
	if (!refreshGrounded(runtime)) {
		return false;
	}

	const impulse = runtime.manager.UpDirection.mul(runtime.rootPart.AssemblyMass * jumpPower);
	runtime.lastJumpImpulse = impulse;
	runtime.lastAppliedImpulse = impulse;
	runtime.rootPart.ApplyImpulse(impulse);
	applyJumpCarry(runtime, jumpPower);
	runtime.grounded = false;
	runtime.manager.ActiveController = runtime.airController;
	runtime.airborneSinceLastBounce = false;
	runtime.wasGroundedLastFrame = false;
	return true;
}

export function applyImpulse(runtime: PhysicsRuntimeEntry, impulse: Vector3): void {
	runtime.lastAppliedImpulse = impulse;
	if (impulse.Magnitude <= EPSILON) {
		return;
	}
	runtime.rootPart.ApplyImpulse(impulse);
}
