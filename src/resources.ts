import { Entity, resource } from "@rovy/core";
import type { BounceLocomotionConfig } from "./components";

export interface PhysicsRuntimeEntry {
	readonly manager: ControllerManager;
	readonly groundController: GroundController;
	readonly airController: AirController;
	readonly groundSensor: ControllerPartSensor;
	readonly rootPart: BasePart;
	lastFacingDirection: Vector3;
	lastMoveDirection: Vector3;
	lastWalkSpeed: number;
	lastBounceConfig?: BounceLocomotionConfig;
	lastAppliedImpulse: Vector3;
	lastJumpImpulse: Vector3;
	carryVelocity: Vector3;
	grounded: boolean;
	wasGroundedLastFrame: boolean;
	airborneSinceLastBounce: boolean;
}

@resource
export class PhysicsRuntimeStore {
	entries: Record<Entity, PhysicsRuntimeEntry | undefined> = {};
}

@resource
export class PhysicsControllerTime {
	lastClock?: number;
}
