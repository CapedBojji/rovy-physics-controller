import { type Commands, component, type Entity } from "@rovy/core";

interface RigidBodyInstances {
	controller_manager: ControllerManager;
	ground_controller: GroundController;
	air_controller: AirController;
	ground_sensor: ControllerPartSensor;
}

interface RigitBodyDefinition {
	root_part: BasePart;
	walk_speed: number;
	base_turn_speed: number;
	ground_offset: number;
}

@component
export class RigidBody {
	constructor(
		public readonly definition: Readonly<RigitBodyDefinition>,
		public readonly instances?: Readonly<RigidBodyInstances>,
	) {}

	public destroy(entity: Entity, commands: Commands) {
		this.instances?.controller_manager.Destroy();
		this.instances?.ground_controller.Destroy();
		this.instances?.air_controller.Destroy();
		this.instances?.ground_sensor.Destroy();
		commands.remove(entity, RigidBody);
	}

	public create_instances(entity: Entity, commands: Commands) {
		const controller_manager = new Instance("ControllerManager");
		controller_manager.Name = `${this.definition.root_part.Name}_ControllerManager`;
		controller_manager.Parent = this.definition.root_part;

		const ground_controller = new Instance("GroundController");
		ground_controller.Name = `${this.definition.root_part.Name}_GroundController`;
		ground_controller.Parent = controller_manager;

		const air_controller = new Instance("AirController");
		air_controller.Name = `${this.definition.root_part.Name}_AirController`;
		air_controller.Parent = controller_manager;

		const ground_sensor = new Instance("ControllerPartSensor");
		ground_sensor.Name = `${this.definition.root_part.Name}_GroundSensor`;
		ground_sensor.Parent = controller_manager;

		controller_manager.GroundSensor = ground_sensor;
		ground_sensor.UpdateType = Enum.SensorUpdateType.OnRead;
		ground_sensor.SensorMode = Enum.SensorMode.Floor;

		commands.set(entity, RigidBody, this);
	}

	public is_grounded() {
		const sensed_part = this.instances?.ground_sensor.SensedPart;
		return sensed_part === undefined;
	}

	public ground_sensor_data() {
		const sensor = this.instances?.ground_sensor;
		if (sensor === undefined) return;
		return {
			hit_normal: sensor.HitNormal,
			hit_frame: sensor.HitFrame,
			sensed_part: sensor.SensedPart,
		};
	}

	public set_walk_speed(speed: number, entity: Entity, commands: Commands) {
		const mananger = this.instances?.controller_manager;
		if (mananger === undefined) return;
		mananger.BaseMoveSpeed = speed;
		commands.set(entity, RigidBody, this);
	}
}
