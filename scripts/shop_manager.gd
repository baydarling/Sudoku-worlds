class_name ShopManager
extends RefCounted
## Three-shelf Journey shop with rarity rolls and doubling rerolls.

enum Consumable { HEART, HINT }
enum Tool { BOX, ROW, COLUMN, PLUS }
enum Rarity { COMMON, RARE, EPIC }

class Offer extends RefCounted:
	var empty: bool = true
	var is_consumable: bool = false
	var relic: int = -1
	var consumable: int = -1
	var rarity: int = 0
	var price: int = 0
	var title: String = ""
	var blurb: String = ""
	var glyph: int = 0
	var tag: String = ""
	var is_tool: bool = false
	var tool: int = -1


const SHELF: int = 3
const REROLL_BASE: int = 100
const P_CONSUMABLE: float = 0.22
const P_COMMON: float = 0.60
const P_RARE: float = 0.30
const CONSUMABLE_NAMES: Array[String] = ["Heart Tonic", "Ink Vial"]
const CONSUMABLE_BLURBS: Array[String] = [
	"+1 life on the next puzzle.",
	"+1 hint on the next puzzle.",
]
const CONSUMABLE_GLYPHS: Array[int] = [8, 9]
const RARITY_TAG: Array[String] = ["Common", "Rare", "Epic"]
const TOOL_NAMES: Array[String] = ["Box Seal", "Row Seal", "Column Seal", "Plus Brand"]
const TOOL_SHORT: Array[String] = ["Box", "Row", "Col", "+"]
const TOOL_BLURBS: Array[String] = [
	"Tap a cell. That box fills with the answer.",
	"Tap a cell. That row fills with the answer.",
	"Tap a cell. That column fills with the answer.",
	"Tap a cell. Its row and column fill.",
]
const TOOL_USE: Array[String] = [
	"Fills that box with the answer. Tap the grid.",
	"Fills that row with the answer. Tap the grid.",
	"Fills that column with the answer. Tap the grid.",
	"Fills that row and column. Tap the grid.",
]
const TOOL_GLYPHS: Array[int] = [10, 11, 12, 13]
## Box, row, and column are rare. The plus is epic.
const TOOL_RARITY: Array[int] = [1, 1, 1, 2]

var offers: Array[Offer] = []
var reroll_count: int = 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	_clear_shelves()


func begin_visit() -> void:
	reroll_count = 0


func reroll_price() -> int:
	return REROLL_BASE << reroll_count


func restock(economy: EconomyManager, relics: RelicManager) -> void:
	_clear_shelves()
	var used_relics: Dictionary = {}
	var used_cons: Dictionary = {}
	var used_tools: Dictionary = {}
	for slot in SHELF:
		offers[slot] = _roll_offer(economy, relics, used_relics, used_cons, used_tools)


func try_reroll(economy: EconomyManager, relics: RelicManager) -> bool:
	var cost: int = reroll_price()
	if not economy.spend(cost):
		return false
	reroll_count += 1
	restock(economy, relics)
	return true


func offer_at(slot: int) -> Offer:
	if slot < 0 or slot >= offers.size():
		return null
	return offers[slot]


func try_buy(slot: int, economy: EconomyManager, relics: RelicManager) -> bool:
	var offer: Offer = offer_at(slot)
	if offer == null or offer.empty:
		return false
	if not economy.spend(offer.price):
		return false
	if offer.is_tool:
		relics.add_tool(offer.tool)
	elif offer.is_consumable:
		_grant_consumable(offer.consumable, relics)
	else:
		relics.grant(offer.relic as RelicManager.Relic)
	offer.empty = true
	return true


func _grant_consumable(kind: int, relics: RelicManager) -> void:
	if kind == int(Consumable.HEART):
		relics.pending_lives += 1
	elif kind == int(Consumable.HINT):
		relics.pending_hints += 1


func _clear_shelves() -> void:
	offers.clear()
	for _slot in SHELF:
		var blank := Offer.new()
		blank.empty = true
		offers.append(blank)


