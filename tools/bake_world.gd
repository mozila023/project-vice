extends SceneTree
## Offline world bake:  godot --headless --path . --script res://tools/bake_world.gd
## Output: assets/baked/world.dat (heights, placements, foliage buffers) and terrain_macro/terrain_data maps.
## Doing this ahead of time is what keeps first load short on phones and in the browser.

const RES := 2048
const SPAN := 5760.0
const PIXEL := SPAN/RES
const SURFACE_RES := 720
const FAR_CHUNK := 240.0
const PALM_CHUNK := 80.0
const LAND := 240
const LAND_STEP := 24.0
## One game building stands for roughly this many mapped ones; keeps the town light enough for phones.
const MAX_BUILDINGS := 1100
const BUCKET := 40.0

var world
var rng := RandomNumberGenerator.new()
var road_dist := PackedFloat32Array()
var buildings: Array=[]
var building_buckets := {}
var meta := {}
var heights := PackedFloat32Array()
var land_density := PackedByteArray()
var land_shops := PackedByteArray()
var land_class := PackedByteArray()
var rejected := {}
var pole_points: Array[Vector3] = []

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	rng.seed=20261104
	world=load("res://scripts/tropical_world.gd").new()
	meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/baked/foliage_meta.json"))
	var cover := FileAccess.get_file_as_bytes("res://assets/geography/land-cover.bin")
	land_density=cover.slice(0,LAND*LAND*2)
	land_shops=cover.slice(LAND*LAND*2,LAND*LAND*4)
	land_class=cover.slice(LAND*LAND*4)
	bake_heights()
	world.heights=heights
	grade_roads()
	limit_slopes()
	world.heights=heights
	bake_road_distance()
	var poles := place_buildings()
	var images := paint_maps()
	images[0].save_png("res://assets/baked/terrain_macro.png")
	images[1].save_png("res://assets/baked/terrain_data.png")
	var data := {"version":2,"map_scale":10,"heights":heights,"buildings":buildings,"poles":poles,"surface":images[2]}
	data.merge(place_flora())
	data["rocks"]=place_rocks()
	var file := FileAccess.open("res://assets/baked/world.dat",FileAccess.WRITE)
	file.store_buffer(var_to_bytes(data))
	file.close()
	print("BAKE buildings=%d poles=%d ms=%d" % [buildings.size(),poles.size(),Time.get_ticks_msec()-started])
	quit()

func bake_heights() -> void:
	var n: int=world.GRID_N
	heights.resize(n*n)
	for z in range(n):
		for x in range(n):
			heights[z*n+x]=world.raw_height(world.GRID_MIN+x*world.GRID_STEP,world.GRID_MIN+z*world.GRID_STEP)
	flatten_settlements()

## Efate's towns sit on the low coastal terraces, but the procedural hills are far steeper than the real land.
## Wherever the map shows buildings, the ground eases down to a gentle plain with a wide, soft transition.
func flatten_settlements() -> void:
	var n: int=world.GRID_N
	# Summed-area table: a box blur about 280 m across, so the plain rises into the hills gradually.
	var side := LAND+1
	var table := PackedFloat32Array()
	table.resize(side*side)
	for cz in range(LAND):
		for cx in range(LAND):
			table[(cz+1)*side+cx+1]=land_density.decode_u16((cz*LAND+cx)*2)+table[cz*side+cx+1]+table[(cz+1)*side+cx]-table[cz*side+cx]
	for z in range(n):
		for x in range(n):
			var at: int=z*n+x
			var h: float=heights[at]
			var p := Vector2(world.GRID_MIN+x*world.GRID_STEP,world.GRID_MIN+z*world.GRID_STEP)
			var cx := clampi(int((p.x+SPAN/2)/LAND_STEP),0,LAND-1)
			var cz := clampi(int((p.y+SPAN/2)/LAND_STEP),0,LAND-1)
			var x0 := maxi(0,cx-11)
			var x1 := mini(LAND,cx+12)
			var z0 := maxi(0,cz-11)
			var z1 := mini(LAND,cz+12)
			var count: float=table[z1*side+x1]-table[z0*side+x1]-table[z1*side+x0]+table[z0*side+x0]
			var built: float=smoothstep(3.0,70.0,count)
			if h>3.5:
				heights[at]=lerpf(h,3.5+(h-3.5)*0.1,built)
			else:
				# In town the shoreline stays put but the beach narrows, so streets are not laid out on sand.
				# Mele keeps its wide beach: it is the player's home and the game's fishing shore.
				var edge: float=world.coast_distance(p)
				var away: float=smoothstep(120.0,220.0,p.distance_to(world.TOWN))
				if edge>4.0: heights[at]=lerpf(h,maxf(h,3.3),built*away*smoothstep(4.0,14.0,edge))

