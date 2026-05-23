import {
	type Added,
	type Commands,
	type Entity,
	type Query,
	system,
} from "@rovy/core";
import { RigidBody } from "../components";
import { Update } from "../state";

@system({ schedule: Update })
export class SetupRigidBody {
	run(
		bodies: Query<[Entity, RigidBody], Added<RigidBody>>,
		commands: Commands,
	) {
		bodies.forEach((entity, body) => {
			body.create_instances(entity, commands);
		});
	}
}
