extends RefCounted
## New island life onboarding: Sunshine -> Pad Thai -> Seaside Inn.
const COMPLETE_STAGE := 5
var language := "th"
var stage := 0
var meals := 0
var relaxed := true
var discovered: Array[String] = []
var tracked_place := ""
var game: Node3D
const PLACES := [
	{"id":"Ifira Port","at":Vector2(-624.71524,1039.86354),"th":"Ifira Port","en":"The island supply line: public quay cargo lists and port office, 07–18.","fact_th":"เส้นทางเสบียงของเกาะ ตรวจรายการสินค้าบนลานสาธารณะ สำนักงาน 07–18 น."},
	{"id":"Evening Nakamal","at":Vector2(-747.3106,1257.95412),"th":"Evening Nakamal","en":"Temporary game name. An evening community gathering place, 16–23.","fact_th":"ชื่อชั่วคราวในเกม ศาลาพบปะชุมชนยามเย็น เปิด 16–23 น."},
	{"id":"Mele","at":Vector2(-978,282),"th":"เมเล","en":"Your home base beside Mele Bay. Greet your hosts and ask before entering homes or gardens.","fact_th":"ฐานพักริมอ่าวเมเล ทักทายเจ้าบ้านและขออนุญาตก่อนเข้าบ้านหรือสวนของผู้อื่น"},
	{"id":"Port Vila","at":Vector2(-508,876),"th":"พอร์ตวิลา","en":"Port Vila is on Efate. Its markets are a place to discover local produce and food such as laplap.","fact_th":"พอร์ตวิลาตั้งอยู่บนเอฟาเต ตลาดเป็นแหล่งพบผลผลิตและอาหารท้องถิ่น เช่น ลัป ลัป"},
	{"id":"Port Havannah","at":Vector2(-924,-1066),"th":"พอร์ตฮาวานนาห์","en":"Havannah Harbour lies northwest of Port Vila, with trips to nearby Moso and Lelepa islands.","fact_th":"อ่าวฮาวานนาห์อยู่ทางตะวันตกเฉียงเหนือของพอร์ตวิลา มีเส้นทางไปเกาะโมโซและเลเลปา"},
	{"id":"Eton","at":Vector2(2118,976),"th":"อีตัน","en":"Eton is on Efate's east coast. Its beach area is known for white sand and a freshwater inlet.","fact_th":"อีตันอยู่ชายฝั่งตะวันออกของเอฟาเต บริเวณชายหาดมีทรายขาวและทางน้ำจืดไหลมาบรรจบทะเล"},
	{"id":"Sunshine Wellness & Spa","at":Vector2(-447.56486,882.01488),"th":"Sunshine Wellness & Spa","en":"785C+68, Seaside. Maps: Sunshine Thai Massage Spa & Nail (Sea Oak 2007). Frontage and salon follow Maps/shop photos.","fact_th":"785C+68 ซีไซด์ Maps: Sunshine Thai Massage Spa & Nail (Sea Oak 2007) ด้านหน้าและห้องทำเล็บอ้างอิงภาพ Maps/เว็บร้าน"},
	{"id":"PAD THAI @ELLUK","at":Vector2(-570.83226,1116.6267),"th":"PAD THAI @ELLUK","en":"Elluk Road. Verified Maps pin; raised frontage, timber stairs and orange elephant signs follow supplied photos.","fact_th":"ถนน Elluk พิกัดตาม Maps หน้าร้านยกสูง บันไดไม้ และป้ายสีส้มลายช้างอ้างอิงรูปที่ส่งมา"},
	{"id":"Seaside Inn","at":Vector2(-398,1012),"th":"โรงแรม Seaside Inn","en":"A fictional playable inn: sleep until morning for 10 vatu. Luna will show you the entrance.","fact_th":"โรงแรมสมมติในเกม นอนถึงเช้าราคา 10 วาตู Luna จะพาไปรู้จักทางเข้า"}
]
const TITLES := [
	["Meet Luna at Sunshine","พบ Luna ที่ร้าน Sunshine"],
	["Follow Luna to Pad Thai","ตาม Luna ไปร้าน Pad Thai"],
	["Food and ingredients","ร้านอาหารและขายวัตถุดิบ"],
	["Follow Luna to the inn","ตาม Luna ไปโรงแรม"],
	["A room for the night","ที่พักสำหรับคืนนี้"],
	["Make yourself at home","เริ่มใช้ชีวิตบนเกาะ"]
]
const TASKS := [
	["Talk to your friend Luna outside Sunshine. Choose LET'S GO.","คุยกับ Luna เพื่อนสาวที่หน้าร้าน Sunshine แล้วเลือก ‘ไปกันเลย’"],
	["Walk behind Luna. She waits if you fall behind. Talk again when you reach Pad Thai.","เดินตาม Luna เธอจะรอหากคุณตามไม่ทัน แล้วคุยกันที่หน้าร้าน Pad Thai"],
	["Luna introduces the restaurant. Then choose SHOW ME THE INN.","Luna จะแนะนำการกินข้าวและขายวัตถุดิบ จากนั้นเลือก ‘ไปดูโรงแรม’"],
	["Follow Luna to Seaside Inn, then talk to her at the entrance.","ตาม Luna ไปโรงแรม Seaside Inn แล้วคุยกับเธอที่ทางเข้า"],
	["Learn about your room, then choose THANKS, LUNA.","รู้จักห้องพัก แล้วเลือก ‘ขอบใจนะ Luna’ เพื่อจบทัวร์"],
	["Eat and sell ingredients at Pad Thai. Sleep at Seaside Inn. Explore at your own pace.","กินข้าวและขายวัตถุดิบที่ Pad Thai นอนที่ Seaside Inn และออกสำรวจได้ตามใจ"]
]
const DIALOGUE := [
	["Hey! I'm Luna, your friend here on the island. Welcome to Sunshine!\nLet me show you Pad Thai, where you can eat and sell ingredients.\nThen we'll find you a room at Seaside Inn. Ready?", "มาแล้วเหรอ! ฉัน Luna เพื่อนเธอไง ยินดีต้อนรับสู่ Sunshine นะ\nเดี๋ยวพาไปรู้จักร้าน Pad Thai ไว้กินข้าวและขายวัตถุดิบ\nแล้วเราค่อยไปดูห้องพักที่โรงแรม Seaside Inn พร้อมไหม?"],
	["Stay close. Pad Thai is just along this road.\nI'll wait here whenever you need to catch up.","ตามฉันมาเลย ร้าน Pad Thai อยู่ตามถนนเส้นนี้\nถ้าตามไม่ทัน ฉันจะหยุดรอ ไม่ต้องรีบนะ"],
	["This is Pad Thai! Walk inside and interact to order a meal for 8 vatu.\nThey buy fresh fish for 15, coconuts for 5 and driftwood for 4 vatu each.\nYou can come back whenever you like. Next, let's see your inn!", "ถึง Pad Thai แล้ว! เดินเข้าไป กดใช้บริการเพื่อกินข้าวราคา 8 วาตู\nร้านรับซื้อปลาสดตัวละ 15 มะพร้าวลูกละ 5 และไม้ชิ้นละ 4 วาตู\nอยากแวะมาตอนไหนก็ได้ ต่อไปไปดูโรงแรมกัน!"],
	["Seaside Inn is nearby. Follow me and I'll show you the entrance.\nIt's a quiet place to recover after exploring.","โรงแรม Seaside Inn อยู่ใกล้ ๆ ตามฉันมา เดี๋ยวพาไปถึงทางเข้า\nเป็นที่พักเงียบ ๆ ไว้เติมพลังก่อนออกสำรวจวันใหม่นะ"],
	["Here we are! A night costs 10 vatu. Enter the inn and use the bed.\nYou'll wake at 08:00 with full Energy and some health restored.\nOne real hour is a full island day. You're ready to live here now!", "ถึงแล้ว! ห้องพักคืนละ 10 วาตู เดินเข้ามาแล้วกดใช้เตียงได้เลย\nจะตื่นเวลา 08:00 พร้อม Energy เต็มและฟื้นฟูสุขภาพ\nหนึ่งชั่วโมงจริงเท่ากับหนึ่งวันบนเกาะ เท่านี้ก็พร้อมใช้ชีวิตแล้วนะ!"],
	["You're all set! Pad Thai handles food and ingredients; Seaside Inn is your rest stop.\nI'll stay around the inn if you want to chat. Enjoy your new island life!", "ครบแล้วนะ! Pad Thai ไว้กินข้าวและขายของ Seaside Inn ไว้นอนพัก\nฉันจะอยู่แถวโรงแรม ถ้าอยากคุยก็แวะมาได้ ใช้ชีวิตบนเกาะให้สนุกนะ!"]
]
func l(en: String,th: String) -> String: return th if language=="th" else en
func title() -> String: return game.quests.title() if stage==COMPLETE_STAGE and game.quests.has_active() else l(TITLES[stage][0],TITLES[stage][1])
func task() -> String: return game.quests.task() if stage==COMPLETE_STAGE and game.quests.has_active() else l(TASKS[stage][0],TASKS[stage][1])
func dialogue() -> String: return l(DIALOGUE[stage][0],DIALOGUE[stage][1])
func tracker_title() -> String:
	if game.places.by_id.has(tracked_place): return game.places.by_id[tracked_place].name
	for place in PLACES:
		if place.id==tracked_place: return l(place.id,place.th)
	return title()
