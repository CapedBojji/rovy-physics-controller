import { component } from "@rovy/core";
import { DEFAULT_FACING, DEFAULT_WALK_SPEED, ZERO_VECTOR } from "./constants";

@component
export class PhysicsControllerConfig {
	constructor(public walkSpeed = DEFAULT_WALK_SPEED) {}
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
export class Grounded {}

@component
export class Airborne {}
