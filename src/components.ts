import { component } from "@rovy/core";
import {
	DEFAULT_BIG_JUMP_CARRY_SCALE,
	DEFAULT_CARRY_RETENTION_PER_BOUNCE,
	DEFAULT_CARRY_STEER_FACTOR,
	DEFAULT_FACING,
	DEFAULT_GROUND_BOUNCE_STRENGTH,
	DEFAULT_MAX_CARRY_SPEED,
	DEFAULT_MIN_CARRY_BOUNCE_THRESHOLD,
	DEFAULT_WALK_SPEED,
	ZERO_VECTOR,
} from "./constants";

export interface FallSlowdownConfig {
	enabled: boolean;
	dragAcceleration: number;
}

export interface AirStrafeConfig {
	enabled: boolean;
	acceleration: number;
	maxHorizontalSpeed: number;
	fallSlowdown?: FallSlowdownConfig;
}

export interface BounceLocomotionConfig {
	enabled: boolean;
	groundBounceStrength: number;
	carryRetentionPerBounce: number;
	bigJumpCarryScale: number;
	maxCarrySpeed: number;
	carrySteerFactor: number;
	minCarryBounceThreshold?: number;
}

@component
export class PhysicsControllerConfig {
	constructor(
		public walkSpeed = DEFAULT_WALK_SPEED,
		public airStrafe?: AirStrafeConfig,
		public bounce: BounceLocomotionConfig = {
			enabled: true,
			groundBounceStrength: DEFAULT_GROUND_BOUNCE_STRENGTH,
			carryRetentionPerBounce: DEFAULT_CARRY_RETENTION_PER_BOUNCE,
			bigJumpCarryScale: DEFAULT_BIG_JUMP_CARRY_SCALE,
			maxCarrySpeed: DEFAULT_MAX_CARRY_SPEED,
			carrySteerFactor: DEFAULT_CARRY_STEER_FACTOR,
			minCarryBounceThreshold: DEFAULT_MIN_CARRY_BOUNCE_THRESHOLD,
		},
	) {}
}

@component
export class PhysicsInput {
	constructor(
		public facingDirection = DEFAULT_FACING,
		public moveDirection = ZERO_VECTOR,
	) {}
}

@component
export class PhysicsBody {
	constructor(public rootPart: BasePart) {}
}

@component
export class AirStrafeIntent {
	constructor(
		public direction = ZERO_VECTOR,
		public strength = 1,
	) {}
}

@component
export class Grounded {}

@component
export class Airborne {}
