import { SystemSet, schedule, set } from "@rovy/core";

@schedule
export class PhysicsControllerUpdate {}

@set()
export class PhysicsRuntimeAttachSet extends SystemSet {}

@set()
export class PhysicsRuntimeInputSet extends SystemSet {}

@set()
export class PhysicsRuntimeEventSet extends SystemSet {}

@set()
export class PhysicsRuntimeStateSet extends SystemSet {}

@set()
export class PhysicsRuntimeCleanupSet extends SystemSet {}
