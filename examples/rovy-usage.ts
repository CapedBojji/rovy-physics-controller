import { App, Commands, Entity, Query, component, schedule, set, system } from "@rovy/core";
import {
	configurePhysicsController,
	ApplyImpulseEvent,
	PhysicsBody,
	PhysicsControllerConfig,
	PhysicsInput,
	PhysicsControllerUpdate,
} from "../src";

@component
export class PlayerTag {}

@schedule
export class Update {}

@set()
export abstract class InputSet {}

@set()
export abstract class MoveSet {}

@system({ schedule: Update, set: InputSet })
export class WritePlayerInput {
	run(players: Query<[Entity, PlayerTag, PhysicsInput]>) {
		players.forEach((_entity, _tag, input) => {
			input.facingDirection = Vector3.new(0, 0, -1);
			input.moveDirection = Vector3.new(0, 0, -1);
		});
	}
}

@system({ schedule: Update, set: MoveSet, after: [WritePlayerInput] })
export class DrivePhysicsController {
	run(commands: Commands, players: Query<[Entity, PlayerTag, PhysicsControllerConfig]>) {
		players.forEach((entity, _tag, config) => {
			if (config.walkSpeed >= 20) {
				commands.send(new ApplyImpulseEvent(entity, Vector3.new(0, 0, -12)));
			}
		});
	}
}

export function exampleUsage(app: App, rootPart: BasePart) {
	const entity = app.world.spawn(
		new PlayerTag(),
		new PhysicsControllerConfig(20),
		new PhysicsInput(),
		new PhysicsBody(rootPart),
	);

	configurePhysicsController(app);
	app.configureSets(Update, [InputSet, MoveSet]);
	app.runSchedule(PhysicsControllerUpdate);
	return entity;
}
