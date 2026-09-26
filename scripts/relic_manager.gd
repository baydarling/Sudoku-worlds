class_name RelicManager
extends RefCounted
## Journey inventory: owned relics, lives, and one-shot potions.

enum Relic { MAGNET, STEEL_SHIELD, COMBO_COIN, ORACLE_EYE, QUILL, SECOND_WIND, MIDAS_BAND, PHOENIX_FEATHER }
enum Guard { NONE, SECOND_WIND, PHOENIX }

const NAMES: Array[String] = [
	"Magnet",
	"Steel Shield",
	"Combo Coin",
	"Oracle Eye",
	"Quill",
	"Second Wind",
	"Midas Band",
	"Phoenix Feather",
]
const BLURBS: Array[String] = [
	"If a row or column has one empty cell, it fills.",
	"+1 life on every puzzle.",
	"Three correct fills in a row doubles this level's gold.",
	"Two empty cells start already solved.",
	"+1 hint on every puzzle.",
	"The first miss each puzzle costs no life.",
	"Clears pay 50% more gold.",
	"Once a journey, survive a wipe with 1 life.",
]
## Common, rare, epic — matches ShopManager.Rarity.
const RARITIES: Array[int] = [0, 1, 1, 1, 0, 0, 2, 2]
const BASE_LIVES: int = 3
const ORACLE_FILLS: int = 2
const COMBO_NEED: int = 3
const QUILL_HINTS: int = 1
const COUNT: int = 8
const STAGES: int = 3

var shop_pending: bool = false
var lives: int = BASE_LIVES
var combo_place_streak: int = 0
var combo_coin_armed: bool = false
var second_wind_ready: bool = false
var phoenix_spent: bool = false
var last_guard: Guard = Guard.NONE
var stage_level: int = 1
var pending_lives: int = 0
var pending_hints: int = 0
var _owned: Array[bool] = [false, false, false, false, false, false, false, false]


func reset_run() -> void:
	shop_pending = false
	stage_level = 1
	phoenix_spent = false
	last_guard = Guard.NONE
	pending_lives = 0
	pending_hints = 0
	for index in COUNT:
		_owned[index] = false
	reset_level()


func reset_level() -> void:
	lives = lives_budget() + take_pending_lives()
	combo_place_streak = 0
	combo_coin_armed = false
	second_wind_ready = has_relic(Relic.SECOND_WIND)
	last_guard = Guard.NONE


func has_relic(relic: Relic) -> bool:
	var index: int = int(relic)
	if index < 0 or index >= COUNT:
		return false
	return _owned[index]


static func rarity_of(index: int) -> int:
	return RARITIES[clampi(index, 0, COUNT - 1)]


func lives_budget() -> int:
	var extra: int = 1 if has_relic(Relic.STEEL_SHIELD) else 0
	return BASE_LIVES + extra


func extra_hints() -> int:
	return QUILL_HINTS if has_relic(Relic.QUILL) else 0


func take_pending_lives() -> int:
	var extra: int = maxi(0, pending_lives)
	pending_lives = 0
	return extra


func take_pending_hints() -> int:
	var extra: int = maxi(0, pending_hints)
	pending_hints = 0
	return extra


func sync_level(level: int) -> void:
	stage_level = maxi(1, level)


func grant(relic: Relic) -> void:
	var index: int = int(relic)
	if index < 0 or index >= COUNT or _owned[index]:
		return
	_owned[index] = true
	if relic == Relic.STEEL_SHIELD:
		lives += 1
	if relic == Relic.SECOND_WIND:
		second_wind_ready = true


func on_player_correct() -> void:
	if combo_coin_armed or not has_relic(Relic.COMBO_COIN):
		return
	combo_place_streak += 1
	if combo_place_streak >= COMBO_NEED:
		combo_coin_armed = true


func on_mistake(cost: int = 1) -> int:
	last_guard = Guard.NONE
	combo_place_streak = 0
	var want: int = maxi(1, cost)
	if second_wind_ready:
		second_wind_ready = false
		last_guard = Guard.SECOND_WIND
		return 0
	lives = maxi(0, lives - want)
	if lives <= 0 and _try_phoenix():
		lives = 1
		last_guard = Guard.PHOENIX
		return 0
	return want


func _try_phoenix() -> bool:
	if phoenix_spent or not has_relic(Relic.PHOENIX_FEATHER):
		return false
	phoenix_spent = true
	return true


func owned_mask() -> int:
	var mask: int = 0
	for index in COUNT:
		if _owned[index]:
			mask |= 1 << index
	return mask


func apply_mask(mask: int) -> void:
	for index in COUNT:
		_owned[index] = (mask & (1 << index)) != 0


func apply_on_deal(board: SudokuBoard, fresh: bool) -> void:
	board.score_mult = 1.0
	board.magnet_enabled = has_relic(Relic.MAGNET)
	if not fresh:
		return
	if has_relic(Relic.ORACLE_EYE):
		board.oracle_fill(ORACLE_FILLS)
	if has_relic(Relic.MAGNET):
		board.apply_magnet_chain()


func catalog_line() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for index in COUNT:
		if _owned[index]:
			parts.append(NAMES[index])
	if parts.is_empty():
		return "No relics yet"
	return " · ".join(parts)
