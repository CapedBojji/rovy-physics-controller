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
		if (this.instances !== undefined) return;

		const root_part = this.definition.root_part;
		const controller_parent = root_part.Parent;

		const controller_manager = new Instance("ControllerManager");
		controller_manager.Name = "ControllerManager";
		controller_manager.RootPart = root_part;
		controller_manager.BaseMoveSpeed = this.definition.walk_speed;
		controller_manager.BaseTurnSpeed = this.definition.base_turn_speed;
		controller_manager.FacingDirection = root_part.CFrame.LookVector;

		const ground_controller = new Instance("GroundController");
		ground_controller.Name = "GroundController";
		ground_controller.GroundOffset = this.definition.ground_offset;
		ground_controller.BalanceRigidityEnabled = true;
		ground_controller.Parent = controller_manager;

		const air_controller = new Instance("AirController");
		air_controller.Name = "AirController";
		air_controller.MaintainLinearMomentum = true;
		air_controller.MaintainAngularMomentum = false;
		air_controller.BalanceRigidityEnabled = true;
		air_controller.MoveMaxForce = 75_000;
		air_controller.Parent = controller_manager;

		const ground_sensor = new Instance("ControllerPartSensor");
		ground_sensor.Name = "GroundSensor";
		ground_sensor.SensorMode = Enum.SensorMode.Floor;
		ground_sensor.UpdateType = Enum.SensorUpdateType.OnRead;
		ground_sensor.SearchDistance = math.max(this.definition.ground_offset + root_part.Size.Y * 0.5 + 0.5, 1);
		ground_sensor.Parent = controller_manager;

		controller_manager.GroundSensor = ground_sensor;
		controller_manager.ActiveController = ground_controller;
		controller_manager.Parent = controller_parent;

		const instances = {
			controller_manager,
			ground_controller,
			air_controller,
			ground_sensor,
		} satisfies RigidBodyInstances;
		commands.set(entity, RigidBody, new RigidBody(this.definition, instances));
	}

	public is_grounded() {
		const sensed_part = this.instances?.ground_sensor.SensedPart;
		return sensed_part !== undefined;
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

	public set_move_direction(direction: Vector3, facing_direction: Vector3, entity: Entity, commands: Commands) {
		const mananger = this.instances?.controller_manager;
		if (mananger === undefined) return;
		mananger.MovingDirection = direction;
		mananger.FacingDirection = facing_direction;
		commands.set(entity, RigidBody, this);
	}
}

@component
export class PhysicsInput {
	constructor(
	public facing_direction = new Vector3(),
	public moving_direction = new Vector3()
	){}

	public update_inputs(commands: Commands, entity: Entity, facing_direction: Vector3, moving_direction: Vector3) {
		this.facing_direction = facing_direction;
		this.moving_direction = moving_direction;
		commands.set(entity, PhysicsInput, this);
	}
}