## Caps hillsides at about 30 degrees by lowering whatever stands too far above its neighbours. Only ever cuts, so
## graded roads and the shoreline are unaffected, and two sweeps are enough to settle the whole grid.
func limit_slopes() -> void:
	var n: int=world.GRID_N
	var rise := 7.0
	var diagonal: float=rise*sqrt(2.0)
	for z in range(n):
		for x in range(n):
			var at: int=z*n+x
			var h: float=heights[at]
			if x>0: h=minf(h,heights[at-1]+rise)
			if z>0:
				h=minf(h,heights[at-n]+rise)
				if x>0: h=minf(h,heights[at-n-1]+diagonal)
				if x<n-1: h=minf(h,heights[at-n+1]+diagonal)
			heights[at]=h
	for z in range(n-1,-1,-1):
		for x in range(n-1,-1,-1):
			var at: int=z*n+x
			var h: float=heights[at]
			if x<n-1: h=minf(h,heights[at+1]+rise)
			if z<n-1:
				h=minf(h,heights[at+n]+rise)
				if x<n-1: h=minf(h,heights[at+n+1]+diagonal)
				if x>0: h=minf(h,heights[at+n-1]+diagonal)
			heights[at]=h

## Cut and fill: the ground follows a smoothed profile under each road, as a built road does, instead of the road
## rippling over the raw hills. Short dips below sea level become causeways, so mapped roads stay continuous.
func grade_roads() -> void:
	var n: int=world.GRID_N
	var step: float=world.GRID_STEP
	var grid_min: float=world.GRID_MIN
	var weight := PackedFloat32Array()
	var target := PackedFloat32Array()
	var bridged := PackedByteArray()
	weight.resize(n*n)
	target.resize(n*n)
	bridged.resize(n*n)
	for road in world.geography.get("roads",[]):
		var half: float=world.road_half(road.type)
		var samples: Array[Vector2]=[]
		var pts: Array=road.points
		for i in range(pts.size()-1):
			var a := Vector2(pts[i][0],pts[i][1])
			var b := Vector2(pts[i+1][0],pts[i+1][1])
			var count := maxi(1,ceili(a.distance_to(b)/6.0))
			for s in range(count): samples.append(a.lerp(b,float(s)/count))
		samples.append(Vector2(pts[-1][0],pts[-1][1]))
		var raw := PackedFloat32Array()
		var causeway := PackedByteArray()
		raw.resize(samples.size())
		causeway.resize(samples.size())
		for i in range(samples.size()): raw[i]=world.height_at(samples[i].x,samples[i].y)
		# Water crossings no longer than 48 m with land at both ends carry the road on an embankment.
		var i := 0
		while i<samples.size():
			if raw[i]>=0.9:
				i+=1
				continue
			var j := i
			while j<samples.size() and raw[j]<0.9: j+=1
			if i>0 and j<samples.size() and (j-i)*6.0<=96.0:
				for k in range(i,j): causeway[k]=1
			i=j
		for s in range(samples.size()):
			if raw[s]<0.9 and causeway[s]==0: continue
			var total := 0.0
			var used := 0
			for k in range(maxi(0,s-5),mini(samples.size(),s+6)):
				if raw[k]<0.9 and causeway[k]==0: continue
				total+=maxf(raw[k],1.1)
				used+=1
			var level: float=total/maxf(used,1)
			var radius: float=half+14.0
			var cx := int((samples[s].x-grid_min)/step)
			var cz := int((samples[s].y-grid_min)/step)
			var reach := ceili(radius/step)
			for z in range(maxi(0,cz-reach),mini(n,cz+reach+2)):
				for x in range(maxi(0,cx-reach),mini(n,cx+reach+2)):
					var d: float=Vector2(grid_min+x*step,grid_min+z*step).distance_to(samples[s])
					var w: float=1.0-smoothstep(half+1.5,radius,d)
					var at: int=z*n+x
					if w>weight[at]:
						weight[at]=w
						target[at]=level
						bridged[at]=causeway[s]
	for at in range(n*n):
		# The open sea bed stays put unless this node carries a causeway.
		if weight[at]>0.0 and (heights[at]>-1.5 or bridged[at]==1):
			heights[at]=lerpf(heights[at],target[at],weight[at])

func to_pixel(x: float,z: float) -> Vector2:
	return Vector2((x+SPAN/2)/PIXEL,(z+SPAN/2)/PIXEL)

