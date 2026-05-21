import { DEFAULT_FACING, EPSILON, ZERO_VECTOR } from "../constants";
import { PhysicsInput } from "../components";
import { PhysicsRuntimeEntry } from "../resources";
import { clampHorizontalMoveInput, normalizeHorizontalFacing } from "./math";

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
