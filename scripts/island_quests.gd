extends RefCounted
## Small stories unlocked after Luna's welcome tour; all rewards are saved and paid once.
var game: Node3D
var selected := 0
var manifests: Array[int] = []
var greetings: Array[String] = []
var bar_greet := false
var bar_story := false
var meal_delivered := false
var claimed: Array[int] = []
const NAMES := [["The island supply line","เส้นทางเสบียงของเกาะ"],["Halo, neighbour","Halo เพื่อนบ้าน"],["An evening together","เย็นนี้ที่ศาลาชุมชน"],["A meal to share","อาหารมื้อแบ่งปัน"]]
const REWARDS := [25,40,20,35]
func l(en: String,th: String) -> String: return game.story.l(en,th)
func unlocked() -> bool: return game.story.stage==game.story.COMPLETE_STAGE
func has_active() -> bool: return unlocked() and selected not in claimed
func title(id := -1) -> String:
	if id<0: id=selected
	return l(NAMES[id][0],NAMES[id][1])
func task(id := -1) -> String:
	if id<0: id=selected
	match id:
		0: return l("Inspect 3 cargo lists on Ifira's public quay, then report at the office (07–18).","ตรวจรายการสินค้า 3 จุดบนลานท่า Ifira แล้วรายงานที่สำนักงาน (07–18 น.)")
		1: return l("Chat with a resident in Mele, Eton and Port Havannah. Halo means hello; tankio means thank you.","คุยกับชาวบ้านที่ Mele, Eton และ Port Havannah · Halo คือสวัสดี Tankio คือขอบคุณ")
		2: return l("Visit Evening Nakamal between 16–23. Greet the host and listen to the community story.","แวะ Evening Nakamal เวลา 16–23 น. ทักทายเจ้าบ้านและฟังเรื่องราวชุมชน")
	return l("Bring 2 fresh fish to Pad Thai for a shared meal. Use COMMUNITY MEAL at the restaurant.","นำปลาสด 2 ตัวไป Pad Thai แล้วเลือก ‘มื้อแบ่งปัน’ เพื่อช่วยเตรียมอาหารให้เพื่อนบ้าน")
func progress(id := -1) -> String:
	if id<0: id=selected
	if id in claimed: return l("COMPLETED · reward received","สำเร็จ · รับรางวัลแล้ว")
	match id:
		0: return "%d / 3" % manifests.size()
		1: return "%d / 3" % greetings.size()
		2: return "%d / 2" % (int(bar_greet)+int(bar_story))
	return "%d / 2" % (2 if meal_delivered else mini(game.fish,2))
func ready(id: int) -> bool:
	return [manifests.size()==3,greetings.size()==3,bar_greet and bar_story,meal_delivered][id]
func target() -> Vector3:
	var at := Vector2(-570.83226,1116.6267)
	match selected:
		0:
			for i in range(3):
				if i not in manifests: return game.landmarks.manifests[i]
			return game.landmarks.port_desk
		1:
			for region in ["Mele","Eton","Port Havannah"]:
				if region in greetings: continue
				for zone in game.population.ZONES:
					if zone[0]==region: at=Vector2(zone[1],zone[2]); break
				break
		2: return game.landmarks.bar_desk
	return Vector3(at.x,game.ground(at.x,at.y),at.y)
func inspect(id: int) -> void:
	if not unlocked(): game.tell(l("Finish Luna's welcome tour first. These crates carry supplies for the island.","จบทัวร์กับ Luna ก่อนนะ ลังเหล่านี้คือเสบียงสำหรับชุมชนบนเกาะ")); return
	if id not in manifests: manifests.append(id)
	selected=0
	game.tell(l("Cargo list checked: ","ตรวจรายการแล้ว: ")+str(manifests.size())+" / 3 · "+l("Report to the office.","รายงานที่สำนักงานท่าเรือ"))
func on_talk(name: String) -> void:
	if not unlocked(): return
	var region: String=game.population.region_for(name)
	if region in ["Mele","Eton","Port Havannah"] and region not in greetings:
		greetings.append(region)
		game.tell(l("Halo! Tankio for visiting ","Halo! ขอบคุณที่มาเยือน ")+region+" · "+progress(1))