## Distance from the road edge, offset so 2.9 means "at the tarmac edge" whatever the road's width.
func bake_road_distance() -> void:
	road_dist.resize(RES*RES)
	road_dist.fill(1000.0)
	# The traffic route counts as a road too: it follows the raw mapped line, which can differ from the drawn one.
	var lines: Array=world.geography.get("roads",[]).duplicate()
	lines.append({"points":world.geography.get("traffic_route",[]),"type":"secondary"})
	for road in lines:
		var pts: Array=road.points
		var half: float=world.road_half(road.type)
		var shift: float=2.9-half
		var reach := ceili((half+24.0)/PIXEL)
		for i in range(pts.size()-1):
			var a := Vector2(pts[i][0],pts[i][1])
			var b := Vector2(pts[i+1][0],pts[i+1][1])
			var steps := maxi(1,ceili(a.distance_to(b)/(PIXEL*2.0)))
			for s in range(steps+1):
				var p := a.lerp(b,float(s)/steps)
				var c := to_pixel(p.x,p.y)
				var cx := int(c.x)
				var cy := int(c.y)
				for y in range(maxi(0,cy-reach),mini(RES,cy+reach+1)):
					var row := y*RES
					var dy: float=y+0.5-c.y
					for x in range(maxi(0,cx-reach),mini(RES,cx+reach+1)):
						var dx: float=x+0.5-c.x
						var d: float=maxf(sqrt(dx*dx+dy*dy)*PIXEL+shift,0.0)
						if d<road_dist[row+x]: road_dist[row+x]=d

func road_distance(x: float,z: float) -> float:
	var c := to_pixel(x,z)
	var ix := clampi(int(c.x),0,RES-1)
	var iy := clampi(int(c.y),0,RES-1)
	return road_dist[iy*RES+ix]

func flat_enough(x: float,z: float,radius: float) -> bool:
	var low := 1e9
	var high := -1e9
	for o in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1),Vector2.ZERO]:
		var h: float=world.height_at(x+o.x*radius,z+o.y*radius)
		low=minf(low,h)
		high=maxf(high,h)
	return low>1.3 and high-low<4.4

func free_spot(x: float,z: float,radius: float) -> bool:
	if preload("res://scripts/sunshine_spa.gd").reserved(x,z,radius) or preload("res://scripts/elluk_restaurant.gd").reserved(x,z,radius) or preload("res://scripts/seaside_inn.gd").reserved(x,z,radius) or preload("res://scripts/island_landmarks.gd").reserved(x,z,radius) or preload("res://scripts/place_sites.gd").reserved(x,z,radius): return false
	# The Mele village green keeps its original hand-placed layout and villager routes.
	if x>-1070.0 and x<-890.0 and z>110.0 and z<320.0: return false
	for b in buildings_near(x,z):
		var gap: float=radius+maxf(b.w,b.d)*0.62+2.0
		if Vector2(b.x,b.z).distance_squared_to(Vector2(x,z))<gap*gap: return false
	for keep in world.KEEP_CLEAR:
		if Vector2(x,z).distance_to(keep)<radius+9.0: return false
	return true

## Buildings within at least one bucket (40 m) of a point. All proximity tests in the bake go through this.
func buildings_near(x: float,z: float) -> Array:
	var found: Array=[]
	var bx := floori(x/BUCKET)
	var bz := floori(z/BUCKET)
	for oz in range(bz-1,bz+2):
		for ox in range(bx-1,bx+2):
			var key := Vector2i(ox,oz)
			if building_buckets.has(key): found.append_array(building_buckets[key])
	return found

func add_building(x: float,z: float,yaw: float,w: float,d: float,storeys: int,style: int,drive := 0.0) -> void:
	var entry := {"x":x,"z":z,"yaw":yaw,"w":w,"d":d,"storeys":storeys,"style":style,"seed":rng.randi()%100000,"drive":drive}
	buildings.append(entry)
	var key := Vector2i(floori(x/BUCKET),floori(z/BUCKET))
	if not building_buckets.has(key): building_buckets[key]=[]
	building_buckets[key].append(entry)

## Mapped buildings in the 3x3 cells (36 m square, about 720 m in real life) around a point.
func mapped_density(x: float,z: float) -> int:
	var cx := int((x+SPAN/2)/LAND_STEP)
	var cz := int((z+SPAN/2)/LAND_STEP)
	var total := 0
	for oz in range(maxi(0,cz-1),mini(LAND,cz+2)):
		for ox in range(maxi(0,cx-1),mini(LAND,cx+2)):
			total+=land_density.decode_u16((oz*LAND+ox)*2)
	return total

func mapped_shops(x: float,z: float) -> int:
	var cx := int((x+SPAN/2)/LAND_STEP)
	var cz := int((z+SPAN/2)/LAND_STEP)
	var total := 0
	for oz in range(maxi(0,cz-1),mini(LAND,cz+2)):
		for ox in range(maxi(0,cx-1),mini(LAND,cx+2)):
			total+=land_shops.decode_u16((oz*LAND+ox)*2)
	return total

