import { DEFAULT_FACING, EPSILON, ZERO_VECTOR } from "../constants";

export function getHorizontalVector(vector: Vector3): Vector3 {
	return new Vector3(vector.X, 0, vector.Z);
}

export function normalizeHorizontalFacing(direction: Vector3, fallback: Vector3): Vector3 {
	const flat = getHorizontalVector(direction);
	const magnitude = flat.Magnitude;
	if (magnitude <= EPSILON) {
		return fallback;
	}
	return flat.div(magnitude);
}

export function clampHorizontalMoveInput(direction: Vector3): Vector3 {
	const flat = getHorizontalVector(direction);
	const magnitude = flat.Magnitude;
	if (magnitude <= EPSILON) {
		return ZERO_VECTOR;
	}
	if (magnitude > 1) {
		return flat.div(magnitude);
	}
	return flat;
}

export function computeBaseMoveVelocity(direction: Vector3, walkSpeed: number): Vector3 {
	return clampHorizontalMoveInput(direction).mul(math.max(0, walkSpeed));
}

export function clampHorizontalVelocityToMax(direction: Vector3, maxSpeed: number): Vector3 {
	const flat = getHorizontalVector(direction);
	const magnitude = flat.Magnitude;
	if (magnitude <= EPSILON || maxSpeed <= 0) {
		return ZERO_VECTOR;
	}
	if (magnitude <= maxSpeed) {
		return flat;
	}
	return flat.div(magnitude).mul(maxSpeed);
}

export function steerHorizontalVelocityTowardIntent(
	current: Vector3,
	intent: Vector3,
	factor: number,
): Vector3 {
	const flatCurrent = getHorizontalVector(current);
	const currentMagnitude = flatCurrent.Magnitude;
	if (currentMagnitude <= EPSILON) {
		return ZERO_VECTOR;
	}

	const flatIntent = clampHorizontalMoveInput(intent);
	if (flatIntent.Magnitude <= EPSILON) {
		return flatCurrent;
	}

	const steerFactor = math.clamp(factor, 0, 1);
	if (steerFactor <= 0) {
		return flatCurrent;
	}

	const currentDirection = flatCurrent.div(currentMagnitude);
	const blended = currentDirection.mul(1 - steerFactor).add(flatIntent.mul(steerFactor));
	if (blended.Magnitude <= EPSILON) {
		return flatCurrent;
	}
	return blended.div(blended.Magnitude).mul(currentMagnitude);
}

export function resolveHorizontalDirection(
	direction: Vector3,
	fallback = DEFAULT_FACING,
): Vector3 {
	return normalizeHorizontalFacing(direction, fallback);
}