func _roll_offer(economy: EconomyManager, relics: RelicManager, used_relics: Dictionary, used_cons: Dictionary, used_tools: Dictionary) -> Offer:
	if _rng.randf() < P_CONSUMABLE:
		var tonic: Offer = _pick_consumable(economy, used_cons, false)
		if tonic != null:
			return tonic
	var rarity: int = _roll_rarity()
	var shelf_offer: Offer = _pick_shelf(economy, relics, rarity, used_relics, used_tools)
	if shelf_offer != null:
		return shelf_offer
	for fallback in [int(Rarity.COMMON), int(Rarity.RARE), int(Rarity.EPIC)]:
		if fallback == rarity:
			continue
		shelf_offer = _pick_shelf(economy, relics, fallback, used_relics, used_tools)
		if shelf_offer != null:
			return shelf_offer
	var last_tonic: Offer = _pick_consumable(economy, used_cons, true)
	if last_tonic != null:
		return last_tonic
	return Offer.new()


func _roll_rarity() -> int:
	var roll: float = _rng.randf()
	if roll < P_COMMON:
		return int(Rarity.COMMON)
	if roll < P_COMMON + P_RARE:
		return int(Rarity.RARE)
	return int(Rarity.EPIC)


## Relics and aimable seals share a rarity roll. Seals can be bought again until the stack is full.
func _pick_shelf(economy: EconomyManager, relics: RelicManager, rarity: int, used_relics: Dictionary, used_tools: Dictionary) -> Offer:
	var relic_pool: Array[int] = []
	for index in RelicManager.COUNT:
		if relics.has_relic(index as RelicManager.Relic):
			continue
		if used_relics.has(index):
			continue
		if RelicManager.rarity_of(index) != rarity:
			continue
		relic_pool.append(index)
	var tool_pool: Array[int] = []
	if rarity != int(Rarity.COMMON):
		for kind in TOOL_NAMES.size():
			if TOOL_RARITY[kind] != rarity:
				continue
			if used_tools.has(kind):
				continue
			if relics.tool_count(kind) >= RelicManager.TOOL_CAP:
				continue
			tool_pool.append(kind)
	var total: int = relic_pool.size() + tool_pool.size()
	if total <= 0:
		return null
	var roll: int = _rng.randi_range(0, total - 1)
	if roll < relic_pool.size():
		var relic_index: int = relic_pool[roll]
		used_relics[relic_index] = true
		return _offer_relic(economy, relic_index, rarity)
	var tool_index: int = tool_pool[roll - relic_pool.size()]
	used_tools[tool_index] = true
	return _offer_tool(economy, tool_index, rarity)


func _offer_relic(economy: EconomyManager, pick: int, rarity: int) -> Offer:
	var offer := Offer.new()
	offer.empty = false
	offer.is_consumable = false
	offer.is_tool = false
	offer.relic = pick
	offer.rarity = rarity
	offer.price = _price_for_relic(economy, rarity)
	offer.title = RelicManager.NAMES[pick]
	offer.blurb = RelicManager.BLURBS[pick]
	offer.glyph = pick
	offer.tag = RARITY_TAG[clampi(rarity, 0, RARITY_TAG.size() - 1)]
	return offer


func _offer_tool(economy: EconomyManager, kind: int, rarity: int) -> Offer:
	var offer := Offer.new()
	offer.empty = false
	offer.is_consumable = false
	offer.is_tool = true
	offer.tool = kind
	offer.rarity = rarity
	offer.price = _price_for_relic(economy, rarity)
	offer.title = TOOL_NAMES[kind]
	offer.blurb = TOOL_BLURBS[kind]
	offer.glyph = TOOL_GLYPHS[kind]
	offer.tag = RARITY_TAG[clampi(rarity, 0, RARITY_TAG.size() - 1)]
	return offer


func _pick_consumable(economy: EconomyManager, used: Dictionary, allow_repeat: bool) -> Offer:
	var pool: Array[int] = []
	for kind in CONSUMABLE_NAMES.size():
		if allow_repeat or not used.has(kind):
			pool.append(kind)
	if pool.is_empty():
		return null
	var pick: int = pool[_rng.randi_range(0, pool.size() - 1)]
	used[pick] = true
	var offer := Offer.new()
	offer.empty = false
	offer.is_consumable = true
	offer.consumable = pick
	offer.price = economy.price_consumable()
	offer.title = CONSUMABLE_NAMES[pick]
	offer.blurb = CONSUMABLE_BLURBS[pick]
	offer.glyph = CONSUMABLE_GLYPHS[pick]
	offer.tag = "Consumable"
	return offer


func _price_for_relic(economy: EconomyManager, rarity: int) -> int:
	match rarity:
		int(Rarity.RARE):
			return economy.price_rare()
		int(Rarity.EPIC):
			return economy.price_epic()
		_:
			return economy.price_common()
