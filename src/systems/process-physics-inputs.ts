import { Commands, Entity, Query, system } from "@rovy/core";
import { PhysicsInput, RigidBody } from "../components";
import { Update } from "../state";



@system({schedule: Update})
export class ProcessPhysicsInputs {
    run(query: Query<[Entity, PhysicsInput, RigidBody]>, commands: Commands) {
        query.forEach((entity, input, body) => {
            body.set_move_direction(input.moving_direction, input.facing_direction, entity, commands);
        });
    }
}
