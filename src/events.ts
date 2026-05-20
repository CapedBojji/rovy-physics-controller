import { Entity, event } from "@rovy/core";

@event({ capacity: 64 })
export class JumpEvent {
	constructor(
		public target: Entity,
		public jumpPower?: number,
	) {}
}

@event({ capacity: 64 })
export class ApplyImpulseEvent {
	constructor(
		public target: Entity,
		public impulse: Vector3,
	) {}
}
