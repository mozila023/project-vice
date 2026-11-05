extends SceneTree
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	print("STORY ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1

func run() -> void:
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var g=current_scene
	g.set_physics_process(false)
	await physics_frame
	var preferences: Node=root.get_node("Preferences")
	check(g.story.language==preferences.language and g.story.relaxed==preferences.relaxed,"saved language and play style apply on entry")
	check(g.field_hud.font.has_char(0x0E01) and g.field_hud.font.has_char(0x0E49),"bundled font contains Thai consonants and tone marks")
	var outfits := {}
	for npc in g.villagers:
		for mesh in npc.visual.find_children("*","MeshInstance3D",true,false):
			for s in range(mesh.mesh.get_surface_count()):
				var fabric=mesh.get_surface_override_material(s)
				if fabric!=null and fabric.albedo_texture!=null: outfits[fabric.albedo_texture.resource_path]=true
	check(outfits.size()>=8,"villagers use varied realistic clothing and face textures")
	g.active_villager="Jonas / Market"
	g.panel="talk"
	g.trade("story")
	check(g.story.stage==0,"story begins only with Malia")
	g.active_villager="Malia / Fisher"
	g.trade("story")
	check(g.story.stage==1,"Malia starts the optional story")
	g.fish=3
	g.trade("sell")
	check(g.story.stage==2 and g.fish==0 and g.delivered_fish==3,"fish trade advances chapter and consumes fish")
	g.player.position=g.camp_position
	g.fish=2
	g.wood=2
	g.interact()
	g.interact()
	check(g.story.stage==3 and g.story.meals==2 and g.cooked_fish==2,"cooking two meals advances chapter through real interaction")
	g.panel="talk"
	g.wood=2
	g.trade("story")
	check(g.story.stage==3 and g.wood==2,"insufficient wood cannot complete donation")
	g.wood=3
	g.trade("story")
	check(g.story.stage==4 and g.wood==0,"donation consumes wood once")
	g.player.position=Vector3(-254,g.ground(-254,438)+1,438)
	g.story.update()
	check(g.story.stage==5 and "Port Vila" in g.story.discovered,"visiting the real mapped town advances exploration")
	var before: int=g.coins
	g.story.update()
	check(g.coins==before,"discovery reward cannot repeat")
	g.trade("story")
	check(g.story.stage==6 and g.coins==before+100,"homecoming completes story and awards final reward")
	g.trade("story")
	check(g.coins==before+100,"final reward cannot repeat")
	g.story.language="en"
	g.story.relaxed=false
	g.story.tracked_place="Eton"
	var saved=JSON.parse_string(JSON.stringify(g.story.data()))
	g.story.restore(saved)
	check(g.story.stage==6 and g.story.language=="en" and not g.story.relaxed and "Port Vila" in g.story.discovered and g.story.tracked_place=="Eton","story, language, exploration and mode survive JSON round trip")
	g.story.restore({"stage":"bad","meals":[],"discovered":["fake"]})
	check(g.story.stage==0 and g.story.meals==0 and g.story.discovered.is_empty(),"malformed story fields are rejected safely")
	g.story.restore({})
	check(g.story.stage==0 and g.story.relaxed,"old saves without story remain compatible")
	g.story.language="th"
	check(g.story.task().contains("มาเลีย"),"Thai quest text is available")
	g.story.language="en"
	check(g.story.task().contains("Malia"),"English quest text is available")
	g.panel="island"
	g.field_hud.activate("place_3",true)
	check(g.panel=="map" and g.story.tracked_place=="Eton" and g.story.target().x>1000,"island note button tracks real mapped destination")
	g.field_hud.activate("track_story",true)
	check(g.story.tracked_place=="","story tracking clears optional destination")
	g.panel="journal"
	check(g.field_hud.buttons().journal.position.y>100,"journal tab has its panel position")
	g.panel=""
	g.food=10
	g.thirst=10
	g.energy=10
	g.story.relaxed=true
	g._physics_process(1.0)
	check(g.food==10 and g.thirst==10 and g.energy==10,"relaxed mode does not drain survival needs")
	print("STORY RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
