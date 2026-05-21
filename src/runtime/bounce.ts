import { BounceLocomotionConfig } from "../components";
import { EPSILON, ZERO_VECTOR } from "../constants";
import { PhysicsRuntimeEntry } from "../resources";
import {
	clampHorizontalVelocityToMax,
	computeBaseMoveVelocity,
	getHorizontalVector,
	steerHorizontalVelocityTowardIntent,
} from "./math";

function getCarryThreshold(config: BounceLocomotionConfig): number {
	return config.minCarryBounceThreshold ?? 0;
}

export function applyGroundBounce(runtime: PhysicsRuntimeEntry, config: BounceLocomotionConfig | undefined): void {
	if (!runtime.grounded) {
		runtime.airborneSinceLastBounce = true;
		runtime.wasGroundedLastFrame = false;
		return;
	}

	if (config === undefined || !config.enabled) {
		runtime.wasGroundedLastFrame = true;
		return;
	}

	if (!runtime.airborneSinceLastBounce) {
		runtime.wasGroundedLastFrame = true;
		return;
	}

	const baseMoveVelocity = computeBaseMoveVelocity(runtime.lastMoveDirection, runtime.lastWalkSpeed);
	let carryVelocity = runtime.carryVelocity;

	if (carryVelocity.Magnitude > EPSILON) {
		carryVelocity = steerHorizontalVelocityTowardIntent(
			carryVelocity,
			runtime.lastMoveDirection,
			config.carrySteerFactor,
		);
		carryVelocity = carryVelocity.mul(math.clamp(config.carryRetentionPerBounce, 0, 1));
		carryVelocity = clampHorizontalVelocityToMax(carryVelocity, config.maxCarrySpeed);
		if (carryVelocity.Magnitude < getCarryThreshold(config)) {
			carryVelocity = ZERO_VECTOR;
		}
	}

	runtime.carryVelocity = carryVelocity;

	const finalHorizontalVelocity = baseMoveVelocity.add(carryVelocity);
	runtime.rootPart.AssemblyLinearVelocity = new Vector3(
		finalHorizontalVelocity.X,
		math.max(0, config.groundBounceStrength),
		finalHorizontalVelocity.Z,
	);
	runtime.grounded = false;
	runtime.manager.ActiveController = runtime.airController;
	runtime.airborneSinceLastBounce = false;
	runtime.wasGroundedLastFrame = false;
}

export function applyJumpCarry(runtime: PhysicsRuntimeEntry, jumpPower: number): void {
	const config = runtime.lastBounceConfig;
	if (config === undefined || !config.enabled || jumpPower <= 0 || config.bigJumpCarryScale <= 0 || config.maxCarrySpeed <= 0) {
		return;
	}

	let launchDirection = runtime.lastMoveDirection;
	if (launchDirection.Magnitude <= EPSILON) {
		launchDirection = getHorizontalVector(runtime.rootPart.AssemblyLinearVelocity);
	}
	if (launchDirection.Magnitude <= EPSILON) {
		return;
	}
	launchDirection = launchDirection.div(launchDirection.Magnitude);

	const baseMoveVelocity = computeBaseMoveVelocity(runtime.lastMoveDirection, runtime.lastWalkSpeed);
	const addedCarry = launchDirection.mul(jumpPower * config.bigJumpCarryScale);
	const nextCarryVelocity = clampHorizontalVelocityToMax(runtime.carryVelocity.add(addedCarry), config.maxCarrySpeed);
	const nextHorizontalVelocity = baseMoveVelocity.add(nextCarryVelocity);

	runtime.carryVelocity = nextCarryVelocity;
	runtime.rootPart.AssemblyLinearVelocity = new Vector3(
		nextHorizontalVelocity.X,
		runtime.rootPart.AssemblyLinearVelocity.Y,
		nextHorizontalVelocity.Z,
	);
}
