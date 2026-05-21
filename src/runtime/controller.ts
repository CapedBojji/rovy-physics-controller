import { PhysicsBody, PhysicsControllerConfig } from "../components";
import { DEFAULT_FACING, DEFAULT_GROUND_SEARCH_DISTANCE, DEFAULT_TURN_SPEED, UP_VECTOR, ZERO_VECTOR } from "../constants";
import { PhysicsRuntimeEntry } from "../resources";

export function createRuntimeEntry(body: PhysicsBody): PhysicsRuntimeEntry {
	const manager = new Instance("ControllerManager");
	manager.Name = "PhysicsControllerManager";
	manager.Parent = body.rootPart;
	manager.RootPart = body.rootPart;
	manager.UpDirection = UP_VECTOR;
	manager.BaseTurnSpeed = DEFAULT_TURN_SPEED;

	const groundController = new Instance("GroundController");
	groundController.Name = "PhysicsGroundController";
	groundController.Parent = manager;
	groundController.MoveSpeedFactor = 1;
	groundController.TurnSpeedFactor = 1;

	const airController = new Instance("AirController");
	airController.Name = "PhysicsAirController";
	airController.Parent = manager;
	airController.MoveSpeedFactor = 1;
	airController.TurnSpeedFactor = 1;

	const groundSensor = new Instance("ControllerPartSensor");
	groundSensor.Name = "PhysicsGroundSensor";
	groundSensor.Parent = body.rootPart;
	groundSensor.SensorMode = Enum.SensorMode.Floor;
	groundSensor.SearchDistance = DEFAULT_GROUND_SEARCH_DISTANCE;
	groundSensor.UpdateType = Enum.SensorUpdateType.OnRead;

	manager.GroundSensor = groundSensor;

	return {
		manager,
		groundController,
		airController,
		groundSensor,
		rootPart: body.rootPart,
		lastFacingDirection: DEFAULT_FACING,
		lastMoveDirection: ZERO_VECTOR,
		lastWalkSpeed: 0,
		lastBounceConfig: undefined,
		lastAppliedImpulse: ZERO_VECTOR,
		lastJumpImpulse: ZERO_VECTOR,
		carryVelocity: ZERO_VECTOR,
		grounded: false,
		wasGroundedLastFrame: false,
		airborneSinceLastBounce: true,
	};
}

export function updateController(runtime: PhysicsRuntimeEntry, controller: PhysicsControllerConfig): void {
	runtime.lastWalkSpeed = controller.walkSpeed;
	runtime.lastBounceConfig = controller.bounce;
	runtime.manager.BaseMoveSpeed = controller.bounce.enabled ? 0 : controller.walkSpeed;
	runtime.manager.UpDirection = UP_VECTOR;
}