func tracker_task() -> String:
	return l("Follow the map to your destination.","ตามแผนที่ไปยังจุดหมาย") if tracked_place!="" else task()
func action_text() -> String:
	match stage:
		0: return l("LET'S GO","ไปกันเลย")
		2: return l("SHOW ME THE INN","ไปดูโรงแรม")
		4: return l("THANKS, LUNA","ขอบใจนะ Luna")
		5: return l("SEE YOU, LUNA","แล้วเจอกันนะ Luna")
	return l("LET'S KEEP WALKING","เดินต่อกันเลย")
func target() -> Vector3:
	if game.places.by_id.has(tracked_place): return game.places.target(tracked_place)
	for place in PLACES:
		if place.id==tracked_place: return Vector3(place.at.x,game.ground(place.at.x,place.at.y),place.at.y)
	if game.quests.has_active(): return game.quests.target()
	return game.luna.position if is_instance_valid(game.luna) else game.spawn
func progress() -> String:
	if tracked_place!="": return distance_text()
	if stage==COMPLETE_STAGE and game.quests.has_active(): return game.quests.progress()
	if stage==COMPLETE_STAGE: return l("TOUR COMPLETE","รู้จักสถานที่ครบแล้ว")
	return l("Places introduced: %d / 2","แนะนำสถานที่แล้ว: %d / 2") % (2 if stage>=4 else (1 if stage>=2 else 0))
