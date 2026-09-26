class_name RaceModeManager
extends RefCounted
## Mixed 4×4 / 6×6 race pacing. Main owns animation and calls these from its clock.

const START_SECONDS: float = 60.0
const CAP_SECONDS: float = 120.0
const MISTAKE_PENALTY: float = 4.0
const BONUS_MINI: float = 19.0
const BONUS_WIDE: float = 29.0
const PERFECT_BONUS: float = 5.0
const STREAK_NEED: int = 3
const STREAK_BONUS: float = 3.0
const DANGER_SECONDS: float = 10.0
const MID_START: int = 5
const LATE_START: int = 11
const MID_MINI_CHANCE: float = 0.60
const LATE_WIDE_CHANCE: float = 0.85

var stage_number: int = 1
var seconds: float = START_SECONDS
var grid_size: int = SudokuGenerator.MINI_SIZE
var last_bonus: float = 0.0
var last_perfect: bool = false
var mistakes_this_level: int = 0
var correct_streak: int = 0
var streak_paid: bool = false
var alive: bool = true
var danger_mode_active: bool = false


func reset() -> void:
	stage_number = 1
	seconds = START_SECONDS
	grid_size = SudokuGenerator.MINI_SIZE
	last_bonus = 0.0
	last_perfect = false
	mistakes_this_level = 0
	correct_streak = 0
	streak_paid = false
	alive = true
	danger_mode_active = false


## Countdown. Main calls this from `_process` while the race clock is live.
func process_clock(delta: float) -> bool:
	if not alive:
		_process_danger(delta)
		return false
	seconds = maxf(0.0, seconds - delta)
	if seconds <= 0.0:
		alive = false
		_process_danger(delta)
		return false
	_process_danger(delta)
	return true


## Threshold check each tick. Visual heartbeat lives on Main's timer label.
func _process_danger(_delta: float) -> void:
	danger_mode_active = alive and seconds <= DANGER_SECONDS


func on_wrong_move() -> float:
	mistakes_this_level += 1
	correct_streak = 0
	if not alive:
		return 0.0
	seconds = maxf(0.0, seconds - MISTAKE_PENALTY)
	if seconds <= 0.0:
		alive = false
	_process_danger(0.0)
	return seconds


func on_grid_completed() -> float:
	last_perfect = mistakes_this_level == 0
	last_bonus = bonus_for(grid_size)
	var paid: float = last_bonus
	if last_perfect:
		paid += PERFECT_BONUS
	seconds = minf(seconds + paid, CAP_SECONDS)
	_process_danger(0.0)
	stage_number += 1
	mistakes_this_level = 0
	correct_streak = 0
	streak_paid = false
	load_next_stage()
	return paid


func on_correct_fill() -> float:
	if not alive or streak_paid:
		return 0.0
	correct_streak += 1
	if correct_streak < STREAK_NEED:
		return 0.0
	correct_streak = 0
	streak_paid = true
	add_seconds(STREAK_BONUS)
	return STREAK_BONUS


func load_next_stage() -> int:
	grid_size = _grid_for_stage(stage_number)
	return grid_size


func add_seconds(amount: float) -> float:
	if amount <= 0.0 or not alive:
		return seconds
	seconds = minf(seconds + amount, CAP_SECONDS)
	_process_danger(0.0)
	return seconds


func bonus_for(size: int) -> float:
	if size == SudokuGenerator.WIDE_SIZE:
		return BONUS_WIDE
	return BONUS_MINI


func _grid_for_stage(stage: int) -> int:
	match stage:
		1, 2, 4:
			return SudokuGenerator.MINI_SIZE
		3:
			return SudokuGenerator.WIDE_SIZE
		_:
			if stage < LATE_START:
				if randf() < MID_MINI_CHANCE:
					return SudokuGenerator.MINI_SIZE
				return SudokuGenerator.WIDE_SIZE
			if randf() < LATE_WIDE_CHANCE:
				return SudokuGenerator.WIDE_SIZE
			return SudokuGenerator.MINI_SIZE
