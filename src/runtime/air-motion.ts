import { AirStrafeConfig, AirStrafeIntent, FallSlowdownConfig } from "../components";
import { EPSILON } from "../constants";
import { PhysicsRuntimeEntry } from "../resources";
import { clampHorizontalVelocityToMax, getHorizontalVector } from "./math";

export function applyAirStrafe(
	runtime: PhysicsRuntimeEntry,
	intent: AirStrafeIntent | undefined,
	config: AirStrafeConfig | undefined,
	dt: number,
): void {
	if (config === undefined || !config.enabled || intent === undefined || runtime.grounded || dt <= 0) {
		return;
	}

	let direction = getHorizontalVector(intent.direction);
	if (direction.Magnitude <= EPSILON) {
		return;
	}
	direction = direction.div(direction.Magnitude);

	const strength = math.clamp(intent.strength, 0, 1);
	if (strength <= 0 || config.acceleration <= 0 || config.maxHorizontalSpeed <= 0) {
		return;
	}

	const currentVelocity = runtime.rootPart.AssemblyLinearVelocity;
	let horizontalVelocity = getHorizontalVector(currentVelocity);
	horizontalVelocity = horizontalVelocity.add(direction.mul(config.acceleration * strength * dt));
	horizontalVelocity = clampHorizontalVelocityToMax(horizontalVelocity, config.maxHorizontalSpeed);

	runtime.rootPart.AssemblyLinearVelocity = new Vector3(
		horizontalVelocity.X,
		currentVelocity.Y,
		horizontalVelocity.Z,
	);
}

export function applyAirborneFallSlowdown(
	runtime: PhysicsRuntimeEntry,
	config: FallSlowdownConfig | undefined,
	dt: number,
): void {
	if (config === undefined || !config.enabled || config.dragAcceleration <= 0 || runtime.grounded || dt <= 0) {
		return;
	}

	const currentVelocity = runtime.rootPart.AssemblyLinearVelocity;
	if (currentVelocity.Y >= 0) {
		return;
	}

	const nextY = math.min(0, currentVelocity.Y + config.dragAcceleration * dt);
	runtime.rootPart.AssemblyLinearVelocity = new Vector3(
		currentVelocity.X,
		nextY,
		currentVelocity.Z,
	);
}