## 0 unmapped, 1 residential, 2 commercial, 3 industrial, 4 farm, 5 forest, 6 scrub, 7 park, 8 wetland, 9 airfield.
func land_at(x: float,z: float) -> int:
	var cx := int((x+SPAN/2)/LAND_STEP)
	var cz := int((z+SPAN/2)/LAND_STEP)
	if cx<0 or cz<0 or cx>=LAND or cz>=LAND: return 0
	return land_class[cz*LAND+cx]

## The whole footprint plus the veranda or awning in front, not only its corners: a road can cross the middle of a lot.
func lot_clear_of_roads(x: float,z: float,yaw: float,w: float,d: float) -> bool:
	var basis := Basis(Vector3.UP,yaw)
	var depth_back: float=-d*0.5
	var depth_front: float=d*0.5+3.2
	for ix in range(5):
		for iz in range(5):
			var c: Vector3=basis*Vector3(lerpf(-w*0.5,w*0.5,ix/4.0),0,lerpf(depth_back,depth_front,iz/4.0))
			if road_distance(x+c.x,z+c.z)<3.5: return false
	return true

func hits_pole(x: float,z: float,yaw: float,w: float,d: float) -> bool:
	for pole in pole_points:
		if footprint_contains(x,z,yaw,w,d,pole.x,pole.z,1.0): return true
	return false

func footprint_contains(x: float,z: float,yaw: float,w: float,d: float,px: float,pz: float,margin: float) -> bool:
	var ox: float=px-x
	var oz: float=pz-z
	var lx: float=ox*cos(yaw)-oz*sin(yaw)
	var lz: float=ox*sin(yaw)+oz*cos(yaw)
	return absf(lx)<w*0.5+margin and lz>-d*0.5-margin and lz<d*0.5+3.2+margin

func try_building(p: Vector2,yaw: float,w: float,d: float,storeys: int,style: int,drive: float) -> bool:
	var size: float=maxf(w,d)*0.62
	var reason := ""
	if not lot_clear_of_roads(p.x,p.y,yaw,w,d): reason="road"
	elif hits_pole(p.x,p.y,yaw,w,d): reason="pole"
	elif land_at(p.x,p.y) in [8,9]: reason="land"
	elif not flat_enough(p.x,p.y,size): reason="slope"
	elif not free_spot(p.x,p.y,size): reason="occupied"
	if reason!="":
		rejected[reason]=rejected.get(reason,0)+1
		return false
	add_building(p.x,p.y,yaw,w,d,storeys,style,drive)
	return true

