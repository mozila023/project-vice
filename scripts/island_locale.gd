extends RefCounted
const TH := {
	"EFATE / ISLAND LIFE":"เอฟาเต / ชีวิตบนเกาะ",
	"HEALTH":"สุขภาพ", "FOOD":"อาหาร", "WATER":"น้ำ", "ENERGY":"พลังงาน",
	"YOUR ISLAND PACK":"กระเป๋าของคุณ", "ISLAND AT REST":"พักผ่อนบนเกาะ",
	"Save your day, load, or return to the coast.":"บันทึก โหลดเกม หรือกลับไปผจญภัยต่อ",
	"Welcome, neighbour. The village needs fresh fish.":"ยินดีต้อนรับ หมู่บ้านของเราต้องการปลาสด",
	"A BITE!  REEL NOW":"ปลากินเหยื่อแล้ว! รีบดึงเบ็ด",
	"FISHING / Watch the float...":"กำลังตกปลา / คอยดูทุ่นไว้นะ...",
	"GET OUT":"ลงจากรถ", "REEL IN THE FISH":"ดึงเบ็ดขึ้น",
	"COOK FISH / 1 raw fish + 1 driftwood":"ย่างปลา / ปลาดิบ 1 ตัว + ไม้ 1 ชิ้น",
	"DRINK / REFILL AT THE WELL":"ดื่มน้ำจากบ่อ", "REST AT YOUR SHELTER":"พักผ่อนที่ที่พัก",
	"DRIVE THIS CAR":"ขับรถคันนี้",
	"Welcome to Efate. Meet the villagers and cast a line from the shore.":"ยินดีต้อนรับสู่เอฟาเต กด J อ่านภารกิจ แล้วไปพบมาเลียริมชายหาด",
	"Wait for the car to stop before getting in.":"รอให้รถหยุดก่อนขึ้นนะ",
	"W accelerate · S brake / reverse · A D steer · Space handbrake · E get out":"W เร่ง · S เบรก/ถอย · A D เลี้ยว · Space เบรกมือ · E ลงรถ",
	"Slow down before getting out.":"ลดความเร็วก่อนลงจากรถ",
	"No room to open the door here.":"ตรงนี้ไม่มีพื้นที่ให้ลงจากรถ",
	"Crunch! Watch the road.":"ชนแล้ว! ระวังทางข้างหน้า",
	"Get out of the car before fishing.":"ลงจากรถก่อนตกปลานะ",
	"Line reeled in.":"เก็บเบ็ดแล้ว",
	"Walk to the shoreline or the jetty before casting.":"เดินไปที่ชายฝั่งหรือท่าเรือก่อนเหวี่ยงเบ็ด",
	"Line cast. Watch the float. Press E / REEL when a fish bites.":"เหวี่ยงเบ็ดแล้ว คอยดูทุ่น กด E / ดึงเบ็ด เมื่อปลากินเหยื่อ",
	"You moved too far from your fishing line.":"คุณเดินห่างจากเบ็ดเกินไป",
	"A BITE! Press E / REEL now.":"ปลากินเหยื่อแล้ว! กด E / ดึงเบ็ด ตอนนี้เลย",
	"The fish escaped. Cast again when you are ready.":"ปลาหลุดไปแล้ว เหวี่ยงเบ็ดใหม่ได้เมื่อพร้อม",
	"Fish caught! Cook it at the beach fire or trade with a villager.":"ได้ปลาแล้ว! นำไปย่างที่กองไฟหรือแลกกับชาวบ้านได้",
	"Grilled fish ready. Press Q / EAT to eat it.":"ปลาย่างพร้อมแล้ว กด Q / กิน เพื่อรับประทาน",
	"Cooking needs one raw fish and one piece of driftwood.":"ต้องใช้ปลาดิบ 1 ตัว และไม้ลอยน้ำ 1 ชิ้นในการย่าง",
	"Fresh water. Your thirst is restored.":"น้ำสะอาด ช่วยดับกระหายแล้ว",
	"You rested for eight hours. A new day on the island.":"พักผ่อนแล้วแปดชั่วโมง เริ่มวันใหม่บนเกาะ",
	"Explore the beach, meet a villager, or press F to fish beside the water.":"สำรวจชายหาด พูดคุยกับชาวบ้าน หรือกด F เพื่อตกปลาริมน้ำ",
	"You ate grilled fish. Hunger restored.":"รับประทานปลาย่างแล้ว อิ่มขึ้นแล้ว",
	"Fresh coconut: food and water restored.":"มะพร้าวสดช่วยเติมอาหารและน้ำ",
	"No prepared food. Catch a fish and cook it, or gather coconuts.":"ไม่มีอาหารพร้อมกิน ลองตกปลามาย่างหรือเก็บมะพร้าวนะ",
	"Thank you! Three fresh fish traded for 45 vatu. Friendship +1.":"ขอบใจนะ! แลกปลาสด 3 ตัว ได้ 45 วาตู มิตรภาพ +1",
	"Bring three fresh fish to trade at the village.":"นำปลาสด 3 ตัวมาแลกที่หมู่บ้านนะ",
	"A home-cooked meal shared with your neighbours.":"อิ่มอร่อยกับอาหารที่เพื่อนบ้านทำให้",
	"A village meal costs 8 vatu.":"อาหารหนึ่งมื้อราคา 8 วาตู",
	"The Efate coast connects Port Vila, Mele, Eton and Undine Bay. The village needs fresh fish each day.":"ชายฝั่งเอฟาเตเชื่อมพอร์ตวิลา เมเล อีตัน และอ่าวอันดีน หมู่บ้านต้องการปลาสดทุกวัน",
	"Island life saved.":"บันทึกชีวิตบนเกาะแล้ว",
	"Save failed. Please check available storage.":"บันทึกไม่สำเร็จ โปรดตรวจพื้นที่เก็บข้อมูล",
	"No island-life save yet.":"ยังไม่มีข้อมูลบันทึก",
	"This save cannot be loaded.":"ไม่สามารถโหลดข้อมูลนี้ได้",
	"Welcome back to your island life.":"ยินดีต้อนรับกลับสู่ชีวิตบนเกาะ",
	"The villagers helped you back to your shelter. Eat and drink before exploring.":"ชาวบ้านช่วยพาคุณกลับที่พัก กินอาหารและดื่มน้ำก่อนออกสำรวจนะ",
	"MAP":"แผนที่", "BAG":"กระเป๋า", "FISH":"ตกปลา", "REEL":"ดึงเบ็ด", "USE":"ใช้",
	"EAT":"กิน", "JUMP":"กระโดด", "RUN":"วิ่ง", "WALK":"เดิน", "SAVE":"บันทึก",
	"LOAD":"โหลด", "RESUME":"เล่นต่อ", "CLOSE":"ปิด", "JOURNAL":"ภารกิจ", "STORY":"เนื้อเรื่อง",
	"TRADE 3 FISH  →  45 VATU":"แลกปลา 3 ตัว → 45 วาตู",
	"BUY A MEAL  /  8 VATU":"ซื้ออาหาร / 8 วาตู", "TALK ABOUT THE ISLAND":"คุยเรื่องเกาะ"
}

static func translate(value: String,language: String) -> String:
	if language!="th": return value
	if TH.has(value): return TH[value]
	if value.begins_with("TALK / "): return "คุย / "+value.trim_prefix("TALK / ")
	if value.begins_with("COLLECT "): return "เก็บ"+("มะพร้าว" if value.ends_with("COCONUT") else "ไม้ลอยน้ำ")
	if value.begins_with("Collected "): return "เก็บ"+("มะพร้าวแล้ว" if "coconut" in value else "ไม้ลอยน้ำแล้ว")
	return value