func distance_text() -> String:
	return l("Distance: %d m","ระยะทาง: %d ม.") % int(Vector2(game.player.position.x,game.player.position.z).distance_to(Vector2(target().x,target().z)))
func advance() -> void:
	stage=mini(stage+1,COMPLETE_STAGE)
	game.tell(l("Luna: ","Luna: ")+task())
	game.guide.clear_path()
func arrive() -> void:
	if stage in [1,3]: advance()
func talk() -> void:
	if game.active_villager!="Luna": return
	if stage in [0,2,4]:
		tracked_place=""
		advance()
func event(kind: String) -> void:
	if kind=="cook": meals+=1
func update() -> void:
	for place in PLACES:
		if not place.id in discovered and Vector2(game.player.position.x,game.player.position.z).distance_to(place.at)<25:
			discovered.append(place.id)
			game.tell(l("Discovered: ","ค้นพบ: ")+l(place.id,place.th))
func data() -> Dictionary:
	var at: Vector3=game.luna.position
	return {"map_scale":10,"quests":game.quests.data(),"tour_version":1,"stage":stage,"meals":meals,"language":language,"relaxed":relaxed,"discovered":discovered.duplicate(),"tracked_place":tracked_place,"luna":[at.x,at.y,at.z]}
func restore(value: Variant) -> void:
	stage=0; meals=0; discovered.clear(); tracked_place=""
	game.quests.restore(value.get("quests",{}) if value is Dictionary else {})
	if not value is Dictionary: return
	if value.get("tour_version",0)==1:
		var saved=value.get("stage",0)
		if (saved is float or saved is int) and is_finite(float(saved)): stage=clampi(int(saved),0,COMPLETE_STAGE)
	language="en" if value.get("language")=="en" else "th"
	relaxed=value.get("relaxed",true)!=false
	var visits=value.get("discovered",[])
	if visits is Array:
		for place in PLACES:
			if place.id in visits: discovered.append(place.id)
		for id in visits:
			if id is String and game.places.by_id.has(id) and id not in discovered: discovered.append(id)
	for place in PLACES:
		if value.get("tracked_place")==place.id: tracked_place=place.id
	if game.places.by_id.has(value.get("tracked_place","")): tracked_place=value.tracked_place
	var at=value.get("luna",[])
	if at is Array and at.size()==3:
		var valid := true
		for number in at: valid=valid and (number is float or number is int) and is_finite(float(number))
		if valid and int(value.get("map_scale",20))==20:
			for i in range(3): at[i]=float(at[i])*2.0
		if valid and absf(float(at[0]))<2800 and absf(float(at[2]))<2800 and game.ground(float(at[0]),float(at[2]))>-.4:
			game.luna.position=Vector3(float(at[0]),maxf(float(at[1]),game.ground(float(at[0]),float(at[2]))+.05),float(at[2]))
	game.guide.clear_path()