func neighbour_story() -> String:
	var region: String=game.population.region_for(game.active_villager)
	return l("Halo! Welcome to ","Halo! ยินดีต้อนรับสู่ ")+region+l(". Tankio means thank you.\nThe coast road connects our villages. Greet your hosts and ask before entering gardens or taking portraits.\nVisit neighbours during the day; most of us are home at night."," · Tankio แปลว่าขอบคุณ\nถนนเลียบฝั่งเชื่อมหมู่บ้านของเรา ทักทายเจ้าบ้านและขอก่อนเข้าสวนหรือถ่ายรูปบุคคลนะ\nแวะหาเพื่อนบ้านตอนกลางวัน กลางคืนส่วนใหญ่จะกลับไปพักแล้ว")
func action(kind: String) -> void:
	if not unlocked(): game.tell(l("Finish your welcome tour with Luna first.","จบทัวร์แนะนำเกาะกับ Luna ก่อนนะ")); return
	match kind:
		"port_report":
			if game.panel!="port" or game.day_time<7 or game.day_time>=18 or game.player.position.distance_to(game.landmarks.port_desk)>4: return
			if ready(0): claim(0)
			else: game.tell(task(0))
		"bar_greet", "bar_story":
			if game.panel!="nakamal" or not game.landmarks.bar_open or game.player.position.distance_to(game.landmarks.bar_desk)>6: return
			if kind=="bar_greet": bar_greet=true
			else: bar_story=true
			game.tell(l("Tavi: A nakamal is a place for conversation and community. Greet your host; ask before taking photographs. Staying to listen is welcome too.","Tavi: Nakamal เป็นที่พบปะพูดคุยของชุมชน ทักทายเจ้าบ้านและขอก่อนถ่ายรูปนะ แค่มานั่งฟังเรื่องราวด้วยกันก็ยินดีแล้ว"))
			if ready(2): claim(2)
		"community_meal":
			if game.panel!="restaurant" or not game.restaurant_inside(): return
			if meal_delivered: game.tell(l("The shared meal is already prepared. Thank you!","มื้อแบ่งปันเตรียมเรียบร้อยแล้ว ขอบคุณนะ!")); return
			if game.fish<2: game.tell(task(3)); return
			game.fish-=2; meal_delivered=true
			game.tell(l("Two fresh fish for your neighbours. A meal brings the island together.","ปลาสดสองตัวสำหรับเพื่อนบ้าน อาหารหนึ่งมื้อทำให้คนบนเกาะได้มาพบกัน"))
			claim(3)
func claim(id: int) -> void:
	if not ready(id) or id in claimed: return
	claimed.append(id)
	game.coins+=REWARDS[id]; game.friendship+=2
	game.tell(title(id)+l(" · Complete +%d vatu"," · สำเร็จ +%d วาตู")%REWARDS[id])
func data() -> Dictionary:
	return {"selected":selected,"manifests":manifests.duplicate(),"greetings":greetings.duplicate(),"bar_greet":bar_greet,"bar_story":bar_story,"meal":meal_delivered,"claimed":claimed.duplicate()}
func restore(value: Variant) -> void:
	selected=0; manifests.clear(); greetings.clear(); claimed.clear(); bar_greet=false; bar_story=false; meal_delivered=false
	if not value is Dictionary: return
	var saved=value.get("selected",0)
	if (saved is int or saved is float) and is_finite(float(saved)): selected=clampi(int(saved),0,3)
	for i in range(3):
		if i in saved_array(value,"manifests"): manifests.append(i)
	for region in ["Mele","Eton","Port Havannah"]:
		if region in saved_array(value,"greetings"): greetings.append(region)
	bar_greet=value.get("bar_greet",false)==true
	bar_story=value.get("bar_story",false)==true
	meal_delivered=value.get("meal",false)==true
	for i in range(4):
		if i in saved_array(value,"claimed") and ready(i): claimed.append(i)
func saved_array(value: Dictionary,key: String) -> Array:
	var entries=value.get(key,[])
	return entries if entries is Array else []
