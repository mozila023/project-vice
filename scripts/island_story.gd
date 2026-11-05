extends RefCounted
## A fictional recovery story set on the game's Efate island.
var language := "th"
var stage := 0
var meals := 0
var relaxed := true
var discovered: Array[String] = []
var tracked_place := ""
var game: Node3D
const PLACES := [
	{"id":"Mele","at":Vector2(-489,141),"th":"เมเล","en":"Your home base beside Mele Bay. Greet your hosts and ask before entering homes or gardens.","fact_th":"ฐานพักริมอ่าวเมเล ทักทายเจ้าบ้านและขออนุญาตก่อนเข้าบ้านหรือสวนของผู้อื่น"},
	{"id":"Port Vila","at":Vector2(-254,438),"th":"พอร์ตวิลา","en":"Port Vila is on Efate. Its markets are a place to discover local produce and food such as laplap.","fact_th":"พอร์ตวิลาตั้งอยู่บนเอฟาเต ตลาดเป็นแหล่งพบผลผลิตและอาหารท้องถิ่น เช่น ลัป ลัป"},
	{"id":"Port Havannah","at":Vector2(-462,-533),"th":"พอร์ตฮาวานนาห์","en":"Havannah Harbour lies northwest of Port Vila, with trips to nearby Moso and Lelepa islands.","fact_th":"อ่าวฮาวานนาห์อยู่ทางตะวันตกเฉียงเหนือของพอร์ตวิลา มีเส้นทางไปเกาะโมโซและเลเลปา"},
	{"id":"Eton","at":Vector2(1059,488),"th":"อีตัน","en":"Eton is on Efate's east coast. Its beach area is known for white sand and a freshwater inlet.","fact_th":"อีตันอยู่ชายฝั่งตะวันออกของเอฟาเต บริเวณชายหาดมีทรายขาวและทางน้ำจืดไหลมาบรรจบทะเล"},
	{"id":"Sunshine Wellness & Spa","at":Vector2(-223.78243,441.00744),"th":"Sunshine Wellness & Spa","en":"785C+68, Seaside. Maps: Sunshine Thai Massage Spa & Nail (Sea Oak 2007). Frontage and salon follow Maps/shop photos.","fact_th":"785C+68 ซีไซด์ Maps: Sunshine Thai Massage Spa & Nail (Sea Oak 2007) ด้านหน้าและห้องทำเล็บอ้างอิงภาพ Maps/เว็บร้าน"},
	{"id":"PAD THAI @ELLUK","at":Vector2(-285.41613,558.31335),"th":"PAD THAI @ELLUK","en":"Elluk Road. Verified Maps pin; raised frontage, timber stairs and orange elephant signs follow supplied photos.","fact_th":"ถนน Elluk พิกัดตาม Maps หน้าร้านยกสูง บันไดไม้ และป้ายสีส้มลายช้างอ้างอิงรูปที่ส่งมา"}
]
const DESTINATION := Vector3(-254,0,438)
const TITLES := [
	["A new neighbour","เพื่อนบ้านคนใหม่"],
	["Food for the village","อาหารเพื่อหมู่บ้าน"],
	["A warm meal","มื้ออุ่นริมทะเล"],
	["Rebuild together","ร่วมแรงซ่อมแซม"],
	["The coastal connection","เส้นทางเชื่อมชุมชน"],
	["A place to call home","ที่ที่เรียกว่าบ้าน"],
	["A new dawn","รุ่งเช้าครั้งใหม่"]
]
const TASKS := [
	["Find Malia near the beach fire. Talk and choose STORY.","พบมาเลียใกล้กองไฟริมชายหาด คุยแล้วเลือก ‘เนื้อเรื่อง’"],
	["Catch 3 fish at the coast. Trade them with any villager.","ตกปลาริมทะเล 3 ตัว แล้วนำไปแลกกับชาวบ้านคนใดก็ได้"],
	["Cook 2 fish at the beach fire (1 fish + 1 wood each).","ย่างปลาที่กองไฟ 2 ตัว ใช้ปลาดิบและไม้ครั้งละ 1 ชิ้น"],
	["Bring 3 driftwood to Malia. Choose STORY to donate.","นำไม้ลอยน้ำ 3 ชิ้นไปให้มาเลีย เลือก ‘เนื้อเรื่อง’ เพื่อส่งมอบ"],
	["Visit Port Vila's coast. Walk or take a parked car.","เดินหรือขับรถไปสำรวจชายฝั่งพอร์ตวิลา ตามจุดสีทองบนแผนที่"],
	["Return to Malia and choose STORY to share the news.","กลับไปหามาเลีย แล้วเลือก ‘เนื้อเรื่อง’ เพื่อเล่าข่าวดี"],
	["The village is connected again. Keep exploring at your pace.","ชุมชนกลับมาเชื่อมถึงกันแล้ว ออกสำรวจและใช้ชีวิตได้อย่างอิสระ"]
]
const DIALOGUE := [
	["The storm has passed, but our village is still finding its feet.\nI'm Malia. Will you help us put a shared meal on the table?\nStart with three fresh fish. Our neighbours will trade for them.","พายุผ่านไปแล้ว แต่หมู่บ้านยังต้องค่อย ๆ ฟื้นตัว\nฉันชื่อมาเลีย มาช่วยเตรียมอาหารให้เพื่อนบ้านกันไหม?\nเริ่มจากปลาสดสามตัว แล้วนำไปแลกกับคนในหมู่บ้านนะ"],
	["A meal brings people together. Fish beside the shore,\nthen trade three fresh fish with any of our neighbours.\nF casts your line. E reels in when the float dips.","อาหารหนึ่งมื้อช่วยให้ทุกคนได้มาพบกัน\nตกปลาที่ชายฝั่ง แล้วนำปลาสดสามตัวไปแลกกับชาวบ้าน\nกด F เพื่อเหวี่ยงเบ็ด และกด E เมื่อปลากินเหยื่อ"],
	["Thank you for the fresh fish. Now light up the evening\nwith two grilled fish at our beach fire. Gather driftwood\nalong the sand if you need fuel. E cooks beside the fire.","ขอบใจสำหรับปลาสดนะ ต่อไปช่วยย่างปลาอีกสองตัว\nที่กองไฟริมชายหาด เก็บไม้ลอยน้ำบนทรายไว้เป็นเชื้อเพลิง\nเดินเข้าใกล้กองไฟแล้วกด E เพื่อทำอาหาร"],
	["We shared your meal. Now the shelter needs a little care.\nBring me three pieces of driftwood for the repairs.\nChoose STORY again when you have them.","ทุกคนได้อิ่มท้องแล้ว ต่อไปมาช่วยซ่อมที่พักกัน\nฉันต้องการไม้ลอยน้ำสามชิ้นสำหรับงานซ่อม\nเมื่อเก็บครบแล้ว กลับมาเลือก ‘เนื้อเรื่อง’ เพื่อส่งมอบนะ"],
	["The shelter is ready. We need to know if the coastal road\nto Port Vila is open. Take a parked car, or walk there.\nFollow the gold marker on your map. Travel safely.","ที่พักพร้อมแล้ว เราต้องรู้ว่าถนนเลียบชายฝั่ง\nไปพอร์ตวิลายังใช้ได้หรือไม่ จะเดินหรือขับรถไปก็ได้\nตามจุดสีทองบนแผนที่ แล้วกลับมาเล่าให้ฟังนะ"],
	["You made it to Port Vila! The coast can connect us again.\nYour help gave us food, shelter and a path forward.\nStay a while. You're part of this village now.","เธอไปถึงพอร์ตวิลาแล้ว! ชายฝั่งเชื่อมชุมชนเราได้อีกครั้ง\nเธอช่วยให้เรามีอาหาร ที่พัก และเส้นทางที่จะก้าวต่อ\nอยู่ด้วยกันก่อนนะ เธอเป็นคนของหมู่บ้านนี้แล้ว"],
	["A new dawn, together. There are still fish to catch,\nmeals to share and quiet roads to explore.\nThank you, neighbour. This island is your home too.","รุ่งเช้าครั้งใหม่เริ่มขึ้นพร้อมกัน ยังมีปลาให้ตก\nมีอาหารให้แบ่งปัน และเส้นทางสงบให้ค้นพบ\nขอบใจนะเพื่อนบ้าน เกาะนี้เป็นบ้านของเธอด้วย"]
]

