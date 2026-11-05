extends RefCounted
## Exact rendered road segments, not the coarse distance texture used for terrain paint.
static func clearance(world,point: Vector2) -> float:
	var result := INF
	var cell := Vector2i(floori(point.x/world.ROAD_CELL),floori(point.y/world.ROAD_CELL))
	for segment in world.road_grid.get(cell,[]):
		result=minf(result,Geometry2D.get_closest_point_to_segment(point,segment[0],segment[1]).distance_to(point)-segment[2])
	return result
static func rect_clear(world,at: Vector2,yaw: float,rect: Rect2,margin := .65) -> bool:
	var basis := Basis(Vector3.UP,yaw)
	var radius := maxf(rect.position.length(),rect.end.length())+12
	var low := Vector2i(floori((at.x-radius)/world.ROAD_CELL),floori((at.y-radius)/world.ROAD_CELL))
	var high := Vector2i(floori((at.x+radius)/world.ROAD_CELL),floori((at.y+radius)/world.ROAD_CELL))
	var seen := {}
	for x in range(low.x,high.x+1):
		for z in range(low.y,high.y+1):
			for segment in world.road_grid.get(Vector2i(x,z),[]):
				var key := str(segment[0])+str(segment[1])+str(segment[2])
				if seen.has(key): continue
				seen[key]=true
				var aa: Vector3=basis.inverse()*Vector3(segment[0].x-at.x,0,segment[0].y-at.y)
				var bb: Vector3=basis.inverse()*Vector3(segment[1].x-at.x,0,segment[1].y-at.y)
				var a := Vector2(aa.x,aa.z);var b := Vector2(bb.x,bb.z)
				var expanded := rect.grow(segment[2]+margin)
				if expanded.has_point(a) or expanded.has_point(b): return false
				var p := expanded.position;var e := expanded.end
				var corners := [p,Vector2(e.x,p.y),e,Vector2(p.x,e.y)]
				for i in range(4):
					if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4])!=null: return false
	return true
static func house_rect(w: float,d: float,shop: bool) -> Rect2:
	return Rect2(Vector2(-w/2-.35,-d/2-.35),Vector2(w+.7,d+3.5)) if shop else Rect2(Vector2(-w*.57,-d*.56),Vector2(w*1.14,d*1.36+.25))
