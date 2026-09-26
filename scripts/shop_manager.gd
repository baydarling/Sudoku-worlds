class_name ShopManager
extends RefCounted
## Three-shelf Journey shop with rarity rolls and doubling rerolls.

enum Consumable { HEART, HINT }
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
	for slot in SHELF:
		offers[slot] = _roll_offer(economy, relics, used_relics, used_cons)


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
	if offer.is_consumable:
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


func _roll_offer(economy: EconomyManager, relics: RelicManager, used_relics: Dictionary, used_cons: Dictionary) -> Offer:
	if _rng.randf() < P_CONSUMABLE:
		var tonic: Offer = _pick_consumable(economy, used_cons, false)
		if tonic != null:
			return tonic
	var rarity: int = _roll_rarity()
	var relic_offer: Offer = _pick_relic(economy, relics, rarity, used_relics)
	if relic_offer != null:
		return relic_offer
	for fallback in [int(Rarity.COMMON), int(Rarity.RARE), int(Rarity.EPIC)]:
		if fallback == rarity:
			continue
		relic_offer = _pick_relic(economy, relics, fallback, used_relics)
		if relic_offer != null:
			return relic_offer
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


func _pick_relic(economy: EconomyManager, relics: RelicManager, rarity: int, used: Dictionary) -> Offer:
	var pool: Array[int] = []
	for index in RelicManager.COUNT:
		if relics.has_relic(index as RelicManager.Relic):
			continue
		if used.has(index):
			continue
		if RelicManager.rarity_of(index) != rarity:
			continue
		pool.append(index)
	if pool.is_empty():
		return null
	var pick: int = pool[_rng.randi_range(0, pool.size() - 1)]
	used[pick] = true
	var offer := Offer.new()
	offer.empty = false
	offer.is_consumable = false
	offer.relic = pick
	offer.rarity = rarity
	offer.price = _price_for_relic(economy, rarity)
	offer.title = RelicManager.NAMES[pick]
	offer.blurb = RelicManager.BLURBS[pick]
	offer.glyph = pick
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