func l(en: String, th: String) -> String:
	return th if language=="th" else en

func title() -> String:
	return l(TITLES[stage][0],TITLES[stage][1])

func tracker_title() -> String:
	for place in PLACES:
		if place.id==tracked_place: return l(place.id,place.th)
	return title()

func tracker_task() -> String:
	if tracked_place!="": return l("Follow the gold marker on the map. Explore at your own pace.","ตามจุดสีทองบนแผนที่ สำรวจได้ตามจังหวะของคุณ")
	return task()

func task() -> String:
	return l(TASKS[stage][0],TASKS[stage][1])

func dialogue() -> String:
	return l(DIALOGUE[stage][0],DIALOGUE[stage][1])

func progress() -> String:
	if tracked_place!="": return distance_text()
	match stage:
		1: return l("Fish traded: %d / 3","ส่งปลาแล้ว: %d / 3") % mini(game.delivered_fish,3)
		2: return l("Meals cooked: %d / 2","ย่างปลาแล้ว: %d / 2") % meals
		3: return l("Driftwood: %d / 3","ไม้ที่มี: %d / 3") % mini(game.wood,3)
		6: return l("STORY COMPLETE","จบเนื้อเรื่องแล้ว")
	return distance_text()

func distance_text() -> String:
	return l("Distance: %d m","ระยะทาง: %d ม.") % int(Vector2(game.player.position.x,game.player.position.z).distance_to(Vector2(target().x,target().z)))

