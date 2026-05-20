import { Entity, resource } from "@rovy/core";

export interface PhysicsRuntimeEntry {
	readonly manager: ControllerManager;
	readonly groundController: GroundController;
	readonly airController: AirController;
	readonly groundSensor: ControllerPartSensor;
	readonly rootPart: BasePart;
	lastFacingDirection: Vector3;
	lastMoveDirection: Vector3;
	lastWalkSpeed: number;
	lastAppliedImpulse: Vector3;
	lastJumpImpulse: Vector3;
	grounded: boolean;
}

@resource
export class PhysicsRuntimeStore {
	entries: Record<Entity, PhysicsRuntimeEntry | undefined> = {};
}