func place_buildings() -> Array:
	# Mele: the original village layout, now facing its street.
	for i in range(10):
		# West row stands clear of the tide line.
		var x := -1014.0 if i%2==0 else -928.0
		var z := 172.0+floorf(i/2.0)*34.0
		# The mapped Ring Road runs through the south end of this layout: those plots stay empty.
		if lot_clear_of_roads(x,z,PI/2 if i%2==0 else -PI/2,10.0,8.5):
			add_building(x,z,PI/2 if i%2==0 else -PI/2,10.0,8.5,1,i%2)
	# Outer rows make Mele read as a lived-in village rather than a line of houses.
	var outer := [[-1082.0,160.0,PI/2],[-1082.0,206.0,PI/2],[-1082.0,252.0,PI/2],[-874.0,148.0,-PI/2],[-874.0,194.0,-PI/2],[-874.0,240.0,-PI/2],[-874.0,286.0,-PI/2],[-940.0,108.0,0.0],[-1010.0,108.0,0.0],[-940.0,336.0,PI],[-880.0,336.0,PI],[-1010.0,340.0,PI]]
	for o in outer:
		var outer_w := rng.randf_range(8.5,12.0)
		var outer_d := rng.randf_range(7.0,9.0)
		if flat_enough(o[0],o[1],7.0) and lot_clear_of_roads(o[0],o[1],o[2],outer_w,outer_d):
			add_building(o[0],o[1],o[2],outer_w,outer_d,1,rng.randi_range(0,1))
	var poles: Array=[]
	var vila := Vector2.ZERO
	for place in world.geography.get("places",[]):
		if place.name=="Port Vila": vila=Vector2(place.position[0],place.position[1])
	var roads: Array=world.geography.get("roads",[]).duplicate()
	roads.reverse() # Main roads first.
	# Every candidate plot along the mapped streets, weighted by how built-up the map says that spot is.
	var plots: Array=[]
	for road in roads:
		var pts: Array=road.points
		var half: float=world.road_half(road.type)
		var major: bool=road.type in ["secondary","tertiary"]
		if road.type=="runway": continue
		var chain := PackedVector3Array()
		var walked := 0.0
		for i in range(pts.size()-1):
			var a := Vector2(pts[i][0],pts[i][1])
			var b := Vector2(pts[i+1][0],pts[i+1][1])
			var length := a.distance_to(b)
			if length<0.01: continue
			var dir := (b-a)/length
			var normal := Vector2(-dir.y,dir.x)
			var along := 0.0
			while along<length:
				var p := a+dir*along
				var mapped: int=mapped_density(p.x,p.y)
				var built: bool=mapped>=6
				# Power poles follow the bigger roads through built-up land.
				if built and road.type in ["secondary","tertiary","unclassified"] and int(walked/34.0)!=int((walked+6.0)/34.0):
					var q := p+normal*(half+2.2)
					var h: float=world.height_at(q.x,q.y)
					var clear: bool=h>0.6 and road_distance(q.x,q.y)>=4.2
					# Mele's hand-placed houses are already standing at this point.
					for house in buildings_near(q.x,q.y):
						if footprint_contains(house.x,house.z,house.yaw,house.w,house.d,q.x,q.y,1.0): clear=false
					if clear:
						chain.append(Vector3(q.x,h,q.y))
						pole_points.append(chain[-1])
				elif not built and chain.size()>0:
					if chain.size()>1: poles.append(chain)
					chain=PackedVector3Array()
				if built and int(walked/13.0)!=int((walked+6.0)/13.0):
					var chance: float=pow(smoothstep(4.0,110.0,float(mapped)),0.55)
					for side in [-1.0,1.0]:
						if rng.randf()<chance: plots.append({"p":p,"normal":normal*side,"half":half,"major":major})
				walked+=6.0
				along+=6.0
		if chain.size()>1: poles.append(chain)
	# Shuffled, so hitting the building cap thins the whole island evenly rather than dropping the last roads.
	for i in range(plots.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var t = plots[i]
		plots[i]=plots[j]
		plots[j]=t
	# Commercial streets are placed first: shops need more frontage, and houses would otherwise take every gap.
	var ordered: Array=[]
	var residential: Array=[]
	for plot in plots:
		var at: Vector2=plot.p
		plot["commercial"]=land_at(at.x,at.y)==2 or mapped_shops(at.x,at.y)>=2 or (plot.major and at.distance_to(vila)<55.0)
		if plot.commercial: ordered.append(plot)
		else: residential.append(plot)
	ordered.append_array(residential)
	var commercial_count := 0
	for plot in ordered:
		if buildings.size()>=MAX_BUILDINGS: break
		var p: Vector2=plot.p
		var centre_dist: float=p.distance_to(vila)
		var shop: bool=plot.commercial and rng.randf()<0.85
		var w := rng.randf_range(11.0,17.0) if shop else rng.randf_range(8.0,12.5)
		var d := rng.randf_range(10.0,14.0) if shop else rng.randf_range(6.8,9.5)
		var gap: float=3.0 if shop else rng.randf_range(3.2,6.5)
		var setback: float=plot.half+1.2+d*0.5+gap
		var s: Vector2=p+plot.normal*setback
		# Local +Z (the front) looks back at the road.
		var face: Vector2=-plot.normal
		var storeys: int=1
		if shop: storeys=rng.randi_range(2,3) if centre_dist<55.0 else rng.randi_range(1,2)
		if try_building(s,atan2(face.x,face.y),w,d,storeys,2 if shop else rng.randi_range(0,1),gap+1.2):
			if shop: commercial_count+=1
	# Mapped settlements with no kept road through them: homes still appear, turned toward the nearest track.
	var frontage_count := buildings.size()
	print("BAKE frontage rejected=%s" % [rejected])
	rejected={}
	var z := -SPAN/2
	while z<SPAN/2 and buildings.size()<MAX_BUILDINGS:
		var x := -SPAN/2
		while x<SPAN/2 and buildings.size()<MAX_BUILDINGS:
			var at := Vector2(x+rng.randf_range(4,20),z+rng.randf_range(4,20))
			x+=24.0
			var mapped: int=mapped_density(at.x,at.y)
			if mapped<16 or rng.randf()>smoothstep(16.0,140.0,float(mapped))*0.8+0.2: continue
			var here: float=road_distance(at.x,at.y)
			var yaw: float=rng.randf()*TAU
			var drive := 0.0
			if here<100.0:
				var grad := Vector2(road_distance(at.x+4.0,at.y)-road_distance(at.x-4.0,at.y),road_distance(at.x,at.y+4.0)-road_distance(at.x,at.y-4.0))
				if grad.length_squared()>0.01:
					grad=-grad.normalized()
					yaw=atan2(grad.x,grad.y)
					drive=here-2.9
			try_building(at,yaw,rng.randf_range(7.5,11.0),rng.randf_range(6.5,8.5),1,rng.randi_range(0,1),drive)
		z+=24.0
	print("BAKE plots=%d frontage=%d offroad=%d shops=%d rejected=%s" % [plots.size(),frontage_count,buildings.size()-frontage_count,commercial_count,rejected])
	return poles

## 0 at the middle of a settlement, 1 outside it. Drawn from the real map rather than a circle around each place name.
func clearing(x: float,z: float) -> float:
	var result := smoothstep(70.0,160.0,Vector2(x,z).distance_to(world.TOWN))
	result=minf(result,1.0-smoothstep(3.0,42.0,float(mapped_density(x,z))))
	if land_at(x,z) in [1,2,3,4,7,9]: result=minf(result,0.2)
	return result

func paint_maps() -> Array:
	var macro := PackedByteArray()
	var data := PackedByteArray()
	macro.resize(RES*RES*3)
	data.resize(RES*RES*4)
	var surface := PackedByteArray()
	surface.resize(SURFACE_RES*SURFACE_RES)
	var canopy := FastNoiseLite.new()
	canopy.seed=11
	canopy.frequency=0.09
	canopy.fractal_octaves=3
	var broad := FastNoiseLite.new()
	broad.seed=12
	broad.frequency=0.006
	broad.fractal_octaves=4
	var reef := FastNoiseLite.new()
	reef.seed=31
	reef.frequency=0.03
	reef.fractal_octaves=5
	for py in range(RES):
		for px in range(RES):
			var x := (px+0.5)*PIXEL-SPAN/2
			var z := (py+0.5)*PIXEL-SPAN/2
			var h: float=world.height_at(x,z)
			var road := road_dist[py*RES+px]
			var forest: float=forest_density(x,z,road)
			var at := py*RES+px
			var colour: Color
			if h<0:
				# Pale sand under the shallows, dark coral heads along the reef shelf, blue-black beyond.
				var depth := -h
				var coral := smoothstep(0.08,0.32,reef.get_noise_2d(x,z))*smoothstep(0.7,2.0,depth)*(1.0-smoothstep(5.0,9.0,depth))
				colour=Color(0.78,0.74,0.60).lerp(Color(0.34,0.40,0.34),coral*0.85)
				colour=colour.lerp(Color(0.08,0.14,0.22),smoothstep(5.0,20.0,depth))
			else:
				var variation := broad.get_noise_2d(x,z)*0.5+0.5
				var pasture := Color(0.15,0.21,0.08).lerp(Color(0.23,0.25,0.115),variation)
				# Mapped land use reads from above: farm plots paler, built-up land dustier.
				var use: int=land_at(x,z)
				if use==4: pasture=pasture.lerp(Color(0.27,0.27,0.13),0.55)
				elif use in [1,2,3]: pasture=pasture.lerp(Color(0.26,0.24,0.15),0.4)
				elif use==9: pasture=pasture.lerp(Color(0.24,0.26,0.13),0.5)
				var crown := canopy.get_noise_2d(x,z)*0.5+0.5
				var jungle := Color(0.035,0.085,0.03).lerp(Color(0.09,0.17,0.05),crown*0.7+variation*0.3)
				colour=pasture.lerp(jungle,smoothstep(0.15,0.7,forest))
				var sand := 1.0-smoothstep(1.7,3.1,h+variation*0.5)
				colour=colour.lerp(Color(0.66,0.61,0.49),sand)
				# Road verges wear down to pale dirt.
				colour=colour.lerp(Color(0.36,0.33,0.26),(1.0-smoothstep(2.5,5.5,road))*0.7)
			var dirt := 1.0-smoothstep(2.5,6.5,road)
			macro[at*3]=to_byte(colour.r)
			macro[at*3+1]=to_byte(colour.g)
			macro[at*3+2]=to_byte(colour.b)
			data[at*4]=to_byte(world.encode_elevation(h))
			data[at*4+1]=to_byte(forest)
			data[at*4+2]=to_byte(dirt)
			data[at*4+3]=255
	# Yards: bare trodden earth around each building and a soft contact shadow beneath.
	var macro_image := Image.create_from_data(RES,RES,false,Image.FORMAT_RGB8,macro)
	var data_image := Image.create_from_data(RES,RES,false,Image.FORMAT_RGBA8,data)
	for b in buildings:
		var c := to_pixel(b.x,b.z)
		var radius: float=maxf(b.w,b.d)*0.5+6.0
		var span := int(radius/PIXEL)+2
		var cos_yaw: float=cos(b.yaw)
		var sin_yaw: float=sin(b.yaw)
		var drive: float=b.get("drive",0.0)
		for y in range(int(c.y)-span,int(c.y)+span+1):
			for x in range(int(c.x)-span,int(c.x)+span+1):
				if x<0 or y<0 or x>=RES or y>=RES: continue
				var offset: Vector2=(Vector2(x+0.5,y+0.5)-c)*PIXEL
				var f: float=1.0-smoothstep(radius*0.45,radius,offset.length())
				# Into the building's own frame, so the contact shadow is a soft rectangle hugging the walls.
				var lx: float=offset.x*cos_yaw-offset.y*sin_yaw
				var lz: float=offset.x*sin_yaw+offset.y*cos_yaw
				var outside: float=Vector2(maxf(absf(lx)-b.w*0.5,0.0),maxf(absf(lz)-b.d*0.5,0.0)).length()
				var m := macro_image.get_pixel(x,y)
				macro_image.set_pixel(x,y,m.lerp(Color(0.30,0.27,0.19),f*0.6))
				var e := data_image.get_pixel(x,y)
				e.b=maxf(e.b,f*0.62)
				e.a=minf(e.a,lerpf(0.5,1.0,smoothstep(0.0,3.4,outside)))
				data_image.set_pixel(x,y,e)
		# A worn path from the front door to the road.
		if drive>1.0:
			var front := Vector2(sin_yaw,cos_yaw)
			var steps := int((drive+b.d*0.5)/PIXEL)
			for s in range(steps+1):
				var at: Vector2=Vector2(b.x,b.z)+front*(b.d*0.5+s*PIXEL)
				var q := to_pixel(at.x,at.y)
				for oy in range(-1,2):
					for ox in range(-1,2):
						var px := int(q.x)+ox
						var py := int(q.y)+oy
						if px<0 or py<0 or px>=RES or py>=RES: continue
						var e := data_image.get_pixel(px,py)
						e.b=maxf(e.b,0.82 if ox==0 and oy==0 else 0.55)
						data_image.set_pixel(px,py,e)
	macro_image.generate_mipmaps()
	# Ground-cover classes at 4 m: 0 none, 1 lawn, 2 forest floor, 3 long grass.
	var cell := SPAN/SURFACE_RES
	for sy in range(SURFACE_RES):
		for sx in range(SURFACE_RES):
			var x := (sx+0.5)*cell-SPAN/2
			var z := (sy+0.5)*cell-SPAN/2
			var h: float=world.height_at(x,z)
			var kind := 0
			if h>3.4 and road_distance(x,z)>4.5:
				var yard := false
				for b in buildings_near(x,z):
					if Vector2(b.x,b.z).distance_to(Vector2(x,z))<maxf(b.w,b.d)*0.5+4.0:
						yard=true
						break
				if not yard:
					var f: float=forest_density(x,z,road_distance(x,z))
					kind=2 if f>0.45 else (3 if clearing(x,z)>0.6 else 1)
			surface[sy*SURFACE_RES+sx]=kind
	return [macro_image,data_image,surface]

func to_byte(v: float) -> int:
	return int(clampf(v,0.0,1.0)*255.0+0.5)

var density_noise: FastNoiseLite
func forest_density(x: float,z: float,road: float) -> float:
	if density_noise==null:
		density_noise=FastNoiseLite.new()
		density_noise.seed=77
		density_noise.frequency=0.0052
		density_noise.fractal_octaves=3
	var h: float=world.height_at(x,z)
	if h<3.0: return 0.0
	# Efate is jungle above the coastal strip, with pasture and gardens on the lower land.
	var patches := smoothstep(-0.14,0.16,density_noise.get_noise_2d(x,z))
	var upland := smoothstep(14.0,55.0,h)
	var f := maxf(patches,upland)
	var use: int=land_at(x,z)
	if use==5: f=maxf(f,0.92)
	elif use==6: f=minf(maxf(f,0.4),0.55)
	f*=clearing(x,z)
	f*=smoothstep(6.0,22.0,road)
	f*=smoothstep(3.0,8.0,h)
	return f

## One instance in MultiMesh buffer layout: basis/origin rows then custom data.
func write_instance(out: PackedFloat32Array,p: Vector3,centre: Vector3,size: float,custom: Color) -> void:
	var yaw := rng.randf()*TAU
	var c := cos(yaw)*size
	var s := sin(yaw)*size
	out.append_array(PackedFloat32Array([c,0,s,p.x-centre.x, 0,size,0,p.y-centre.y, -s,0,c,p.z-centre.z, custom.r,custom.g,custom.b,custom.a]))

func group(groups: Dictionary,chunk_size: float,entry: Array) -> void:
	var p: Vector3=entry[0]
	var key := Vector2i(floori(p.x/chunk_size),floori(p.z/chunk_size))
	if not groups.has(key): groups[key]=[]
	groups[key].append(entry)

func flush(groups: Dictionary,chunk_size: float) -> Array:
	var result: Array=[]
	for key in groups:
		var entries: Array=groups[key]
		# Shuffled so visible_instance_count can thin each chunk evenly on slow devices.
		for i in range(entries.size()-1,0,-1):
			var j := rng.randi_range(0,i)
			var t = entries[i]
			entries[i]=entries[j]
			entries[j]=t
		var centre := Vector3((key.x+0.5)*chunk_size,0,(key.y+0.5)*chunk_size)
		var total := 0.0
		for e in entries: total+=e[0].y
		centre.y=total/entries.size()
		var buffer := PackedFloat32Array()
		for e in entries: write_instance(buffer,e[0],centre,e[1],e[2])
		result.append({"centre":centre,"count":entries.size(),"buffer":buffer})
	return result

func cell_of(name: String) -> Vector2:
	return Vector2(meta[name].cell[0],meta[name].cell[1])

func place_flora() -> Dictionary:
	var trees := {}
	var palms := {}
	var palm_far := {}
	var counts := [0,0,0]
	var step := 13.0
	var z := -SPAN/2
	while z<SPAN/2:
		var x := -SPAN/2
		while x<SPAN/2:
			var px := x+rng.randf_range(0,step)
			var pz := z+rng.randf_range(0,step)
			x+=step
			var h: float=world.height_at(px,pz)
			if h<1.0 or not building_clear(px,pz): continue
			var f: float=forest_density(px,pz,road_distance(px,pz))
			if f>0.0 and rng.randf()<f:
				var margin := f<0.55 and rng.randf()<0.4
				var kind: String="bush" if margin else ("tree_a" if rng.randf()<0.55 else "tree_b")
				var target := rng.randf_range(2.4,4.2) if margin else rng.randf_range(10.0,19.0)
				var size: float=target/meta[kind].height*meta[kind].size
				var cell := cell_of(kind)
				group(trees,FAR_CHUNK,[Vector3(px,h-0.1,pz),size,Color(cell.x,cell.y,rng.randf(),1.0)])
				counts[0]+=1
		z+=step
	# Coconut palms line the shore and dot the settlements.
	z=-SPAN/2
	var palm_step := 12.0
	while z<SPAN/2:
		var x := -SPAN/2
		while x<SPAN/2:
			var px := x+rng.randf_range(0,palm_step)
			var pz := z+rng.randf_range(0,palm_step)
			x+=palm_step
			var h: float=world.height_at(px,pz)
			if h<1.6 or not building_clear(px,pz) or road_distance(px,pz)<7.0: continue
			var edge: float=world.coast_distance(Vector2(px,pz))
			var chance := 0.34*(1.0-smoothstep(10.0,85.0,edge))
			if clearing(px,pz)<0.5: chance=maxf(chance,0.035)
			if h>26.0: chance=0.0
			if rng.randf()<chance:
				var scale := rng.randf_range(0.8,1.45)
				var p := Vector3(px,h-0.05,pz)
				group(palms,PALM_CHUNK,[p,scale,Color(0,0,rng.randf(),1.0)])
				var cell := cell_of("palm")
				group(palm_far,FAR_CHUNK,[p,meta.palm.size*scale,Color(cell.x,cell.y,rng.randf(),1.0)])
				counts[1]+=1
		z+=palm_step
	print("BAKE trees=%d palms=%d" % [counts[0],counts[1]])
	return {"trees":flush(trees,FAR_CHUNK),"palms":flush(palms,PALM_CHUNK),"palm_far":flush(palm_far,FAR_CHUNK)}

func building_clear(x: float,z: float) -> bool:
	for keep in world.KEEP_CLEAR:
		if Vector2(x,z).distance_to(keep)<7.0: return false
	for b in buildings_near(x,z):
		if Vector2(b.x,b.z).distance_to(Vector2(x,z))<maxf(b.w,b.d)*0.5+3.5: return false
	return true

func place_rocks() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in range(520):
		var x := rng.randf_range(-2500,2500)
		var z := rng.randf_range(-2700,2500)
		var h: float=world.height_at(x,z)
		if h<-0.7 or road_distance(x,z)<8.0 or clearing(x,z)<0.8: continue
		var edge: float=world.coast_distance(Vector2(x,z))
		# Weathered coral boulders on the shore, a scatter of volcanic rock inland.
		if edge>60.0 and rng.randf()>0.3: continue
		out.append_array(PackedFloat32Array([x,h,z,rng.randf_range(0.5,2.4),rng.randf()*TAU]))
	return out