func target() -> Vector3:
	for place in PLACES:
		if place.id==tracked_place: return Vector3(place.at.x,game.ground(place.at.x,place.at.y),place.at.y)
	if stage==4: return Vector3(DESTINATION.x,game.ground(DESTINATION.x,DESTINATION.z),DESTINATION.z)
	if stage==2:
		if game.fish<=0: return Vector3(-534,0,165)
		if game.wood<=0: return nearest_wood()
		return game.camp_position
	if stage==1 and game.fish<3: return Vector3(-534,0,165)
	if stage==3 and game.wood<3: return nearest_wood()
	return game.villagers[0].body.position

func nearest_wood() -> Vector3:
	var found: Vector3=game.villagers[0].body.position
	var best := INF
	for item in game.resources:
		if item.kind!="wood" or item.collected: continue
		var distance: float=game.player.position.distance_to(item.node.position)
		if distance<best:
			best=distance
			found=item.node.position
	return found

func advance() -> void:
	if stage>=6: return
	stage+=1
	game.tell(l("New chapter: ","บทใหม่: ")+title())

func event(kind: String) -> void:
	if stage==1 and kind=="trade" and game.delivered_fish>=3:
		game.coins+=20
		advance()
	elif stage==2 and kind=="cook":
		meals=mini(meals+1,2)
		if meals>=2:
			game.coins+=25
			advance()

func talk() -> void:
	if not game.active_villager.begins_with("Malia"):
		game.tell(l("Malia is by the beach fire. She coordinates the village's recovery.","มาเลียอยู่แถวกองไฟริมชายหาด เธอเป็นคนประสานงานฟื้นฟูหมู่บ้าน"))
		return
	if stage==0:
		# Existing saves can already have supplied the village.
		advance()
		if game.delivered_fish>=3: event("trade")
	elif stage==3:
		if game.wood<3:
			game.tell(l("Bring 3 driftwood for the shelter repairs.","นำไม้ลอยน้ำ 3 ชิ้นมาช่วยซ่อมที่พักก่อนนะ"))
		else:
			game.wood-=3
			game.friendship+=2
			game.coins+=30
			advance()
	elif stage==5:
		game.coins+=100
		game.friendship+=3
		advance()

func update() -> void:
	for place in PLACES:
		if not place.id in discovered and Vector2(game.player.position.x,game.player.position.z).distance_to(place.at)<40.0:
			discovered.append(place.id)
			game.coins+=10
			game.tell(l("Discovered: ","ค้นพบ: ")+l(place.id,place.th)+l(" · +10 vatu. Read the island journal."," · +10 วาตู อ่านเรื่องราวในบันทึกเกาะได้"))
	if stage==4 and Vector2(game.player.position.x,game.player.position.z).distance_to(Vector2(DESTINATION.x,DESTINATION.z))<35.0:
		advance()

func data() -> Dictionary:
	return {"stage":stage,"meals":meals,"language":language,"relaxed":relaxed,"discovered":discovered,"tracked_place":tracked_place}

func restore(value: Variant) -> void:
	stage=0
	meals=0
	discovered.clear()
	tracked_place=""
	if not value is Dictionary: return
	var s=value.get("stage",0)
	var m=value.get("meals",0)
	if (s is int or s is float) and is_finite(float(s)): stage=clampi(int(s),0,6)
	if (m is int or m is float) and is_finite(float(m)): meals=clampi(int(m),0,2)
	language="en" if value.get("language")=="en" else "th"
	relaxed=value.get("relaxed",true)!=false
	var visits=value.get("discovered",[])
	if visits is Array:
		for place in PLACES:
			if place.id in visits: discovered.append(place.id)
	for place in PLACES:
		if value.get("tracked_place")==place.id: tracked_place=place.id
