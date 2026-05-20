import { type Entity, Commands } from "@rovy/core";
import {
	Airborne,
	Grounded,
	PhysicsBody,
	PhysicsControllerConfig,
	PhysicsInput,
} from "./components";
import {
	DEFAULT_FACING,
	DEFAULT_GROUND_SEARCH_DISTANCE,
	DEFAULT_JUMP_POWER,
	DEFAULT_TURN_SPEED,
	EPSILON,
	UP_VECTOR,
	ZERO_VECTOR,
} from "./constants";
import { type PhysicsRuntimeEntry, PhysicsRuntimeStore } from "./resources";

function createRuntimeEntry(body: PhysicsBody): PhysicsRuntimeEntry {
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
		lastAppliedImpulse: ZERO_VECTOR,
		lastJumpImpulse: ZERO_VECTOR,
		grounded: false,
	};
}

/**
 * Flattens a direction onto the XZ plane and normalizes it into a unit vector.
 *
 * Returns `fallback` when the horizontal portion is too small to produce a
 * stable facing direction.
 */
function normalizeHorizontalFacing(direction: Vector3, fallback: Vector3): Vector3 {
	const flat = new Vector3(direction.X, 0, direction.Z);
	const magnitude = flat.Magnitude;
	if (magnitude <= EPSILON) {
		return fallback;
	}
	return flat.div(magnitude);
}

/**
 * Flattens movement onto the XZ plane and clamps its magnitude to at most `1`.
 *
 * This preserves analog-style input strength below `1` while keeping larger
 * inputs in the controller's expected unit range.
 */
function clampHorizontalMoveInput(direction: Vector3): Vector3 {
	const flat = new Vector3(direction.X, 0, direction.Z);
	const magnitude = flat.Magnitude;
	if (magnitude <= EPSILON) {
		return ZERO_VECTOR;
	}
	if (magnitude > 1) {
		return flat.div(magnitude);
	}
	return flat;
}

/**
 * Checks whether the configured physics root still still exists.
 */
export function isValidControlledBody(body: PhysicsBody): boolean {
	return body.rootPart.Parent !== undefined;
}

/**
 * Returns an entity runtime, creating or recreating the Roblox control objects
 * when the entity's body/model pair changed.
 */
export function ensureRuntime(
	store: PhysicsRuntimeStore,
	entity: Entity,
	body: PhysicsBody,
	controller: PhysicsControllerConfig,
): PhysicsRuntimeEntry {
	const existing = store.entries[entity];
	if (existing !== undefined && existing.rootPart === body.rootPart) {
		updateController(existing, controller);
		return existing;
	}
	if (existing !== undefined) {
		destroyRuntime(existing);
	}

	const runtime = createRuntimeEntry(body);

	updateController(runtime, controller);
	refreshGrounded(runtime);
	store.entries[entity] = runtime;
	return runtime;
}

/**
 * Pushes component config into the live `ControllerManager` state.
 */
export function updateController(runtime: PhysicsRuntimeEntry, controller: PhysicsControllerConfig): void {
	runtime.lastWalkSpeed = controller.walkSpeed;
	runtime.manager.BaseMoveSpeed = controller.walkSpeed;
	runtime.manager.UpDirection = UP_VECTOR;
}

/**
 * Refreshes grounded state from the sensor first, then falls back to a short
 * downward raycast when the sensor does not currently report a usable floor.
 */
export function refreshGrounded(runtime: PhysicsRuntimeEntry): boolean {
	let grounded = false;

	const sensedPart = runtime.groundSensor.SensedPart;
	if (sensedPart !== undefined && sensedPart !== runtime.rootPart) {
		grounded = true;
	} else {
		const workspace = game.GetService("Workspace");
		const params = new RaycastParams();
		params.FilterType = Enum.RaycastFilterType.Exclude;
		params.FilterDescendantsInstances = [runtime.rootPart];
		const result = workspace.Raycast(
			runtime.rootPart.Position,
			runtime.manager.UpDirection.mul(-runtime.groundSensor.SearchDistance),
			params,
		);
		grounded = result !== undefined;
	}

	runtime.grounded = grounded;
	runtime.manager.ActiveController = grounded ? runtime.groundController : runtime.airController;
	return grounded;
}

