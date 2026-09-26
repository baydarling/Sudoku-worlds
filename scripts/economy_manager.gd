class_name EconomyManager
extends RefCounted
## Journey gold: level payout, world price inflation, and the purse.

class Payout extends RefCounted:
	var clear_reward: int = 0
	var flawless_bonus: int = 0
	var interest: int = 0
	var vine_bonus: int = 0
	var total: int = 0
	var combo_applied: bool = false


const CLEAR_REWARD: int = 500
const FLAWLESS_BONUS: int = 250
const BASE_VINE_GOLD: int = 100
const INTEREST_STEP: int = 250
const INTEREST_EACH: int = 50
const INTEREST_CAP: int = 250
const BASE_CONSUMABLE: int = 300
const BASE_COMMON: int = 600
const BASE_RARE: int = 1500
const BASE_EPIC: int = 3500
const WORLD_MULT: Array[float] = [1.0, 1.5, 2.2, 3.0]
const STAGES: int = 3
const FAIL_TAX_NUM: int = 1
const FAIL_TAX_DEN: int = 3
const MIDAS_MULT: float = 1.5

var gold: int = 0
var stage_level: int = 1


func reset() -> void:
	gold = 0
	stage_level = 1


func sync_level(level: int) -> void:
	stage_level = maxi(1, level)


func shop_visit() -> int:
	@warning_ignore("integer_division")
	return clampi(maxi(1, stage_level) / STAGES, 1, WORLD_MULT.size())


func world_of(level: int) -> int:
	@warning_ignore("integer_division")
	return (maxi(1, level) - 1) / STAGES


func world_multiplier(visit: int = -1) -> float:
	var slot: int = shop_visit() if visit < 1 else visit
	return WORLD_MULT[clampi(slot, 1, WORLD_MULT.size()) - 1]


func world_multiplier_for_level(level: int) -> float:
	return WORLD_MULT[clampi(world_of(level), 0, WORLD_MULT.size() - 1)]


func format_multiplier(mult: float) -> String:
	var snapped_mult: float = snapped(mult, 0.1)
	if is_equal_approx(snapped_mult, roundf(snapped_mult)):
		return "%d" % int(roundf(snapped_mult))
	return "%.1f" % snapped_mult


func interest_on(held: int) -> int:
	if held < INTEREST_STEP:
		return 0
	@warning_ignore("integer_division")
	return mini(INTEREST_CAP, (held / INTEREST_STEP) * INTEREST_EACH)


func vine_bounty(level: int = -1) -> int:
	var stage: int = stage_level if level < 1 else level
	return _nice_price(int(round(float(BASE_VINE_GOLD) * world_multiplier_for_level(stage))))


func quote_clear(mistakes: int, midas: bool, combo: bool, vines: int = 0) -> Payout:
	var slip := Payout.new()
	slip.clear_reward = CLEAR_REWARD
	if midas:
		slip.clear_reward = int(round(float(CLEAR_REWARD) * MIDAS_MULT))
	if mistakes <= 0:
		slip.flawless_bonus = FLAWLESS_BONUS
	slip.interest = interest_on(gold)
	slip.vine_bonus = vine_bounty() * maxi(0, vines)
	slip.total = slip.clear_reward + slip.flawless_bonus + slip.interest + slip.vine_bonus
	if combo:
		slip.total *= 2
		slip.combo_applied = true
	return slip


func collect_clear(mistakes: int, midas: bool, combo: bool, vines: int = 0) -> Payout:
	var slip: Payout = quote_clear(mistakes, midas, combo, vines)
	gold = maxi(0, gold + slip.total)
	return slip


func can_spend(amount: int) -> bool:
	return amount > 0 and gold >= amount


func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	gold -= amount
	return true


func take_fail_tax() -> int:
	if gold <= 0:
		return 0
	@warning_ignore("integer_division")
	var lost: int = (gold * FAIL_TAX_NUM) / FAIL_TAX_DEN
	gold -= lost
	return lost


func price_consumable(visit: int = -1) -> int:
	return _inflate(BASE_CONSUMABLE, visit)


func price_common(visit: int = -1) -> int:
	return _inflate(BASE_COMMON, visit)


func price_rare(visit: int = -1) -> int:
	return _inflate(BASE_RARE, visit)


func price_epic(visit: int = -1) -> int:
	return _inflate(BASE_EPIC, visit)


func _inflate(base: int, visit: int) -> int:
	return _nice_price(int(round(float(base) * world_multiplier(visit))))


func _nice_price(value: int) -> int:
	var amount: int = maxi(50, value)
	var step: int = 50
	if amount >= 10000:
		step = 100
	elif amount >= 2000:
		step = 50
	@warning_ignore("integer_division")
	return maxi(step, ((amount + step / 2) / step) * step)
