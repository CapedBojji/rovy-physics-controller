import { Commands, Entity } from "@rovy/core";
import { Airborne, Grounded } from "../components";
import { PhysicsRuntimeEntry } from "../resources";

export function refreshGrounded(runtime: PhysicsRuntimeEntry): boolean {
	let grounded = false;
	const currentVelocity = runtime.rootPart.AssemblyLinearVelocity;

	if (currentVelocity.Y > 0) {
		runtime.grounded = false;
		runtime.manager.ActiveController = runtime.airController;
		return false;
	}

	const sensedPart = runtime.groundSensor.SensedPart;
	if (sensedPart !== undefined && sensedPart !== runtime.rootPart) {
		grounded = true;
	} else if (currentVelocity.Y <= 0) {
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

export function syncGroundedTags(commands: Commands, entity: Entity, runtime: PhysicsRuntimeEntry): void {
	if (runtime.grounded) {
		commands.insert(entity, new Grounded());
		commands.remove(entity, Airborne);
		return;
	}

	commands.insert(entity, new Airborne());
	commands.remove(entity, Grounded);
}