/**
 * Applies the latest input component to controller-facing Roblox state.
 *
 * Facing is always normalized horizontally, while movement preserves analog
 * magnitude until it exceeds the unit range.
 */
export function applyInput(runtime: PhysicsRuntimeEntry, input?: PhysicsInput): void {
	const facingFallback = runtime.lastFacingDirection.Magnitude > EPSILON ? runtime.lastFacingDirection : DEFAULT_FACING;
	const nextFacing = input ? normalizeHorizontalFacing(input.facingDirection, facingFallback) : facingFallback;
	const nextMove = input ? clampHorizontalMoveInput(input.moveDirection) : ZERO_VECTOR;

	runtime.lastFacingDirection = nextFacing;
	runtime.lastMoveDirection = nextMove;
	runtime.manager.FacingDirection = nextFacing;
	runtime.manager.MovingDirection = nextMove;
	runtime.manager.ActiveController = runtime.grounded ? runtime.groundController : runtime.airController;
}

/**
 * Applies a jump impulse when the entity is currently grounded.
 *
 * Uses the provided scalar jump power when present, otherwise falls back to the
 * package default. Returns `true` only when a jump was actually performed.
 */
export function applyJump(runtime: PhysicsRuntimeEntry, jumpPower = DEFAULT_JUMP_POWER): boolean {
	if (!refreshGrounded(runtime)) {
		return false;
	}

	const impulse = runtime.manager.UpDirection.mul(runtime.rootPart.AssemblyMass * jumpPower);
	runtime.lastJumpImpulse = impulse;
	runtime.lastAppliedImpulse = impulse;
	runtime.rootPart.ApplyImpulse(impulse);
	runtime.grounded = false;
	runtime.manager.ActiveController = runtime.airController;
	return true;
}

/**
 * Applies an arbitrary impulse event to the controlled root part and records
 * the last requested impulse for test/debug visibility.
 */
export function applyImpulse(runtime: PhysicsRuntimeEntry, impulse: Vector3): void {
	runtime.lastAppliedImpulse = impulse;
	if (impulse.Magnitude <= EPSILON) {
		return;
	}
	runtime.rootPart.ApplyImpulse(impulse);
}

/**
 * Keeps the public `Grounded` and `Airborne` tags in sync with the current
 * sensed locomotion state.
 */
export function syncGroundedTags(commands: Commands, entity: Entity, runtime: PhysicsRuntimeEntry): void {
	if (refreshGrounded(runtime)) {
		commands.insert(entity, new Grounded());
		commands.remove(entity, Airborne);
		return;
	}
	commands.insert(entity, new Airborne());
	commands.remove(entity, Grounded);
}

/**
 * Destroys the Roblox instances owned by a runtime entry.
 */
export function destroyRuntime(runtime: PhysicsRuntimeEntry): void {
	if (runtime.groundSensor.Parent !== undefined) {
		runtime.groundSensor.Destroy();
	}
	if (runtime.manager.Parent !== undefined) {
		runtime.manager.Destroy();
	}
}

/**
 * Removes an entity runtime from the store and destroys any owned instances.
 *
 * Returns `true` when a runtime was present.
 */
export function removeRuntime(store: PhysicsRuntimeStore, entity: Entity): boolean {
	const runtime = store.entries[entity];
	if (runtime === undefined) {
		return false;
	}
	destroyRuntime(runtime);
	store.entries[entity] = undefined;
	return true;
}

/**
 * Destroys runtimes for entities that are no longer active in the controller
 * query and clears their public locomotion tags.
 */
export function cleanupRuntimes(
	commands: Commands,
	store: PhysicsRuntimeStore,
	active: ReadonlySet<Entity>,
): void {
	for (const [entityKey, runtime] of pairs(store.entries)) {
		if (runtime === undefined) {
			continue;
		}
		const entity = tonumber(entityKey) as Entity;
		if (entity === undefined || active.has(entity)) {
			continue;
		}
		destroyRuntime(runtime);
		store.entries[entity] = undefined;
		commands.remove(entity, Grounded);
		commands.remove(entity, Airborne);
	}
}
