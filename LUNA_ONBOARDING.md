# Luna's island welcome

New Game loads directly at Sunshine Wellness & Spa beside the player's friend Luna. Interact and choose LET'S GO. Luna physically walks to PAD THAI @ELLUK, waits when the player falls more than 15m behind, and resumes within 10m. Her local AStar grid checks buildings, cars and tree collision and routes around the raised restaurant's back wall.

Talk at Pad Thai and choose SHOW ME THE INN. Luna leads the player to Seaside Inn and introduces its room. THANKS, LUNA finishes onboarding; she stays near the inn while the player explores. This replaces the mandatory recovery fetch quests. Existing inventory/location saves remain usable; legacy story stages migrate into the new tour. Tour saves preserve the stage and Luna's position.

Enter Pad Thai and interact to buy a meal for 8 vatu (45 hunger, 20 thirst, 5 health, capped at 100). Sell one fresh fish for 15, one coconut for 5 or one driftwood for 4. Empty stock and insufficient funds are guarded.

Seaside Inn is a **fictional playable hotel** at game coordinates (-199,506), not a reconstruction of a real business. It has a physical entrance, reception and bed. Enter and interact to sleep until the next 08:00 for 10 vatu. Energy and Stamina refill, health improves and the calendar advances correctly. A short fade marks waking. The parcel excludes generated buildings/vegetation, its foundation reaches terrain, and a warm light comes on at night.

One active real hour equals one full game day: 3,600 real seconds = 24 game hours, or 2.5 real seconds per game minute. Morning is 05:00–09:00, late morning 09:00–12:00, afternoon 12:00–17:00, evening 17:00–20:00, and night 20:00–05:00. The sky/sun use this clock. Pausing or opening a modal menu pauses simulation; sleep skips directly to morning.

Luna's dialogue is written in Thai/English. The web build can read it using browser/device speech synthesis when available; text always remains usable. Existing island audio is retained.

Verification: `tools/check_luna_tour.gd` exercises the full physical escort, waiting, service prices, inventory guards, inn traversal, sleep, clock ratio/rollover and save migration. `tools/check_frontend.gd` checks direct New Game arrival. `tools/check_story.gd` remains a compatibility entry point for the tour test. Native poses: `luna_welcome`, `hotel_front`, `restaurant_service` in `tools/shot.gd`.
