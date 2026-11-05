extends RefCounted
## Geographic distances are compressed 10:1. Actors and furniture retain metre dimensions.
const DENOMINATOR := 10
const SPAN := 5760.0
const HALF := SPAN/2
const LEGACY_MULTIPLIER := 2.0
static func project(latitude: float,longitude: float) -> Vector2:
	return Vector2((longitude-168.363)*10600.0,-(latitude+17.6625)*11100.0)
static func migrate_position(at: Vector3,saved_scale: int) -> Vector3:
	return at*LEGACY_MULTIPLIER if saved_scale==20 else at
