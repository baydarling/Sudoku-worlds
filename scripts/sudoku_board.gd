class_name SudokuBoard
extends Control
## Draws the 9x9 grid and handles the player's input.

const AlgaePatchScript: GDScript = preload("res://scripts/algae_patch.gd")
const PoisonVineScript: GDScript = preload("res://scripts/poison_vine.gd")
const CyberLockScript: GDScript = preload("res://scripts/cyber_lock.gd")
const SandCacheScript: GDScript = preload("res://scripts/sand_cache.gd")

## Emitted once every cell is filled in without breaking a Sudoku rule.
signal solved
## Emitted whenever the number of empty cells changes.
signal progress_changed(remaining: int)
## Emitted when how many of each digit sit on the board changes.
signal digits_changed
## Emitted when a clean line scores, and when a mistake breaks the streak.
signal score_changed(score: int, streak: int)
## Emitted when a row, column, or box is completed correctly.
signal unit_cleared
## Emitted when a filled digit is legal on the board right now.
signal correct_placed
## Emitted when pencil-mark mode is switched, including from the keyboard.
signal notes_mode_changed(enabled: bool)
## Emitted when the undo history becomes usable or runs out.
signal undo_availability_changed(can_undo: bool)
## Emitted when a filled digit does not match the puzzle's answer.
## `life_cost` is 2 on a still-active poison cell, otherwise 1.
signal mistake_made(index: int, life_cost: int)
## Steel Shield turned away the first clashing digit this puzzle.
signal aegis_spent
## The player tapped a cell while a shop seal is armed.
signal seal_target(index: int)
## Emitted when a poison cell is filled with the right digit.
signal poison_solved(index: int)
## Emitted when a Neon cyber lock opens after its row or column is solved.
signal cyber_unlocked(index: int)
## Emitted when a Water algae patch is fully cleaned.
signal algae_cleaned(index: int)
## Emitted on each algae tap before the patch rips off.
signal algae_tapped(index: int)
## Emitted on the tap that starts the rip, so the splash is not delayed.
signal algae_splashed(index: int)
## Emitted when a marked Desert cell is solved and its cache is uncovered.
signal sand_cache_solved(index: int)
## Emitted whenever Ember's heat meter fills.
signal ember_overheated
## Emitted when one correct digit finishes more than one unit.
signal combo_cleared(unit_count: int, gained: int)

const CLASSIC_GRID: int = 9
const CLASSIC_BOX: int = 3
const CLASSIC_CELLS: int = 81
var grid_size: int = CLASSIC_GRID
var box_width: int = CLASSIC_BOX
var box_height: int = CLASSIC_BOX
var cell_count: int = CLASSIC_CELLS
## The well is drawn smaller than the control so it sits back in the black.
const STAGE_SCALE: float = 0.94
## Dark lip between the well edge and the grid, as a share of the well width.
const GRID_PADDING_RATIO: float = 0.042
const SPARK_COUNT: int = 26
const SAND_GRAVITY: float = 280.0
const DRIFT_LIMIT: int = 180
## Clean row, column, or box. A streak multiplies this.
const UNIT_POINTS: int = 100
const SCORE_POP_LIFE: float = 1.2
const POP_SEPARATION: float = 52.0
const STREAK_BREAK_LIFE: float = 0.9

const LOCK_DURATION: float = 0.42
const ORACLE_STAGGER: float = 0.34
const ORACLE_LIFE: float = 0.92
## A finished line shares this many motes. A double or triple must not multiply it by every cell.
const BURST_CAP: int = 36
const CONFLICT_MOTE_COUNT: int = 3
## The light crosses the finished unit, then the whole glow fades away.
const SWEEP_TRAVEL_TIME: float = 0.8
const SWEEP_FADE_TIME: float = 0.9
const SWEEP_DURATION: float = SWEEP_TRAVEL_TIME + SWEEP_FADE_TIME
## How long the win screen waits so the last line-clear can play out.
const CELEBRATION_TIME: float = SWEEP_DURATION
## Where each difficulty sits between the quiet look and the neon look.
const MOOD_DIFFICULTY: Array[float] = [0.62, 0.4, 0.18]
const MOOD_BREATHE: float = 0.16
const MOOD_CYCLE: float = 26.0

enum ArtStyle { DESERT, WATER, NIGHT, FOREST, EMBER }

const COLOR_CONFLICT_TEXT: Color = Color(0.93, 0.64, 0.7)
const COLOR_CONFLICT_CELL: Color = Color(0.72, 0.34, 0.44, 0.1)
const COLOR_NONE: Color = Color(0, 0, 0, 0)

## How many moves the player can walk back.
const UNDO_LIMIT: int = 100
const HAPTIC_PLACE_MS: int = 14
const HAPTIC_CLEAR_MS: int = 44
const HAPTIC_PLACE_AMP: float = 0.28
const HAPTIC_CLEAR_AMP: float = 0.5
const ALGAE_COVER: int = 5
const POISON_MIN: int = 3
const POISON_MAX: int = 8
const POISON_FLASH_LIFE: float = 0.28
const CYBER_LOCK_MIN: int = 2
const CYBER_LOCK_MAX: int = 6
const CYBER_LOCK_TRIES: int = 12
const SAND_CACHE_MIN: int = 3
const SAND_CACHE_MAX: int = 5
const EMBER_CELL_COOL: float = 0.025
const EMBER_UNIT_COOL: float = 0.12
const EMBER_MISTAKE_HEAT: float = 0.12
const EMBER_RESET_HEAT: float = 0.3


## A restore point taken just before a move changes the board.
class Snapshot extends RefCounted:
	var values: Array[int] = []
	var notes: Array[int] = []
	var selected: int = -1


## A correct placement: the cell flashes and a ring expands from it.
class LockPulse extends RefCounted:
	var index: int = -1
	var age: float = 0.0


## Oracle Eye revealing one true pencil mark. Negative age is the wait before this cell.
class OracleFlash extends RefCounted:
	var index: int = -1
	var digit: int = 0
	var age: float = 0.0


## A row, column, or box that just became complete.
class UnitSweep extends RefCounted:
	var cells: PackedInt32Array = PackedInt32Array()
	var age: float = 0.0


## A +points burst that sits just outside the 9x9.
class ScorePop extends RefCounted:
	var origin: Vector2 = Vector2.ZERO
	var drift: Vector2 = Vector2.ZERO
	var amount: int = 0
	var streak: int = 1
	var age: float = 0.0
	var life: float = SCORE_POP_LIFE
	var broken: bool = false
	var clock: bool = false
	var gold: bool = false
	var caption: String = ""


## A grain of sand or a drop of water. Ambient ones wrap; line-clear ones die.
class Drift extends RefCounted:
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var age: float = 0.0
	var life: float = 1.0
	var size: float = 2.0
	var seed: float = 0.0
	var sand: bool = false
	var leaf: bool = false
	var flame: bool = false
	var wraps: bool = false
	var base_size: float = 2.0
	var hollow: float = 0.0


## One world's quiet or vivid colors. Mood blends the two.
class Palette extends RefCounted:
	var well_top: Color
	var well_bottom: Color
	var line_thin: Color
	var line_thick: Color
	var given: Color
	var player: Color
	var note: Color
	var selected: Color
	var same_digit: Color
	var peer: Color
	var neon: Color
	var lock: Color
	var sky_top: Color
	var sky_bottom: Color

## Heavier face for the clues the puzzle starts with.
@export var given_font: Font
## Lighter face for the digits the player types in.
@export var entry_font: Font

## While true, digits become pencil marks instead of answers.
var notes_mode: bool = false:
	set(value):
		if notes_mode == value:
			return
		notes_mode = value
		notes_mode_changed.emit(value)

var _givens: Array[int] = []
var _solution: Array[int] = []
var _values: Array[int] = []
## One bitmask per cell; bit 0 means the digit 1 is pencilled in.
var _notes: Array[int] = []
var _conflicts: Array[bool] = []
var _undo_stack: Array[Snapshot] = []
var _locks: Array[LockPulse] = []
var _oracle: Array[OracleFlash] = []
var _sweeps: Array[UnitSweep] = []
var _score_pops: Array[ScorePop] = []
## Points for this puzzle. A clean row, column, or box adds more on a streak.
var score: int = 0
var _streak: int = 0
## The 9 rows, 9 columns and 9 boxes, each as a list of cell indices.
var _units: Array[PackedInt32Array] = []
var _spark_positions: PackedVector2Array = PackedVector2Array()
var _spark_seeds: PackedFloat32Array = PackedFloat32Array()
var _flow: Array[Drift] = []
var _drifts: Array[Drift] = []
## 0 hides this world's motes. 1 is the designed look. Size is 1 at the designed size.
var particle_strength: float = 0.7
var particle_size_scale: float = 1.0
var burst_strength: float = 1.0
var burst_size_scale: float = 1.0
var burst_hollow: float = 0.0
var burst_fall: float = 0.0
## Race uses bigger pops so time hits and scores read at a glance.
var loud_pops: bool = false
## Last cell a player (or hint/magnet) wrote. Captions park beside it instead of stacking dead-center.
var last_place_index: int = -1
## Journey Bloom leftover; relics no longer scale unit points.
var score_mult: float = 1.0
## Journey Magnet relic fills the last empty cell in a row or column.
var magnet_enabled: bool = false
## True while Magnet is writing, so Relay ignores those fills.
var magnet_filling: bool = false
## Steel Shield can still bounce the first clashing digit this puzzle.
var aegis_ready: bool = false
## True while Relay is writing, so that fill does not count toward the next Relay.
var relay_filling: bool = false
## Armed shop seal: 0 box, 1 row, 2 column, 3 plus. -1 means a tap places a digit.
var seal_aim: int = -1
## True while a seal is writing, so those fills do not count as player moves.
var seal_filling: bool = false
var _magnet_busy: bool = false
var _ambient_time: float = 0.0
## 0 is the dim board, 1 is the full neon board. It eases toward `_mood_target`.
var mood: float = 0.72
var _mood_difficulty: float = 0.62
var _mood_progress: float = 0.0
var _mood_lift: float = 0.0
var _style: ArtStyle = ArtStyle.NIGHT
var _quiet: Palette = Palette.new()
var _vivid: Palette = Palette.new()
## Read by the stage background and the win ring.
var sky_top: Color = Color(0.02, 0.0, 0.04)
var sky_bottom: Color = Color(0.05, 0.0, 0.08)
var glow_color: Color = Color(0.96, 0.5, 1.0)
var haptics_enabled: bool = true
## When true, a player digit that is not the finished answer is painted red. It is still a legal place.
var check_mistakes: bool = false:
	set(value):
		if check_mistakes == value:
			return
		check_mistakes = value
		if not _units.is_empty():
			_update_conflicts()
			queue_redraw()
var _selected: int = -1
var _locked: bool = true
var _play_enabled: bool = true
var _fx_paused: bool = false
var _hit_cells: Array[Control] = []
var _algae: Dictionary = {}
## Original poison marks. Visuals hide themselves once the cell matches the answer.
var _poison: Dictionary = {}
var _poison_bounty: int = 0
var _poison_flash: ColorRect
var _poison_flash_tween: Tween
## Neon cyber locks. Overlay nodes stay even after they open.
var _cyber: Dictionary = {}
## Desert caches are passive marks: solve the cell normally to uncover one.
var _sand_caches: Dictionary = {}
var _sand_bounty: int = 0
## Ember pressure rises only while the board accepts play.
var ember_heat: float = 0.0
var _ember_active: bool = false
var _ember_rate: float = 0.0
var _ember_flash: float = 0.0


func set_play_enabled(enabled: bool) -> void:
	_play_enabled = enabled
	if not enabled and _selected != -1:
		_selected = -1
		queue_redraw()


func configure_grid(size: int) -> void:
	var next_size: int = SudokuGenerator.normalize_size(size)
	var dims: Vector2i = SudokuGenerator.box_dims(next_size)
	var next_count: int = next_size * next_size
	if grid_size == next_size and box_width == dims.x and box_height == dims.y and cell_count == next_count and _hit_cells.size() == next_count:
		return
	grid_size = next_size
	box_width = dims.x
	box_height = dims.y
	cell_count = next_count
	_selected = -1
	last_place_index = -1
	_givens.clear()
	_givens.resize(cell_count)
	_solution.clear()
	_solution.resize(cell_count)
	_values.clear()
	_values.resize(cell_count)
	_notes.clear()
	_notes.resize(cell_count)
	_conflicts.clear()
	_conflicts.resize(cell_count)
	_undo_stack.clear()
	_clear_effects()
	_build_units()
	_rebuild_hit_cells()
	queue_redraw()


func _ready() -> void:
	_givens.resize(cell_count)
	_solution.resize(cell_count)
	_values.resize(cell_count)
	_notes.resize(cell_count)
	_conflicts.resize(cell_count)
	_build_units()
	_build_sparkles()
	_build_hit_cells()
	set_art_style(ArtStyle.NIGHT)
	resized.connect(_on_board_resized)


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _fx_paused:
		return
	if not _hit_cells.is_empty():
		var expected: float = _get_grid_rect().size.x / float(grid_size)
		if expected > 1.0 and absf(_hit_cells[0].size.x - expected) > 0.5:
			_layout_hit_cells()
	var step: float = minf(delta, 0.033)
	_ambient_time += step
	var follow: float = 1.0 - exp(-step * 1.4)
	_mood_lift = maxf(_mood_lift - step * 0.4, 0.0)
	mood = lerpf(mood, _mood_target(), follow)
	_advance_effects(step)
	_advance_drifts(step)
	_advance_score_pops(step)
	_advance_ember_heat(step)
	queue_redraw()


func load_puzzle(puzzle: SudokuGenerator.Puzzle) -> void:
	configure_grid(puzzle.grid_size)
	_givens = puzzle.givens.duplicate()
	_solution = puzzle.solution.duplicate()
	_values = puzzle.givens.duplicate()
	_notes.fill(0)
	_conflicts.fill(false)
	_undo_stack.clear()
	_clear_effects()
	clear_algae()
	clear_poison()
	clear_cyber_locks()
	clear_sand_caches()
	clear_ember_pressure()
	score = 0
	_streak = 0
	magnet_filling = false
	_magnet_busy = false
	_mood_lift = 0.0
	_selected = -1
	last_place_index = -1
	_locked = false
	queue_redraw()
	_emit_progress()
	score_changed.emit(score, _streak)
	undo_availability_changed.emit(false)


func can_save_run() -> bool:
	return _solution.size() == cell_count and not _locked and not _is_solved()


func export_run() -> Dictionary:
	return {
		"givens": _to_packed(_givens),
		"solution": _to_packed(_solution),
		"values": _to_packed(_values),
		"notes": _to_packed(_notes),
		"undo": _export_undo(),
		"selected": _selected,
		"score": score,
		"streak": _streak,
		"notes_mode": notes_mode,
		"algae": algae_indices(),
		"poison": poison_indices(),
		"cyber": cyber_indices(),
		"sand_caches": sand_cache_indices(),
		"ember_active": _ember_active,
		"ember_heat": ember_heat,
	}


func restore_run(data: Dictionary) -> bool:
	var givens: PackedInt32Array = data.get("givens", PackedInt32Array())
	var solution: PackedInt32Array = data.get("solution", PackedInt32Array())
	var values: PackedInt32Array = data.get("values", PackedInt32Array())
	var notes: PackedInt32Array = data.get("notes", PackedInt32Array())
	var undo: PackedInt32Array = data.get("undo", PackedInt32Array())
	if not _valid_cells(givens, 0, grid_size) or not _valid_cells(solution, 1, grid_size):
		return false
	if not _valid_cells(values, 0, grid_size) or not _valid_cells(notes, 0, _digit_mask()):
		return false
	_givens = _from_packed(givens)
	_solution = _from_packed(solution)
	_values = _from_packed(values)
	_notes = _from_packed(notes)
	for index in cell_count:
		if _givens[index] != 0:
			_values[index] = _givens[index]
	if not _import_undo(undo):
		_undo_stack.clear()
	_selected = clampi(int(data.get("selected", -1)), -1, cell_count - 1)
	score = maxi(0, int(data.get("score", 0)))
	_streak = maxi(0, int(data.get("streak", 0)))
	_clear_effects()
	_update_conflicts()
	if _is_solved():
		return false
	_mood_lift = 0.0
	_locked = false
	queue_redraw()
	_emit_progress()
	score_changed.emit(score, _streak)
	undo_availability_changed.emit(not _undo_stack.is_empty())
	notes_mode = bool(data.get("notes_mode", false))
	_restore_algae(data.get("algae", PackedInt32Array()))
	_restore_poison(data.get("poison", PackedInt32Array()))
	_restore_cyber_locks(data.get("cyber", PackedInt32Array()))
	_restore_sand_caches(data.get("sand_caches", PackedInt32Array()))
	_ember_active = bool(data.get("ember_active", false))
	ember_heat = clampf(float(data.get("ember_heat", 0.0)), 0.0, 1.0)
	return true


func _to_packed(values: Array[int]) -> PackedInt32Array:
	var packed := PackedInt32Array()
	packed.resize(values.size())
	for index in values.size():
		packed[index] = values[index]
	return packed


func _from_packed(packed: PackedInt32Array) -> Array[int]:
	var values: Array[int] = []
	values.resize(packed.size())
	for index in packed.size():
		values[index] = packed[index]
	return values


func _valid_cells(packed: PackedInt32Array, minimum: int, maximum: int) -> bool:
	if packed.size() != cell_count:
		return false
	for value in packed:
		if value < minimum or value > maximum:
			return false
	return true


func _export_undo() -> PackedInt32Array:
	var packed := PackedInt32Array()
	packed.append(_undo_stack.size())
	for snap in _undo_stack:
		packed.append(snap.selected)
		for value in snap.values:
			packed.append(value)
		for mark in snap.notes:
			packed.append(mark)
	return packed


func _import_undo(packed: PackedInt32Array) -> bool:
	_undo_stack.clear()
	if packed.is_empty():
		return true
	var count: int = packed[0]
	if count < 0 or count > UNDO_LIMIT:
		return false
	var stride: int = 1 + cell_count + cell_count
	if packed.size() != 1 + count * stride:
		return false
	var offset: int = 1
	for _snap in count:
		var snapshot := Snapshot.new()
		snapshot.selected = packed[offset]
		offset += 1
		snapshot.values.resize(cell_count)
		for index in cell_count:
			snapshot.values[index] = packed[offset]
			offset += 1
		snapshot.notes.resize(cell_count)
		for index in cell_count:
			snapshot.notes[index] = packed[offset]
			offset += 1
		_undo_stack.append(snapshot)
	return true


## Difficulty sets the resting brightness, progress lifts it, and a slow wave drifts it.
func set_mood_sources(difficulty: int, remaining: int, blanks: int, snap: bool = false) -> void:
	var index: int = clampi(difficulty, 0, MOOD_DIFFICULTY.size() - 1)
	_mood_difficulty = MOOD_DIFFICULTY[index]
	if blanks <= 0:
		_mood_progress = 0.0
	else:
		_mood_progress = clampf(1.0 - float(remaining) / float(blanks), 0.0, 1.0)
	if snap:
		mood = _mood_target()
		queue_redraw()


## Pushes the board to the vivid end of its world for a moment, then lets it settle.
func lift_mood() -> void:
	_mood_lift = 0.85


func set_fx_paused(paused: bool) -> void:
	_fx_paused = paused
	if not paused:
		queue_redraw()


## Switches the stage colors. Mood still blends this world's quiet and vivid ends.
func set_art_style(style: ArtStyle) -> void:
	var same: bool = _style == style
	_style = style
	_quiet = _palette_for(style, false)
	_vivid = _palette_for(style, true)
	sky_top = _vivid.sky_top
	sky_bottom = _vivid.sky_bottom
	glow_color = _vivid.neon
	if not same:
		_drifts.clear()
		_rebuild_flow()
	queue_redraw()


func current_style() -> ArtStyle:
	return _style


func apply_world_look(look: Resource) -> void:
	if look == null:
		return
	particle_strength = clampf(_look_float(look, "particle_strength", 0.7), 0.0, 2.0)
	particle_size_scale = clampf(_look_float(look, "particle_size", 1.0), 0.4, 2.4)
	burst_strength = clampf(_look_float(look, "burst_strength", 1.0), 0.0, 2.0)
	burst_size_scale = clampf(_look_float(look, "burst_size", 1.0), 0.2, 2.4)
	burst_hollow = clampf(_look_float(look, "burst_hollow", 0.0), 0.0, 1.0)
	var fall_default: float = 1.0 if _style == ArtStyle.DESERT else 0.0
	burst_fall = clampf(_look_float(look, "burst_fall", fall_default), 0.0, 2.5)
	queue_redraw()


func _look_float(look: Resource, key: String, fallback: float) -> float:
	var value: Variant = look.get(key)
	if value == null:
		return fallback
	return float(value)


func _style_strength() -> float:
	return particle_strength


func _style_size() -> float:
	return particle_size_scale


func _mood_target() -> float:
	var breathe: float = sin(_ambient_time * TAU / MOOD_CYCLE) * MOOD_BREATHE
	return clampf(_mood_difficulty + _mood_progress * 0.3 + breathe + _mood_lift, 0.0, 1.0)


func _paint(quiet: Color, vivid: Color) -> Color:
	return quiet.lerp(vivid, mood)


func _glow_amount() -> float:
	return lerpf(0.28, 1.0, mood)


func _c_well_top() -> Color:
	return _paint(_quiet.well_top, _vivid.well_top)


func _c_well_bottom() -> Color:
	return _paint(_quiet.well_bottom, _vivid.well_bottom)


func _c_line_thin() -> Color:
	return _paint(_quiet.line_thin, _vivid.line_thin)


func _c_line_thick() -> Color:
	return _paint(_quiet.line_thick, _vivid.line_thick)


func _c_given() -> Color:
	return _paint(_quiet.given, _vivid.given)


func _c_player() -> Color:
	return _paint(_quiet.player, _vivid.player)


func _c_note() -> Color:
	return _paint(_quiet.note, _vivid.note)


func _c_selected() -> Color:
	return _paint(_quiet.selected, _vivid.selected)


func _c_same() -> Color:
	return _paint(_quiet.same_digit, _vivid.same_digit)


func _c_peer() -> Color:
	return _paint(_quiet.peer, _vivid.peer)


func _c_neon() -> Color:
	return _paint(_quiet.neon, _vivid.neon)


func _palette_for(style: ArtStyle, vivid: bool) -> Palette:
	var palette := Palette.new()
	match style:
		ArtStyle.DESERT:
			_fill_desert(palette, vivid)
		ArtStyle.WATER:
			_fill_water(palette, vivid)
		ArtStyle.FOREST:
			_fill_forest(palette, vivid)
		ArtStyle.EMBER:
			_fill_ember(palette, vivid)
		_:
			_fill_night(palette, vivid)
	return palette


func _fill_desert(palette: Palette, vivid: bool) -> void:
	if vivid:
		palette.well_top = Color(0.05, 0.16, 0.34)
		palette.well_bottom = Color(0.22, 0.08, 0.02)
		palette.line_thin = Color(1.0, 0.68, 0.22, 0.88)
		palette.line_thick = Color(1.0, 0.84, 0.4, 1.0)
		palette.given = Color(1.0, 0.95, 0.84)
		palette.player = Color(1.0, 0.74, 0.22)
		palette.note = Color(0.95, 0.68, 0.32, 0.85)
		palette.selected = Color(1.0, 0.55, 0.12, 0.4)
		palette.same_digit = Color(1.0, 0.7, 0.25, 0.28)
		palette.peer = Color(0.55, 0.28, 0.08, 0.22)
		palette.neon = Color(1.0, 0.62, 0.12)
		palette.lock = Color(1.0, 0.92, 0.62)
		palette.sky_top = Color(0.28, 0.68, 0.95)
		palette.sky_bottom = Color(0.78, 0.34, 0.08)
	else:
		palette.well_top = Color(0.03, 0.08, 0.16)
		palette.well_bottom = Color(0.09, 0.04, 0.012)
		palette.line_thin = Color(0.55, 0.36, 0.14, 0.55)
		palette.line_thick = Color(0.72, 0.46, 0.16, 0.72)
		palette.given = Color(0.78, 0.68, 0.5)
		palette.player = Color(0.72, 0.48, 0.16)
		palette.note = Color(0.62, 0.44, 0.2, 0.7)
		palette.selected = Color(0.7, 0.35, 0.08, 0.22)
		palette.same_digit = Color(0.65, 0.4, 0.1, 0.16)
		palette.peer = Color(0.35, 0.18, 0.06, 0.12)
		palette.neon = Color(0.62, 0.34, 0.08)
		palette.lock = Color(1.0, 0.86, 0.55)
		palette.sky_top = Color(0.16, 0.4, 0.62)
		palette.sky_bottom = Color(0.42, 0.16, 0.04)


func _fill_water(palette: Palette, vivid: bool) -> void:
	if vivid:
		palette.well_top = Color(0.0, 0.02, 0.05)
		palette.well_bottom = Color(0.0, 0.09, 0.18)
		palette.line_thin = Color(0.3, 0.78, 1.0, 0.82)
		palette.line_thick = Color(0.55, 0.94, 1.0, 1.0)
		palette.given = Color(0.88, 0.96, 1.0)
		palette.player = Color(0.28, 0.86, 1.0)
		palette.note = Color(0.4, 0.75, 0.95, 0.82)
		palette.selected = Color(0.1, 0.5, 0.95, 0.42)
		palette.same_digit = Color(0.2, 0.7, 1.0, 0.28)
		palette.peer = Color(0.05, 0.22, 0.4, 0.22)
		palette.neon = Color(0.2, 0.78, 1.0)
		palette.lock = Color(0.78, 0.96, 1.0)
		palette.sky_top = Color(0.0, 0.05, 0.12)
		palette.sky_bottom = Color(0.0, 0.12, 0.22)
	else:
		palette.well_top = Color(0.0, 0.012, 0.028)
		palette.well_bottom = Color(0.0, 0.03, 0.06)
		palette.line_thin = Color(0.12, 0.32, 0.42, 0.55)
		palette.line_thick = Color(0.16, 0.42, 0.55, 0.7)
		palette.given = Color(0.62, 0.74, 0.8)
		palette.player = Color(0.18, 0.48, 0.62)
		palette.note = Color(0.2, 0.4, 0.52, 0.7)
		palette.selected = Color(0.08, 0.28, 0.42, 0.24)
		palette.same_digit = Color(0.1, 0.35, 0.5, 0.16)
		palette.peer = Color(0.04, 0.14, 0.22, 0.12)
		palette.neon = Color(0.08, 0.35, 0.5)
		palette.lock = Color(0.6, 0.85, 0.95)
		palette.sky_top = Color(0.0, 0.02, 0.05)
		palette.sky_bottom = Color(0.0, 0.04, 0.08)


func _fill_night(palette: Palette, vivid: bool) -> void:
	if vivid:
		palette.well_top = Color(0.012, 0.002, 0.02)
		palette.well_bottom = Color(0.045, 0.008, 0.06)
		palette.line_thin = Color(0.82, 0.4, 1.0, 0.78)
		palette.line_thick = Color(1.0, 0.62, 0.98, 1.0)
		palette.given = Color(0.94, 0.88, 1.0)
		palette.player = Color(1.0, 0.58, 0.98)
		palette.note = Color(0.74, 0.5, 0.92, 0.82)
		palette.selected = Color(0.72, 0.22, 1.0, 0.4)
		palette.same_digit = Color(0.85, 0.35, 1.0, 0.28)
		palette.peer = Color(0.5, 0.16, 0.7, 0.22)
		palette.neon = Color(0.96, 0.5, 1.0)
		palette.lock = Color(1.0, 0.78, 1.0)
		palette.sky_top = Color(0.02, 0.0, 0.04)
		palette.sky_bottom = Color(0.06, 0.0, 0.09)
	else:
		palette.well_top = Color(0.008, 0.004, 0.012)
		palette.well_bottom = Color(0.016, 0.012, 0.02)
		palette.line_thin = Color(0.34, 0.3, 0.38, 0.5)
		palette.line_thick = Color(0.46, 0.4, 0.52, 0.68)
		palette.given = Color(0.68, 0.66, 0.72)
		palette.player = Color(0.52, 0.44, 0.6)
		palette.note = Color(0.4, 0.36, 0.46, 0.62)
		palette.selected = Color(0.26, 0.18, 0.32, 0.26)
		palette.same_digit = Color(0.24, 0.18, 0.3, 0.16)
		palette.peer = Color(0.16, 0.12, 0.2, 0.12)
		palette.neon = Color(0.36, 0.26, 0.44)
		palette.lock = Color(0.7, 0.55, 0.78)
		palette.sky_top = Color(0.01, 0.0, 0.02)
		palette.sky_bottom = Color(0.02, 0.0, 0.03)


func _fill_forest(palette: Palette, vivid: bool) -> void:
	if vivid:
		palette.well_top = Color(0.01, 0.04, 0.02)
		palette.well_bottom = Color(0.02, 0.08, 0.03)
		palette.line_thin = Color(0.42, 0.92, 0.38, 0.82)
		palette.line_thick = Color(0.72, 1.0, 0.42, 1.0)
		palette.given = Color(0.9, 0.98, 0.82)
		palette.player = Color(0.55, 0.95, 0.32)
		palette.note = Color(0.5, 0.78, 0.35, 0.82)
		palette.selected = Color(0.28, 0.72, 0.18, 0.4)
		palette.same_digit = Color(0.45, 0.85, 0.22, 0.28)
		palette.peer = Color(0.08, 0.28, 0.08, 0.22)
		palette.neon = Color(0.48, 0.95, 0.28)
		palette.lock = Color(0.86, 1.0, 0.55)
		palette.sky_top = Color(0.02, 0.08, 0.03)
		palette.sky_bottom = Color(0.04, 0.14, 0.04)
	else:
		palette.well_top = Color(0.008, 0.02, 0.01)
		palette.well_bottom = Color(0.012, 0.035, 0.016)
		palette.line_thin = Color(0.22, 0.42, 0.18, 0.55)
		palette.line_thick = Color(0.3, 0.55, 0.22, 0.7)
		palette.given = Color(0.62, 0.72, 0.52)
		palette.player = Color(0.32, 0.52, 0.22)
		palette.note = Color(0.28, 0.42, 0.2, 0.7)
		palette.selected = Color(0.16, 0.35, 0.12, 0.24)
		palette.same_digit = Color(0.2, 0.4, 0.14, 0.16)
		palette.peer = Color(0.06, 0.16, 0.06, 0.12)
		palette.neon = Color(0.22, 0.42, 0.16)
		palette.lock = Color(0.62, 0.82, 0.4)
		palette.sky_top = Color(0.01, 0.04, 0.016)
		palette.sky_bottom = Color(0.02, 0.06, 0.02)


func _fill_ember(palette: Palette, vivid: bool) -> void:
	if vivid:
		palette.well_top = Color(0.04, 0.01, 0.01)
		palette.well_bottom = Color(0.12, 0.02, 0.0)
		palette.line_thin = Color(1.0, 0.38, 0.12, 0.86)
		palette.line_thick = Color(1.0, 0.62, 0.18, 1.0)
		palette.given = Color(1.0, 0.9, 0.78)
		palette.player = Color(1.0, 0.42, 0.12)
		palette.note = Color(0.95, 0.45, 0.22, 0.82)
		palette.selected = Color(1.0, 0.28, 0.06, 0.4)
		palette.same_digit = Color(1.0, 0.4, 0.1, 0.28)
		palette.peer = Color(0.42, 0.08, 0.02, 0.22)
		palette.neon = Color(1.0, 0.38, 0.08)
		palette.lock = Color(1.0, 0.78, 0.32)
		palette.sky_top = Color(0.08, 0.01, 0.01)
		palette.sky_bottom = Color(0.22, 0.04, 0.0)
	else:
		palette.well_top = Color(0.02, 0.006, 0.004)
		palette.well_bottom = Color(0.05, 0.012, 0.004)
		palette.line_thin = Color(0.55, 0.22, 0.1, 0.55)
		palette.line_thick = Color(0.7, 0.3, 0.12, 0.72)
		palette.given = Color(0.72, 0.52, 0.42)
		palette.player = Color(0.7, 0.28, 0.1)
		palette.note = Color(0.58, 0.26, 0.12, 0.7)
		palette.selected = Color(0.55, 0.16, 0.05, 0.22)
		palette.same_digit = Color(0.55, 0.2, 0.06, 0.16)
		palette.peer = Color(0.28, 0.06, 0.02, 0.12)
		palette.neon = Color(0.55, 0.18, 0.06)
		palette.lock = Color(0.9, 0.55, 0.22)
		palette.sky_top = Color(0.04, 0.008, 0.004)
		palette.sky_bottom = Color(0.1, 0.02, 0.0)


## Writes `digit` into the selected cell; 0 clears it, as does repeating a digit.
## In notes mode the digit is toggled as a pencil mark instead.
func write_digit(digit: int) -> void:
	if not _play_enabled or _locked or _selected < 0:
		return
	if has_algae(_selected):
		return
	if is_cyber_locked(_selected):
		_deny_cyber(_selected)
		return
	if digit < 0 or digit > grid_size:
		return
	if _givens[_selected] != 0:
		return
	if notes_mode:
		if not _would_note_change(digit):
			return
		_push_undo()
		_write_note(digit)
		return
	if digit != 0 and _values[_selected] != digit and _count_digit(digit) >= grid_size:
		return
	var value: int = 0 if _values[_selected] == digit else digit
	if _values[_selected] == value:
		return
	if value != 0 and aegis_ready and _placement_clashes(_selected, value):
		aegis_ready = false
		aegis_spent.emit()
		_pulse_cell(_selected)
		spawn_caption("AEGIS", _selected)
		_haptic(HAPTIC_CLEAR_MS, HAPTIC_CLEAR_AMP)
		return
	_push_undo()
	var stake: int = poison_stake(_selected)
	var completed_before: int = _completed_unit_mask()
	_values[_selected] = value
	if value != 0:
		last_place_index = _selected
		_erase_note_from_peers(_selected, value)
	_update_conflicts()
	if value != 0:
		_cue_move_audio(_selected, completed_before)
		_play_place_effect(_selected, completed_before)
		_award_unit_points(_selected, completed_before, stake)
	_finish_board_change()
	if value != 0 and magnet_enabled and not _locked:
		apply_magnet_chain()


## Fills one empty cell with its answer. Prefers a cell that already has only one legal digit.
func apply_hint() -> bool:
	if not _play_enabled or _locked or _solution.size() != cell_count:
		return false
	var index: int = _pick_hint_cell()
	if index < 0:
		return false
	_push_undo()
	_selected = index
	last_place_index = index
	var completed_before: int = _completed_unit_mask()
	_values[index] = _solution[index]
	_erase_note_from_peers(index, _values[index])
	_update_conflicts()
	_cue_move_audio(index, completed_before)
	_play_place_effect(index, completed_before)
	_finish_board_change()
	if magnet_enabled and not _locked:
		apply_magnet_chain()
	return true


func is_cleared() -> bool:
	return _is_solved()


## Dawn Band: pencil every legal candidate onto empty cells. Does not place digits.
func dawn_mark() -> void:
	if _locked or _solution.size() != cell_count:
		return
	var marked: int = 0
	for index in cell_count:
		if not _relic_target(index, false):
			continue
		var mask: int = _candidate_mask(index)
		if mask == 0:
			continue
		_notes[index] = mask
		marked += 1
	if marked <= 0:
		return
	spawn_caption("DAWN")
	_finish_board_change()


## Oracle Eye: note the true digit on the empties with the fewest choices.
func oracle_note(count: int) -> void:
	if _locked or _solution.size() != cell_count or count <= 0:
		return
	var marked: int = 0
	var last: int = -1
	_oracle.clear()
	while marked < count:
		var index: int = _spotlight_true_note(false)
		if index < 0:
			break
		last = index
		var flash := OracleFlash.new()
		flash.index = index
		flash.digit = _solution[index]
		flash.age = -float(marked) * ORACLE_STAGGER
		_oracle.append(flash)
		marked += 1
	if marked <= 0:
		return
	spawn_caption("ORACLE", last)
	_finish_board_change()


## Relay: fill one cell that has a single legal digit, or note the truth on the next best cell.
func apply_relay() -> bool:
	if not _play_enabled or _locked or _solution.size() != cell_count:
		return false
	var index: int = _find_single_candidate_cell()
	if index >= 0:
		_push_undo()
		var digit: int = _solution[index]
		var stake: int = poison_stake(index)
		var completed_before: int = _completed_unit_mask()
		_values[index] = digit
		last_place_index = index
		_erase_note_from_peers(index, digit)
		_update_conflicts()
		relay_filling = true
		_cue_move_audio(index, completed_before)
		_play_place_effect(index, completed_before)
		_award_unit_points(index, completed_before, stake)
		spawn_caption("RELAY", index)
		_finish_board_change()
		if magnet_enabled and not _locked:
			apply_magnet_chain()
		relay_filling = false
		return true
	var noted: int = _spotlight_true_note()
	if noted < 0:
		return false
	spawn_caption("RELAY", noted)
	_finish_board_change()
	return true


func seal_has_work(origin: int, kind: int) -> bool:
	if not _play_enabled or _locked or _solution.size() != cell_count:
		return false
	if origin < 0 or origin >= cell_count or kind < 0 or kind > 3:
		return false
	for index in _seal_cells(origin, kind):
		if _seal_can_fill(index):
			return true
	return false


## Fills the box, row, column, or plus around `origin` with the answer. One undo step.
func apply_seal(origin: int, kind: int) -> bool:
	if not _play_enabled or _locked or _solution.size() != cell_count:
		return false
	if origin < 0 or origin >= cell_count or kind < 0 or kind > 3:
		return false
	var targets: Array[int] = []
	for index in _seal_cells(origin, kind):
		if not _seal_can_fill(index):
			continue
		targets.append(index)
	if targets.is_empty():
		return false
	_push_undo()
	seal_filling = true
	for index in targets:
		var digit: int = _solution[index]
		var stake: int = poison_stake(index)
		var completed_before: int = _completed_unit_mask()
		_values[index] = digit
		last_place_index = index
		_erase_note_from_peers(index, digit)
		_update_conflicts()
		_cue_move_audio(index, completed_before)
		_play_place_effect(index, completed_before)
		_award_unit_points(index, completed_before, stake)
		if _is_solved():
			break
	var captions: Array[String] = ["BOX", "ROW", "COLUMN", "PLUS"]
	spawn_caption(captions[kind], origin)
	seal_filling = false
	_finish_board_change()
	if magnet_enabled and not _locked:
		apply_magnet_chain()
	return true


func _seal_can_fill(index: int) -> bool:
	if index < 0 or index >= cell_count:
		return false
	if _givens[index] != 0:
		return false
	if has_algae(index) or is_poison_active(index) or is_cyber_locked(index):
		return false
	if _solution[index] < 1 or _solution[index] > grid_size:
		return false
	return _values[index] != _solution[index]


@warning_ignore("integer_division")
func _seal_cells(origin: int, kind: int) -> Array[int]:
	var cells: Array[int] = []
	var row: int = origin / grid_size
	var column: int = origin % grid_size
	if kind == 0:
		var box_row: int = row / box_height
		var box_column: int = column / box_width
		for box_r in box_height:
			for box_c in box_width:
				cells.append((box_row * box_height + box_r) * grid_size + box_column * box_width + box_c)
		return cells
	if kind == 1:
		for step in grid_size:
			cells.append(row * grid_size + step)
		return cells
	if kind == 2:
		for step in grid_size:
			cells.append(step * grid_size + column)
		return cells
	for step in grid_size:
		cells.append(row * grid_size + step)
	for step in grid_size:
		if step == row:
			continue
		cells.append(step * grid_size + column)
	return cells


## Journey Magnet: last empty cell in a row or column fills itself.
func apply_magnet_chain() -> void:
	if not magnet_enabled or _magnet_busy or _locked or _solution.size() != cell_count:
		return
	_magnet_busy = true
	var steps: int = 0
	while steps < 20 and not _locked:
		var index: int = _find_magnet_cell()
		if index < 0:
			break
		var digit: int = _solution[index]
		var stake: int = poison_stake(index)
		var completed_before: int = _completed_unit_mask()
		_values[index] = digit
		last_place_index = index
		_erase_note_from_peers(index, digit)
		_update_conflicts()
		magnet_filling = true
		_cue_move_audio(index, completed_before)
		_play_place_effect(index, completed_before)
		_award_unit_points(index, completed_before, stake)
		magnet_filling = false
		steps += 1
		if _is_solved():
			_locked = true
			_selected = -1
			_finish_board_change()
			solved.emit()
			_magnet_busy = false
			return
	if steps > 0:
		_finish_board_change()
	_magnet_busy = false


func _find_magnet_cell() -> int:
	for row in grid_size:
		var empty_index: int = -1
		var empty_count: int = 0
		for column in grid_size:
			var index: int = row * grid_size + column
			if _values[index] != 0:
				continue
			empty_count += 1
			empty_index = index
		if empty_count == 1 and _magnet_cell_ready(empty_index):
			return empty_index
	for column in grid_size:
		var empty_index: int = -1
		var empty_count: int = 0
		for row in grid_size:
			var index: int = row * grid_size + column
			if _values[index] != 0:
				continue
			empty_count += 1
			empty_index = index
		if empty_count == 1 and _magnet_cell_ready(empty_index):
			return empty_index
	return -1


func _magnet_cell_ready(index: int) -> bool:
	if index < 0 or index >= cell_count:
		return false
	if _givens[index] != 0 or _values[index] != 0:
		return false
	if has_algae(index):
		return false
	if is_poison_active(index):
		return false
	if is_cyber_locked(index):
		return false
	if _solution[index] < 1 or _solution[index] > grid_size:
		return false
	return true


func _finish_board_change() -> void:
	_refresh_cyber_locks(true)
	_sync_poison_visuals()
	_sync_sand_cache_visuals(true)
	queue_redraw()
	_emit_progress()
	if _is_solved() and not _locked:
		_locked = true
		_selected = -1
		queue_redraw()
		solved.emit()


func _pick_hint_cell() -> int:
	var safe: int = _pick_hint_cell_filtered(true)
	if safe >= 0:
		return safe
	return _pick_hint_cell_filtered(false)


func _pick_hint_cell_filtered(skip_poison: bool) -> int:
	var best_index: int = -1
	var best_count: int = grid_size + 1
	for index in cell_count:
		if _givens[index] != 0 or _values[index] != 0:
			continue
		if has_algae(index):
			continue
		if skip_poison and is_poison_active(index):
			continue
		if is_cyber_locked(index):
			continue
		if _solution[index] < 1 or _solution[index] > grid_size:
			continue
		var count: int = _count_mask_bits(_candidate_mask(index))
		if count <= 0:
			count = grid_size
		if count < best_count:
			best_count = count
			best_index = index
			if count == 1:
				break
	return best_index


func _placement_clashes(index: int, digit: int) -> bool:
	if digit < 1 or digit > grid_size or index < 0 or index >= cell_count:
		return false
	for other in cell_count:
		if other == index:
			continue
		if _values[other] == digit and _is_peer_of(other, index):
			return true
	return false


func _relic_target(index: int, allow_covered: bool) -> bool:
	if index < 0 or index >= cell_count:
		return false
	if _givens[index] != 0 or _values[index] != 0:
		return false
	if has_algae(index) or is_poison_active(index) or is_cyber_locked(index):
		return false
	if not allow_covered and has_sand_cache(index):
		return false
	if _solution[index] < 1 or _solution[index] > grid_size:
		return false
	return true


func _find_single_candidate_cell() -> int:
	for index in cell_count:
		if not _relic_target(index, true):
			continue
		var mask: int = _candidate_mask(index)
		if _count_mask_bits(mask) != 1:
			continue
		if _lowest_digit(mask) == _solution[index]:
			return index
	return -1


## Pencils only the true digit. Skips a cell that already shows just that digit.
func _spotlight_true_note(pulse: bool = true) -> int:
	var best: int = -1
	var best_count: int = grid_size + 1
	for index in cell_count:
		if not _relic_target(index, false):
			continue
		var truth: int = 1 << (_solution[index] - 1)
		if _notes[index] == truth:
			continue
		var count: int = _count_mask_bits(_candidate_mask(index))
		if count <= 0:
			count = grid_size
		if count < best_count:
			best_count = count
			best = index
	if best < 0:
		return -1
	_notes[best] = 1 << (_solution[best] - 1)
	if pulse:
		_pulse_cell(best)
	return best


func _lowest_digit(mask: int) -> int:
	for digit in range(1, grid_size + 1):
		if mask & (1 << (digit - 1)) != 0:
			return digit
	return 0


func _pulse_cell(index: int) -> void:
	if index < 0 or index >= cell_count:
		return
	var pulse := LockPulse.new()
	pulse.index = index
	_locks.append(pulse)
	queue_redraw()


func _candidate_mask(index: int) -> int:
	var mask: int = _digit_mask()
	for other in cell_count:
		if other == index:
			continue
		var value: int = _values[other]
		if value == 0 or not _is_peer_of(other, index):
			continue
		mask &= ~(1 << (value - 1))
	return mask


func _count_mask_bits(mask: int) -> int:
	var count: int = 0
	var bits: int = mask
	while bits != 0:
		count += bits & 1
		bits >>= 1
	return count


## Steps back to the board as it was before the last move. One move can span many
## cells, since answering a cell also strips that candidate from its peers.
func undo() -> void:
	if not _play_enabled or _locked or _undo_stack.is_empty():
		return
	var snapshot: Snapshot = _undo_stack.pop_back()
	_values = snapshot.values
	_notes = snapshot.notes
	_selected = snapshot.selected
	_clear_effects()
	_update_conflicts()
	_refresh_cyber_locks(false)
	_sync_poison_visuals()
	_sync_sand_cache_visuals(false)
	queue_redraw()
	_emit_progress()
	undo_availability_changed.emit(not _undo_stack.is_empty())


func can_undo() -> bool:
	return _play_enabled and not _locked and not _undo_stack.is_empty()


func _push_undo() -> void:
	var snapshot := Snapshot.new()
	snapshot.values = _values.duplicate()
	snapshot.notes = _notes.duplicate()
	snapshot.selected = _selected
	_undo_stack.append(snapshot)
	if _undo_stack.size() > UNDO_LIMIT:
		_undo_stack.remove_at(0)
	undo_availability_changed.emit(true)


## Guards against recording an undo step for a tap that would change nothing.
func _would_note_change(digit: int) -> bool:
	if digit != 0:
		return true
	return _notes[_selected] != 0 or _values[_selected] != 0


## A cell shows either an answer or its pencil marks, so noting clears the answer.
## The marks themselves survive underneath an answer and reappear once it is erased.
func _write_note(digit: int) -> void:
	if _values[_selected] != 0:
		_values[_selected] = 0
		_update_conflicts()
	if digit == 0:
		_notes[_selected] = 0
	else:
		_notes[_selected] ^= 1 << (digit - 1)
	_refresh_cyber_locks(false)
	_sync_poison_visuals()
	_sync_sand_cache_visuals(false)
	queue_redraw()
	_emit_progress()


## Answering a cell retires that candidate from every cell that shares a unit.
func _erase_note_from_peers(index: int, digit: int) -> void:
	var bit: int = 1 << (digit - 1)
	for other in cell_count:
		if other != index and _is_peer_of(other, index):
			_notes[other] &= ~bit


func _gui_input(event: InputEvent) -> void:
	if not _play_enabled or _locked:
		return
	# Phones send a screen-touch and an emulated mouse click. The mouse event is
	# already in this control's space, same as the number pad.
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			_select_cell_at(get_local_mouse_position())
			accept_event()


func _build_hit_cells() -> void:
	_hit_cells.clear()
	for index in cell_count:
		var hit := Control.new()
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.focus_mode = Control.FOCUS_NONE
		hit.gui_input.connect(_on_hit_cell_gui_input.bind(index))
		add_child(hit)
		_hit_cells.append(hit)
	_layout_hit_cells()


func _rebuild_hit_cells() -> void:
	for hit in _hit_cells:
		remove_child(hit)
		hit.free()
	_hit_cells.clear()
	_build_hit_cells()


func _layout_hit_cells() -> void:
	if _hit_cells.size() != cell_count:
		return
	var grid := _get_grid_rect()
	if grid.size.x <= 1.0:
		return
	var cell_size: float = grid.size.x / float(grid_size)
	for index in cell_count:
		var hit: Control = _hit_cells[index]
		hit.position = _get_cell_position(grid, cell_size, index)
		hit.size = Vector2(cell_size, cell_size)
	_layout_algae()
	_layout_poison()
	_layout_cyber_locks()
	_layout_sand_caches()


func has_algae(index: int) -> bool:
	return _algae.has(index) and is_instance_valid(_algae[index] as Node)


func algae_indices() -> PackedInt32Array:
	var packed := PackedInt32Array()
	for key in _algae.keys():
		var index: int = int(key)
		if has_algae(index):
			packed.append(index)
	packed.sort()
	return packed


func clear_algae() -> void:
	for key in _algae.keys():
		var patch: Node = _algae[key] as Node
		if is_instance_valid(patch):
			if patch.is_connected(&"cleaned", _on_algae_cleaned):
				patch.disconnect(&"cleaned", _on_algae_cleaned)
			if patch.is_connected(&"tapped", _on_algae_tapped):
				patch.disconnect(&"tapped", _on_algae_tapped)
			if patch.is_connected(&"splashed", _on_algae_splashed):
				patch.disconnect(&"splashed", _on_algae_splashed)
			patch.queue_free()
	_algae.clear()
	for child in get_children():
		if child is CPUParticles2D and String(child.name).begins_with("AlgaeBurst"):
			child.queue_free()


func seed_algae(count: int = ALGAE_COVER) -> void:
	clear_algae()
	if count <= 0 or cell_count <= 0:
		return
	var empties: Array[int] = []
	for index in cell_count:
		if _givens[index] != 0 or _values[index] != 0:
			continue
		if _solution.size() == cell_count and (_solution[index] < 1 or _solution[index] > grid_size):
			continue
		empties.append(index)
	empties.shuffle()
	var take: int = mini(count, empties.size())
	for slot in take:
		_place_algae(empties[slot])
	_layout_algae()


func _restore_algae(indices: Variant) -> void:
	clear_algae()
	var packed := PackedInt32Array()
	if indices is PackedInt32Array:
		packed = indices
	for index in packed:
		if index < 0 or index >= cell_count:
			continue
		if _givens[index] != 0 or _values[index] != 0:
			continue
		_place_algae(index)
	_layout_algae()


func _place_algae(index: int) -> void:
	if has_algae(index):
		return
	var patch: TextureRect = AlgaePatchScript.new() as TextureRect
	patch.set("cell_index", index)
	patch.z_index = 24
	patch.show_behind_parent = false
	patch.connect(&"cleaned", _on_algae_cleaned)
	patch.connect(&"tapped", _on_algae_tapped)
	patch.connect(&"splashed", _on_algae_splashed)
	add_child(patch)
	_algae[index] = patch


func _layout_algae() -> void:
	var grid := _get_grid_rect()
	if grid.size.x <= 1.0:
		return
	var cell_size: float = grid.size.x / float(grid_size)
	for key in _algae.keys():
		var index: int = int(key)
		var patch: TextureRect = _algae[key] as TextureRect
		if not is_instance_valid(patch):
			continue
		patch.position = _get_cell_position(grid, cell_size, index)
		patch.size = Vector2(cell_size, cell_size)


func _on_algae_tapped(index: int) -> void:
	algae_tapped.emit(index)


func _on_algae_splashed(index: int) -> void:
	algae_splashed.emit(index)


func _on_algae_cleaned(index: int) -> void:
	_algae.erase(index)
	_haptic(HAPTIC_PLACE_MS, HAPTIC_PLACE_AMP)
	algae_cleaned.emit(index)
	if _play_enabled and not _locked and index >= 0 and index < cell_count:
		_selected = index
	queue_redraw()
	if magnet_enabled and not _locked:
		apply_magnet_chain()


func has_poison(index: int) -> bool:
	return _poison.has(index) and is_instance_valid(_poison[index] as Node)


func is_poison_active(index: int) -> bool:
	if not has_poison(index):
		return false
	if index < 0 or index >= cell_count:
		return false
	if _solution.size() == cell_count and _values[index] == _solution[index]:
		return false
	return true


func poison_stake(index: int) -> int:
	return 2 if is_poison_active(index) else 1


func poison_cleared_count() -> int:
	var cleared: int = 0
	for key in _poison.keys():
		var index: int = int(key)
		if has_poison(index) and not is_poison_active(index):
			cleared += 1
	return cleared


func set_poison_bounty(amount: int) -> void:
	_poison_bounty = maxi(0, amount)
	for key in _poison.keys():
		var vine: Node = _poison[key] as Node
		if is_instance_valid(vine):
			vine.set("bounty", _poison_bounty)
			if vine is CanvasItem:
				(vine as CanvasItem).queue_redraw()


func poison_indices() -> PackedInt32Array:
	var packed := PackedInt32Array()
	for key in _poison.keys():
		var index: int = int(key)
		if has_poison(index):
			packed.append(index)
	packed.sort()
	return packed


func clear_poison() -> void:
	for key in _poison.keys():
		var vine: Node = _poison[key] as Node
		if is_instance_valid(vine):
			vine.queue_free()
	_poison.clear()
	_clear_poison_flash()


func seed_poison(count: int = -1) -> void:
	clear_poison()
	if cell_count <= 0:
		return
	var take: int = count
	if take < 0:
		take = randi_range(POISON_MIN, POISON_MAX)
	var empties: Array[int] = []
	for index in cell_count:
		if not _can_mark_poison(index):
			continue
		empties.append(index)
	empties.shuffle()
	take = mini(maxi(0, take), empties.size())
	for slot in take:
		_place_poison(empties[slot])
	_layout_poison()
	_sync_poison_visuals()


func _can_mark_poison(index: int) -> bool:
	if index < 0 or index >= cell_count:
		return false
	if _givens[index] != 0 or _values[index] != 0:
		return false
	if has_algae(index) or has_poison(index) or has_cyber(index) or has_sand_cache(index):
		return false
	if _solution.size() == cell_count and (_solution[index] < 1 or _solution[index] > grid_size):
		return false
	return true


func _restore_poison(indices: Variant) -> void:
	clear_poison()
	var packed := PackedInt32Array()
	if indices is PackedInt32Array:
		packed = indices
	for index in packed:
		if index < 0 or index >= cell_count:
			continue
		if _givens[index] != 0:
			continue
		_place_poison(index)
	_layout_poison()
	_sync_poison_visuals()


func _place_poison(index: int) -> void:
	if has_poison(index):
		return
	var vine: Control = PoisonVineScript.new() as Control
	vine.set("cell_index", index)
	vine.set("bounty", _poison_bounty)
	vine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vine.z_index = 8
	vine.show_behind_parent = false
	add_child(vine)
	_poison[index] = vine


func _layout_poison() -> void:
	var grid := _get_grid_rect()
	if grid.size.x <= 1.0:
		return
	var cell_size: float = grid.size.x / float(grid_size)
	for key in _poison.keys():
		var index: int = int(key)
		var vine: Control = _poison[key] as Control
		if not is_instance_valid(vine):
			continue
		vine.position = _get_cell_position(grid, cell_size, index)
		vine.size = Vector2(cell_size, cell_size)


func _sync_poison_visuals() -> void:
	for key in _poison.keys():
		var index: int = int(key)
		var vine: Node = _poison[key] as Node
		if not is_instance_valid(vine):
			continue
		vine.call("set_resolved", not is_poison_active(index))


func flash_poison_miss() -> void:
	_ensure_poison_flash()
	if _poison_flash_tween != null and is_instance_valid(_poison_flash_tween):
		_poison_flash_tween.kill()
	_poison_flash.visible = true
	_poison_flash.color = Color(0.18, 0.92, 0.32, 0.48)
	_poison_flash_tween = create_tween()
	_poison_flash_tween.tween_property(_poison_flash, "color:a", 0.0, POISON_FLASH_LIFE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_haptic(HAPTIC_CLEAR_MS, HAPTIC_CLEAR_AMP)


func _ensure_poison_flash() -> void:
	if is_instance_valid(_poison_flash):
		return
	var flash := ColorRect.new()
	flash.name = "PoisonFlash"
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0.18, 0.92, 0.32, 0.0)
	flash.z_index = 40
	add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_poison_flash = flash


func _clear_poison_flash() -> void:
	if _poison_flash_tween != null and is_instance_valid(_poison_flash_tween):
		_poison_flash_tween.kill()
		_poison_flash_tween = null
	if is_instance_valid(_poison_flash):
		_poison_flash.color.a = 0.0


func has_cyber(index: int) -> bool:
	return _cyber.has(index) and is_instance_valid(_cyber[index] as Node)


func is_cyber_locked(index: int) -> bool:
	if not has_cyber(index):
		return false
	var gate: Node = _cyber[index] as Node
	return not bool(gate.get("open"))


func cyber_indices() -> PackedInt32Array:
	var packed := PackedInt32Array()
	for key in _cyber.keys():
		var index: int = int(key)
		if has_cyber(index):
			packed.append(index)
	packed.sort()
	return packed


func clear_cyber_locks() -> void:
	for key in _cyber.keys():
		var gate: Node = _cyber[key] as Node
		if is_instance_valid(gate):
			gate.queue_free()
	_cyber.clear()


func seed_cyber_locks(count: int = -1) -> void:
	clear_cyber_locks()
	if cell_count <= 0 or grid_size < CLASSIC_GRID:
		return
	var take: int = count
	if take < 0:
		var counts: Array[int] = [CYBER_LOCK_MIN, 4, CYBER_LOCK_MAX]
		take = counts[randi() % counts.size()]
	take = clampi(take, 0, CYBER_LOCK_MAX)
	if take <= 0:
		return
	var picked: Array[int] = _pick_cyber_cells(take)
	for index in picked:
		_place_cyber(index)
	_layout_cyber_locks()
	_refresh_cyber_locks(false)


func _restore_cyber_locks(indices: Variant) -> void:
	clear_cyber_locks()
	var packed := PackedInt32Array()
	if indices is PackedInt32Array:
		packed = indices
	for index in packed:
		if index < 0 or index >= cell_count:
			continue
		if _givens[index] != 0:
			continue
		_place_cyber(index)
	_layout_cyber_locks()
	_refresh_cyber_locks(false)


func _pick_cyber_cells(take: int) -> Array[int]:
	var candidates: Array[int] = []
	for index in cell_count:
		if _can_mark_cyber(index):
			candidates.append(index)
	var best: Array[int] = []
	for _attempt in CYBER_LOCK_TRIES:
		candidates.shuffle()
		var picked: Array[int] = []
		for index in candidates:
			if picked.size() >= take:
				break
			var trial: Array[int] = []
			trial.append_array(picked)
			trial.append(index)
			if _cyber_set_solvable(trial):
				picked.append(index)
		if picked.size() > best.size():
			best = picked
		if best.size() >= take:
			break
	return best


func _can_mark_cyber(index: int) -> bool:
	if index < 0 or index >= cell_count:
		return false
	if _givens[index] != 0 or _values[index] != 0:
		return false
	if has_algae(index) or has_poison(index) or has_cyber(index) or has_sand_cache(index):
		return false
	if _solution.size() == cell_count and (_solution[index] < 1 or _solution[index] > grid_size):
		return false
	if _cyber_line_ready(index):
		return false
	return true


func _cyber_set_solvable(picked: Array[int]) -> bool:
	var remaining: Array[int] = []
	remaining.append_array(picked)
	while not remaining.is_empty():
		var found: int = -1
		for index in remaining:
			if _cyber_has_free_line(index, remaining):
				found = index
				break
		if found < 0:
			return false
		remaining.erase(found)
	return true


func _cyber_has_free_line(index: int, remaining: Array[int]) -> bool:
	var row_blocked: bool = false
	var col_blocked: bool = false
	var row: int = _row_of(index)
	var column: int = _column_of(index)
	for other in remaining:
		if other == index:
			continue
		if _row_of(other) == row:
			row_blocked = true
		if _column_of(other) == column:
			col_blocked = true
		if row_blocked and col_blocked:
			return false
	return not row_blocked or not col_blocked


func _place_cyber(index: int) -> void:
	if has_cyber(index):
		return
	var gate: Control = CyberLockScript.new() as Control
	gate.set("cell_index", index)
	gate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gate.z_index = 10
	gate.show_behind_parent = false
	add_child(gate)
	_cyber[index] = gate


func _layout_cyber_locks() -> void:
	var grid := _get_grid_rect()
	if grid.size.x <= 1.0:
		return
	var cell_size: float = grid.size.x / float(grid_size)
	for key in _cyber.keys():
		var index: int = int(key)
		var gate: Control = _cyber[key] as Control
		if not is_instance_valid(gate):
			continue
		gate.position = _get_cell_position(grid, cell_size, index)
		gate.size = Vector2(cell_size, cell_size)


func _refresh_cyber_locks(announce: bool) -> void:
	var opened: int = _sync_cyber_locks(announce)
	if announce and opened > 0:
		_haptic(HAPTIC_CLEAR_MS, HAPTIC_CLEAR_AMP)
	if _selected >= 0 and is_cyber_locked(_selected):
		_selected = -1


func _sync_cyber_locks(announce: bool = false) -> int:
	var opened: int = 0
	for key in _cyber.keys():
		var index: int = int(key)
		var gate: Node = _cyber[key] as Node
		if not is_instance_valid(gate):
			continue
		var should_open: bool = _cyber_line_ready(index)
		var was_open: bool = bool(gate.get("open"))
		gate.call("set_open", should_open)
		if should_open and not was_open:
			opened += 1
			cyber_unlocked.emit(index)
			if announce:
				spawn_caption("UNLOCK", index)
	return opened


## A lock opens when every other cell in its row, or every other cell in its column, matches the solution.
func _cyber_line_ready(index: int) -> bool:
	return _cyber_unit_ready(index, true) or _cyber_unit_ready(index, false)


func _cyber_unit_ready(index: int, use_row: bool) -> bool:
	if index < 0 or index >= cell_count or _solution.size() != cell_count:
		return false
	var row: int = _row_of(index)
	var column: int = _column_of(index)
	for slot in grid_size:
		var other: int
		if use_row:
			other = row * grid_size + slot
		else:
			other = slot * grid_size + column
		if other == index:
			continue
		if not _cell_matches_solution(other):
			return false
	return true


func _cell_matches_solution(index: int) -> bool:
	if index < 0 or index >= cell_count or _solution.size() != cell_count:
		return false
	return _values[index] == _solution[index]


func _deny_cyber(index: int) -> void:
	if not has_cyber(index):
		return
	var gate: Node = _cyber[index] as Node
	if is_instance_valid(gate):
		gate.call("nudge_deny")
	_haptic(HAPTIC_PLACE_MS, HAPTIC_PLACE_AMP)


func has_sand_cache(index: int) -> bool:
	return _sand_caches.has(index) and is_instance_valid(_sand_caches[index] as Node)


func sand_cache_indices() -> PackedInt32Array:
	var packed := PackedInt32Array()
	for key in _sand_caches.keys():
		var index: int = int(key)
		if has_sand_cache(index):
			packed.append(index)
	packed.sort()
	return packed


func sand_caches_cleared_count() -> int:
	var cleared: int = 0
	for key in _sand_caches.keys():
		var index: int = int(key)
		if has_sand_cache(index) and _cell_matches_solution(index):
			cleared += 1
	return cleared


func set_sand_bounty(amount: int) -> void:
	_sand_bounty = maxi(0, amount)
	for key in _sand_caches.keys():
		var cache: Node = _sand_caches[key] as Node
		if is_instance_valid(cache):
			cache.set("bounty", _sand_bounty)
			if cache is CanvasItem:
				(cache as CanvasItem).queue_redraw()


func clear_sand_caches() -> void:
	for key in _sand_caches.keys():
		var cache: Node = _sand_caches[key] as Node
		if is_instance_valid(cache):
			cache.queue_free()
	_sand_caches.clear()


func seed_sand_caches(count: int = -1) -> void:
	clear_sand_caches()
	if cell_count <= 0:
		return
	var take: int = randi_range(SAND_CACHE_MIN, SAND_CACHE_MAX) if count < 0 else count
	var empties: Array[int] = []
	for index in cell_count:
		if _can_mark_sand_cache(index):
			empties.append(index)
	empties.shuffle()
	take = mini(maxi(0, take), empties.size())
	for slot in take:
		_place_sand_cache(empties[slot])
	_layout_sand_caches()
	_sync_sand_cache_visuals(false)


func _can_mark_sand_cache(index: int) -> bool:
	if index < 0 or index >= cell_count:
		return false
	if _givens[index] != 0 or _values[index] != 0:
		return false
	if has_algae(index) or has_poison(index) or has_cyber(index) or has_sand_cache(index):
		return false
	if _solution.size() == cell_count and (_solution[index] < 1 or _solution[index] > grid_size):
		return false
	return true


func _restore_sand_caches(indices: Variant) -> void:
	clear_sand_caches()
	var packed := PackedInt32Array()
	if indices is PackedInt32Array:
		packed = indices
	for index in packed:
		if index < 0 or index >= cell_count or _givens[index] != 0:
			continue
		_place_sand_cache(index)
	_layout_sand_caches()
	_sync_sand_cache_visuals(false)


func _place_sand_cache(index: int) -> void:
	if has_sand_cache(index):
		return
	var cache: Control = SandCacheScript.new() as Control
	cache.set("cell_index", index)
	cache.set("bounty", _sand_bounty)
	cache.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cache.z_index = 7
	cache.show_behind_parent = false
	add_child(cache)
	_sand_caches[index] = cache


func _layout_sand_caches() -> void:
	var grid := _get_grid_rect()
	if grid.size.x <= 1.0:
		return
	var cell_size: float = grid.size.x / float(grid_size)
	for key in _sand_caches.keys():
		var index: int = int(key)
		var cache: Control = _sand_caches[key] as Control
		if not is_instance_valid(cache):
			continue
		cache.position = _get_cell_position(grid, cell_size, index)
		cache.size = Vector2(cell_size, cell_size)


func _sync_sand_cache_visuals(announce: bool) -> void:
	for key in _sand_caches.keys():
		var index: int = int(key)
		var cache: Node = _sand_caches[key] as Node
		if not is_instance_valid(cache):
			continue
		var resolved: bool = _cell_matches_solution(index)
		var was_resolved: bool = bool(cache.get("resolved"))
		cache.call("set_resolved", resolved, announce)
		if announce and resolved and not was_resolved:
			sand_cache_solved.emit(index)
			spawn_caption("TREASURE", index)


func set_ember_pressure(seconds_to_overheat: float, reset_heat: bool = true) -> void:
	_ember_active = seconds_to_overheat > 0.0
	_ember_rate = 1.0 / maxf(seconds_to_overheat, 1.0) if _ember_active else 0.0
	if reset_heat:
		ember_heat = 0.0
	_ember_flash = 0.0
	queue_redraw()


func clear_ember_pressure() -> void:
	_ember_active = false
	_ember_rate = 0.0
	ember_heat = 0.0
	_ember_flash = 0.0
	queue_redraw()


## Unfinished world marks use a high draw order, so they would sit on the results screen.
func conceal_level_mechanics() -> void:
	clear_algae()
	clear_poison()
	clear_cyber_locks()
	clear_sand_caches()
	clear_ember_pressure()


func ember_active() -> bool:
	return _ember_active


func apply_score_penalty(amount: int) -> int:
	var lost: int = mini(maxi(0, amount), score)
	if lost <= 0:
		return 0
	score -= lost
	score_changed.emit(score, _streak)
	return lost


func _advance_ember_heat(delta: float) -> void:
	if _ember_flash > 0.0:
		_ember_flash = maxf(0.0, _ember_flash - delta * 2.5)
	if not _ember_active or not _play_enabled or _locked or _ember_rate <= 0.0:
		return
	ember_heat = minf(1.0, ember_heat + delta * _ember_rate)
	if ember_heat < 1.0:
		return
	ember_heat = EMBER_RESET_HEAT
	_ember_flash = 1.0
	_haptic(HAPTIC_CLEAR_MS, HAPTIC_CLEAR_AMP)
	ember_overheated.emit()


func _cool_ember(amount: float) -> void:
	if not _ember_active or amount <= 0.0:
		return
	ember_heat = maxf(0.0, ember_heat - amount)


func _on_hit_cell_gui_input(event: InputEvent, index: int) -> void:
	if not _play_enabled or _locked:
		return
	var tapped: bool = false
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		tapped = button.pressed and button.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	if not tapped:
		return
	if seal_aim >= 0:
		seal_target.emit(index)
		accept_event()
		return
	if has_algae(index):
		return
	if is_cyber_locked(index):
		_deny_cyber(index)
		accept_event()
		return
	_selected = index
	queue_redraw()
	accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _play_enabled or not is_visible_in_tree():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var keycode: int = key.keycode
	if OS.is_debug_build() and _try_debug_key(keycode):
		get_viewport().set_input_as_handled()
		return
	if _locked:
		return
	if keycode == KEY_Z and key.ctrl_pressed:
		undo()
		get_viewport().set_input_as_handled()
		return
	if keycode >= KEY_1 and keycode <= KEY_9:
		write_digit(keycode - KEY_0)
	elif keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		write_digit(keycode - KEY_KP_0)
	elif keycode == KEY_0 or keycode == KEY_BACKSPACE or keycode == KEY_DELETE:
		write_digit(0)
	elif keycode == KEY_N:
		notes_mode = not notes_mode
	elif keycode == KEY_LEFT:
		_move_selection(-1, 0)
	elif keycode == KEY_RIGHT:
		_move_selection(1, 0)
	elif keycode == KEY_UP:
		_move_selection(0, -1)
	elif keycode == KEY_DOWN:
		_move_selection(0, 1)
	else:
		return
	get_viewport().set_input_as_handled()


## Editor / debug builds only. F2 row, F3 column, F4 box preview the burst. F5 fills the selected row for real.
func _try_debug_key(keycode: int) -> bool:
	match keycode:
		KEY_F2:
			_debug_preview_unit(0)
			return true
		KEY_F3:
			_debug_preview_unit(1)
			return true
		KEY_F4:
			_debug_preview_unit(2)
			return true
		KEY_F5:
			if not _locked:
				_debug_fill_unit(0)
			return true
		_:
			return false


func _debug_preview_unit(kind: int) -> void:
	var cells: PackedInt32Array = _debug_unit_cells(kind)
	if cells.is_empty():
		return
	var sweep := UnitSweep.new()
	sweep.cells = cells
	_sweeps.append(sweep)
	_spawn_line_drift(cells)
	queue_redraw()


func _debug_fill_unit(kind: int) -> void:
	if _solution.is_empty():
		_debug_preview_unit(kind)
		return
	var cells: PackedInt32Array = _debug_unit_cells(kind)
	var last_empty: int = -1
	for index in cells:
		if _givens[index] != 0:
			continue
		if _values[index] == 0 or _values[index] != _solution[index]:
			last_empty = index
	if last_empty < 0:
		_debug_preview_unit(kind)
		return
	for index in cells:
		if index == last_empty:
			continue
		if _givens[index] == 0:
			_values[index] = _solution[index]
	_update_conflicts()
	_selected = last_empty
	write_digit(_solution[last_empty])


func _debug_unit_cells(kind: int) -> PackedInt32Array:
	var index: int = _selected if _selected >= 0 else 40
	var cells := PackedInt32Array()
	match kind:
		0:
			var row: int = _row_of(index)
			for column in grid_size:
				cells.append(row * grid_size + column)
		1:
			var column: int = _column_of(index)
			for row in grid_size:
				cells.append(row * grid_size + column)
		_:
			@warning_ignore("integer_division")
			var box_row: int = (_row_of(index) / box_height) * box_height
			@warning_ignore("integer_division")
			var box_column: int = (_column_of(index) / box_width) * box_width
			for row in box_height:
				for column in box_width:
					cells.append((box_row + row) * grid_size + box_column + column)
	return cells


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	_draw_sparkles()
	var board := _get_board_rect()
	_draw_well(board)
	if _style == ArtStyle.DESERT:
		_draw_pyramids(board)
	elif _style == ArtStyle.FOREST:
		_draw_trees(board)
	elif _style == ArtStyle.EMBER:
		_draw_crags(board)
	_draw_world_flow()

	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(grid_size)
	var ink: float = grid.size.x / float(CLASSIC_GRID)
	var fx: float = cell_size if grid_size >= CLASSIC_GRID else ink
	for index in cell_count:
		var highlight: Color = _get_highlight(index)
		if highlight.a > 0.0:
			draw_rect(Rect2(_get_cell_position(grid, cell_size, index), Vector2(cell_size, cell_size)), highlight, true)
	_draw_effect_fills(grid, cell_size)
	_draw_digits(grid, cell_size, ink)
	_draw_grid_lines(grid, cell_size, fx)
	_draw_oracle(grid, cell_size, ink)
	_draw_effect_rings(grid, cell_size, fx)
	_draw_line_drifts()
	_draw_conflict_motes(grid, cell_size, fx)
	_draw_outer_glow(board)
	_draw_ember_heat(board, grid)
	_draw_score_total(board, grid)
	_draw_score_pops(fx)


func _draw_sparkles() -> void:
	var board := _get_board_rect()
	var center: Vector2 = board.get_center()
	var orbit: float = board.size.x * 0.545
	for index in _spark_positions.size():
		var angle: float = _spark_seeds[index] + _ambient_time * (0.12 + float(index % 4) * 0.025)
		var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * orbit
		if board.has_point(point) or not Rect2(Vector2.ZERO, size).has_point(point):
			continue
		var twinkle: float = 0.3 + 0.7 * absf(sin(_ambient_time * 1.5 + _spark_seeds[index]))
		var spark := _c_neon()
		spark.a = (0.18 + 0.6 * twinkle) * _glow_amount() * _style_strength()
		draw_circle(point, (1.2 + twinkle * 1.8) * _style_size(), spark)


func _draw_well(board: Rect2) -> void:
	var shadow := board.grow(6.0)
	shadow.position.y += 16.0
	var shadow_color := _c_neon()
	shadow_color.a = lerpf(0.1, 0.34, mood)
	draw_rect(shadow, shadow_color, true)
	var floor_color: Color = _c_well_bottom()
	var bands: int = 14
	var band_height: float = board.size.y / float(bands)
	for band in bands:
		var shade: float = float(band) / float(bands - 1)
		var top: float = board.position.y + band_height * float(band)
		var bottom: float = board.end.y if band == bands - 1 else top + band_height
		draw_rect(Rect2(board.position.x, top, board.size.x, bottom - top), _c_well_top().lerp(floor_color, shade), true)


## Bands sit outside the well. The well fill used to cover the glow completely.
func _draw_outer_glow(board: Rect2) -> void:
	var amount: float = _glow_amount()
	var neon := _c_neon()
	var reaches: Array[float] = [5.0, 12.0, 22.0, 34.0]
	var alphas: Array[float] = [0.55, 0.32, 0.16, 0.08]
	for band in reaches.size():
		var reach: float = reaches[band]
		var color := neon
		color.a = alphas[band] * amount
		var outer := board.grow(reach)
		draw_rect(Rect2(outer.position, Vector2(outer.size.x, reach)), color, true)
		draw_rect(Rect2(Vector2(outer.position.x, board.end.y), Vector2(outer.size.x, reach)), color, true)
		draw_rect(Rect2(outer.position.x, board.position.y, reach, board.size.y), color, true)
		draw_rect(Rect2(board.end.x, board.position.y, reach, board.size.y), color, true)


func _score_font() -> Font:
	if given_font != null:
		return given_font
	var fallback: Font = get_theme_default_font()
	if fallback != null:
		return fallback
	return ThemeDB.fallback_font


func _draw_score_total(board: Rect2, grid: Rect2) -> void:
	var font: Font = _score_font()
	var band_height: float = grid.position.y - board.position.y
	var font_size: int = maxi(14, int(band_height * (0.82 if loud_pops else 0.62)))
	var text: String = str(score)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline: float = (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var mid_y: float = (board.position.y + grid.position.y) * 0.5 + baseline
	var streak_gap: float = font_size * 0.85 if _streak >= 2 else 0.0
	var streak_text: String = "×%d" % _streak
	var streak_size: Vector2 = font.get_string_size(streak_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var total_width: float = text_size.x + streak_gap + (streak_size.x if _streak >= 2 else 0.0)
	var pos := Vector2(board.get_center().x - total_width * 0.5, mid_y)
	var color := _c_neon()
	color.a = (0.78 if loud_pops else 0.55) + 0.45 * _glow_amount()
	var shadow := Color(0.0, 0.0, 0.0, color.a * 0.55)
	draw_string(font, pos + Vector2(0.0, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
	if _streak >= 2:
		var streak_pos := Vector2(pos.x + text_size.x + streak_gap, mid_y)
		var streak_color := color.lerp(Color.WHITE, 0.35)
		draw_string(font, streak_pos + Vector2(0.0, 1.5), streak_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow)
		draw_string(font, streak_pos, streak_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, streak_color)


func _draw_ember_heat(board: Rect2, grid: Rect2) -> void:
	if not _ember_active:
		return
	var lip_height: float = board.end.y - grid.end.y
	var bar_height: float = minf(clampf(lip_height * 0.62, 16.0, 26.0), lip_height * 0.78)
	var bar := Rect2(
		Vector2(grid.position.x, grid.end.y + (lip_height - bar_height) * 0.55),
		Vector2(grid.size.x, bar_height)
	)
	var pulse: float = 0.5 + 0.5 * sin(_ambient_time * lerpf(3.0, 8.0, ember_heat))
	draw_rect(bar, Color(0.07, 0.012, 0.0, 0.94), true)
	var filled: float = bar.size.x * ember_heat
	if filled > 1.0:
		var body := Rect2(bar.position, Vector2(filled, bar.size.y))
		draw_rect(body, Color(0.62, 0.06, 0.0, 0.96), true)
		draw_rect(Rect2(body.position, Vector2(filled, bar.size.y * 0.62)), Color(1.0, 0.34, 0.04, 0.95), true)
		draw_rect(Rect2(body.position, Vector2(filled, bar.size.y * 0.28)), Color(1.0, 0.82, 0.28, 0.92), true)
		_draw_ember_tongues(bar, filled, bar_height)
	var edge := Color(1.0, 0.38, 0.05, 0.55 + pulse * 0.25)
	draw_rect(bar, edge, false, maxf(1.6, bar_height * 0.1))
	if ember_heat >= 0.72:
		var hot := edge
		hot.a = (ember_heat - 0.72) * (0.85 + pulse * 0.3)
		draw_rect(bar.grow(2.0 + pulse * 2.0), hot, false, 2.0)


func _draw_ember_tongues(bar: Rect2, filled: float, bar_height: float) -> void:
	var step: float = 18.0
	var x: float = bar.position.x + step * 0.45
	var index: int = 0
	var end_x: float = bar.position.x + filled - 3.0
	while x < end_x:
		var wave: float = sin(_ambient_time * (8.0 + float(index % 3) * 2.0) + float(index) * 1.7)
		var height: float = bar_height * (0.55 + 0.5 * (0.5 + 0.5 * wave)) * lerpf(0.7, 1.2, ember_heat)
		var width: float = step * (0.34 + 0.1 * sin(_ambient_time * 13.0 + float(index) * 0.8))
		var tip := Vector2(x + sin(_ambient_time * 10.0 + float(index)) * 2.4, bar.position.y - height)
		var outer := PackedVector2Array([
			tip,
			Vector2(x + width, bar.position.y + 2.0),
			Vector2(x - width, bar.position.y + 2.0),
		])
		var flame := Color(1.0, 0.42, 0.05, 0.92).lerp(Color(1.0, 0.9, 0.4, 0.95), 0.5 + 0.5 * wave)
		draw_colored_polygon(outer, flame)
		var core := PackedVector2Array([
			tip + Vector2(0.0, height * 0.42),
			Vector2(x + width * 0.32, bar.position.y + 1.0),
			Vector2(x - width * 0.32, bar.position.y + 1.0),
		])
		draw_colored_polygon(core, Color(1.0, 0.96, 0.72, 0.88))
		x += step
		index += 1


func _draw_score_pops(fx: float = -1.0) -> void:
	if _score_pops.is_empty():
		return
	var font: Font = _score_font()
	var grid := _get_grid_rect()
	if fx < 1.0:
		fx = grid.size.x / float(CLASSIC_GRID)
	var font_size: int = maxi(18, int(fx * (0.48 if loud_pops else 0.32)))
	for pop in _score_pops:
		var travel: float = clampf(pop.age / pop.life, 0.0, 1.0)
		var fade: float = 1.0 - travel * travel
		var lift: float = 1.0 - pow(1.0 - travel, 3.0)
		var pos: Vector2 = pop.origin + pop.drift * lift
		if pop.broken:
			pos.x += sin(pop.age * 38.0) * (8.0 * (1.0 - travel))
		var text: String
		if not pop.caption.is_empty():
			text = pop.caption
		elif pop.clock:
			text = "%+d" % pop.amount
		elif pop.broken:
			text = "×%d" % pop.streak
		elif pop.streak > 1:
			text = "+%d  ×%d" % [pop.amount, pop.streak]
		else:
			text = "+%d" % pop.amount
		var size_boost: int = mini(8, (pop.streak - 1) * 2)
		var pop_size: int = font_size + size_boost
		if not pop.caption.is_empty():
			pop_size = maxi(28, int(fx * (0.7 if loud_pops else 0.52)))
		elif pop.gold:
			pop_size = maxi(26, int(fx * (0.62 if loud_pops else 0.48)))
		elif pop.clock:
			pop_size = maxi(34, int(fx * (0.88 if loud_pops else 0.62)))
		elif pop.broken:
			pop_size = maxi(20, int(float(pop_size) * (1.15 - travel * 0.45)))
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size)
		var baseline: float = (font.get_ascent(pop_size) - font.get_descent(pop_size)) * 0.5
		var draw_at := Vector2(pos.x - text_size.x * 0.5, pos.y + baseline)
		var color: Color
		if not pop.caption.is_empty():
			color = _c_neon().lerp(Color.WHITE, 0.55)
			color.a = fade
		elif pop.gold:
			color = Color(1.0, 0.86, 0.38)
			color.a = fade
		elif pop.clock and pop.amount < 0:
			color = Color(1.0, 0.42, 0.38)
			color.a = fade
		elif pop.clock:
			color = Color(1.0, 0.88, 0.38)
			color.a = fade
		elif pop.broken:
			color = COLOR_CONFLICT_TEXT
			color.a = fade
		else:
			color = _c_neon().lerp(Color.WHITE, 0.35)
			color.a = fade
		var glow := color
		glow.a *= 0.55 if pop.clock or pop.gold or loud_pops or not pop.caption.is_empty() else 0.4
		var shadow := Color(0.0, 0.0, 0.0, 0.62 * fade)
		draw_string(font, draw_at + Vector2(0.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size, shadow)
		draw_string(font, draw_at + Vector2(-1.6, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size, glow)
		draw_string(font, draw_at + Vector2(1.6, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size, glow)
		draw_string(font, draw_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size, color)
		if pop.broken and not pop.clock:
			_draw_streak_break_shards(pop, pos, fade)
		elif pop.clock and pop.amount < 0:
			_draw_streak_break_shards(pop, pos, fade)


func _draw_streak_break_shards(pop: ScorePop, origin: Vector2, fade: float) -> void:
	var speck := COLOR_CONFLICT_TEXT
	speck.a = 0.75 * fade
	for shard in 6:
		var angle: float = float(shard) * TAU / 6.0 + pop.age * 2.4
		var dist: float = 10.0 + pop.age * 42.0
		draw_circle(origin + Vector2(cos(angle), sin(angle)) * dist, 2.2 - pop.age * 1.1, speck)


func _draw_oracle(grid: Rect2, cell_size: float, ink: float) -> void:
	if _oracle.is_empty():
		return
	var font: Font = entry_font if entry_font != null else _score_font()
	if font == null:
		return
	var note_size: int = maxi(10, int(minf(cell_size / float(maxi(box_width, box_height)), ink * 0.42) * 0.55))
	var cell := Vector2(cell_size, cell_size)
	for flash in _oracle:
		if flash.age < 0.0 or flash.digit < 1:
			continue
		var travel: float = clampf(flash.age / ORACLE_LIFE, 0.0, 1.0)
		var settle: float = travel * travel * (3.0 - 2.0 * travel)
		var origin: Vector2 = _get_cell_position(grid, cell_size, flash.index)
		var center: Vector2 = origin + cell * 0.5
		var wash := Color(0.62, 0.42, 1.0, (1.0 - travel) * 0.42)
		draw_rect(Rect2(origin, cell), wash, true)
		var ring := Color(0.86, 0.74, 1.0, (1.0 - clampf(travel / 0.75, 0.0, 1.0)) * 0.95)
		var radius: float = lerpf(cell_size * 0.12, cell_size * 0.46, clampf(travel / 0.7, 0.0, 1.0))
		draw_arc(center, radius, 0.0, TAU, 20, ring, maxf(1.6, ink * 0.04), true)
		var slot := Vector2i((flash.digit - 1) % box_width, int((flash.digit - 1) / box_width))
		var slot_center := origin + Vector2((float(slot.x) + 0.5) * cell_size / float(box_width), (float(slot.y) + 0.5) * cell_size / float(box_height))
		var at: Vector2 = center.lerp(slot_center, settle)
		var pop_size: int = int(round(lerpf(ink * 0.5, float(note_size), settle)))
		var text: String = str(flash.digit)
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size).x
		var baseline: float = (font.get_ascent(pop_size) - font.get_descent(pop_size)) * 0.5
		var fade: float = 1.0 - clampf((travel - 0.62) / 0.38, 0.0, 1.0)
		var ink_color := Color(1.0, 0.93, 0.62, fade)
		draw_string(font, at + Vector2(-text_width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pop_size, ink_color)


func _draw_digits(grid: Rect2, cell_size: float, ink: float) -> void:
	var fallback: Font = get_theme_default_font()
	if fallback == null:
		fallback = ThemeDB.fallback_font
	var clue_font: Font = given_font if given_font != null else fallback
	var typed_font: Font = entry_font if entry_font != null else fallback
	var grow: float = 1.0 + 0.18 * (1.0 - float(grid_size) / float(CLASSIC_GRID))
	var font_size: int = maxi(18, int(ink * 0.62 * grow))
	var clue_baseline: float = (clue_font.get_ascent(font_size) - clue_font.get_descent(font_size)) * 0.5
	var typed_baseline: float = (typed_font.get_ascent(font_size) - typed_font.get_descent(font_size)) * 0.5
	var note_slot: float = minf(cell_size / float(maxi(box_width, box_height)), ink * 0.42)
	var note_size: int = maxi(10, int(note_slot * 0.55))
	var note_baseline: float = (typed_font.get_ascent(note_size) - typed_font.get_descent(note_size)) * 0.5
	var note_step_x: float = cell_size / float(box_width)
	var note_step_y: float = cell_size / float(box_height)
	var glow_offset: float = ink * 0.018
	for index in cell_count:
		var value: int = _values[index]
		var origin: Vector2 = _get_cell_position(grid, cell_size, index)
		if value == 0:
			var marks: int = _notes[index]
			if marks == 0:
				continue
			for digit in range(1, grid_size + 1):
				if marks & (1 << (digit - 1)) == 0:
					continue
				var mark: String = str(digit)
				var mark_width: float = typed_font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1.0, note_size).x
				var slot := Vector2i((digit - 1) % box_width, int((digit - 1) / box_width))
				var slot_center := origin + Vector2((float(slot.x) + 0.5) * note_step_x, (float(slot.y) + 0.5) * note_step_y)
				draw_string(typed_font, slot_center + Vector2(-mark_width * 0.5, note_baseline), mark, HORIZONTAL_ALIGNMENT_LEFT, -1.0, note_size, _c_note())
			continue
		var is_clue: bool = _givens[index] != 0
		var font: Font = clue_font if is_clue else typed_font
		var baseline: float = clue_baseline if is_clue else typed_baseline
		var text: String = str(value)
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		var text_position := origin + Vector2(cell_size * 0.5 - text_width * 0.5, cell_size * 0.5 + baseline)
		var color: Color = _get_digit_color(index)
		var scale: float = _lock_scale(index)
		var shake: Vector2 = _conflict_shake(index, ink)
		var center := origin + Vector2(cell_size, cell_size) * 0.5
		var xform := Transform2D.IDENTITY.scaled(Vector2(scale, scale))
		xform.origin = center + shake - xform.basis_xform(center)
		draw_set_transform_matrix(xform)
		var glow := color
		glow.a *= 0.32
		draw_string(font, text_position + Vector2(-glow_offset, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, glow)
		draw_string(font, text_position + Vector2(glow_offset, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, glow)
		draw_string(font, text_position + Vector2(0.0, -glow_offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, glow)
		draw_string(font, text_position + Vector2(0.0, glow_offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, glow)
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_grid_lines(grid: Rect2, cell_size: float, fx: float) -> void:
	for line in range(grid_size + 1):
		var is_box_vertical: bool = line % box_width == 0
		var is_box_horizontal: bool = line % box_height == 0
		var offset: float = line * cell_size
		var vertical_width: float = (maxf(3.0, fx * 0.05) if is_box_vertical else maxf(1.4, fx * 0.02)) * lerpf(0.75, 1.0, mood)
		var horizontal_width: float = (maxf(3.0, fx * 0.05) if is_box_horizontal else maxf(1.4, fx * 0.02)) * lerpf(0.75, 1.0, mood)
		_draw_neon_line(grid.position + Vector2(offset, 0.0), grid.position + Vector2(offset, grid.size.y), _c_line_thick() if is_box_vertical else _c_line_thin(), vertical_width, is_box_vertical)
		_draw_neon_line(grid.position + Vector2(0.0, offset), grid.position + Vector2(grid.size.x, offset), _c_line_thick() if is_box_horizontal else _c_line_thin(), horizontal_width, is_box_horizontal)
	var joint: float = maxf(3.0, fx * 0.05)
	for row in range(0, grid_size + 1, box_height):
		for column in range(0, grid_size + 1, box_width):
			var point := grid.position + Vector2(float(column) * cell_size, float(row) * cell_size)
			var glow := _c_line_thick()
			glow.a = 0.4 * _glow_amount()
			draw_circle(point, joint * 1.6, glow)
			draw_circle(point, joint * 0.7, _c_line_thick())


func _draw_neon_line(from: Vector2, to: Vector2, color: Color, width: float, strong: bool) -> void:
	var glow: float = _glow_amount()
	var outer := color
	outer.a = (0.2 if strong else 0.1) * glow
	draw_line(from, to, outer, width * (6.0 if strong else 3.6), true)
	var mid := color
	mid.a = (0.45 if strong else 0.26) * glow
	draw_line(from, to, mid, width * (2.5 if strong else 1.8), true)
	draw_line(from, to, color, width, true)


func _draw_effect_fills(grid: Rect2, cell_size: float) -> void:
	var cell := Vector2(cell_size, cell_size)
	for pulse in _locks:
		var amount: float = 1.0 - clampf(pulse.age / LOCK_DURATION, 0.0, 1.0)
		var flash := _vivid.lock
		flash.a = amount * 0.78
		draw_rect(Rect2(_get_cell_position(grid, cell_size, pulse.index), cell), flash, true)
	for sweep in _sweeps:
		var head: float = _sweep_head(sweep.age)
		var strength: float = _sweep_strength(sweep.age)
		var count: int = sweep.cells.size()
		for slot in count:
			var lit: float = _sweep_cell_lit(slot, count, head)
			if lit <= 0.0:
				continue
			var light := _vivid.neon
			light.a = strength * (0.26 + 0.4 * lit)
			draw_rect(Rect2(_get_cell_position(grid, cell_size, sweep.cells[slot]), cell), light, true)
	if _ember_flash > 0.0:
		var flash := Color(1.0, 0.12, 0.015, 0.34 * _ember_flash)
		draw_rect(grid, flash, true)


func _draw_effect_rings(grid: Rect2, cell_size: float, fx: float) -> void:
	for pulse in _locks:
		var travel: float = clampf(pulse.age / LOCK_DURATION, 0.0, 1.0)
		var center: Vector2 = _get_cell_position(grid, cell_size, pulse.index) + Vector2(cell_size, cell_size) * 0.5
		var ring := _vivid.lock
		ring.a = (1.0 - travel) * 0.95
		var radius: float = lerpf(fx * 0.2, minf(cell_size * 0.48, fx * 1.45), travel)
		var ring_width: float = maxf(2.0, fx * 0.07 * (1.0 - travel))
		draw_arc(center, radius, 0.0, TAU, 48, ring, ring_width, true)
		var inner := _vivid.neon
		inner.a = (1.0 - travel) * 0.7
		draw_arc(center, radius * 0.72, 0.0, TAU, 40, inner, ring_width * 0.55, true)
	for sweep in _sweeps:
		_draw_sweep_streak(grid, cell_size, fx, sweep)


func _draw_sweep_streak(grid: Rect2, cell_size: float, fx: float, sweep: UnitSweep) -> void:
	if sweep.cells.is_empty():
		return
	var head: float = _sweep_head(sweep.age)
	var strength: float = _sweep_strength(sweep.age)
	if head <= 0.0 or strength <= 0.0:
		return
	var streak := _vivid.lock
	streak.a = strength * 0.8
	var first: int = sweep.cells[0]
	var last: int = sweep.cells[sweep.cells.size() - 1]
	var width: float = maxf(2.0, fx * 0.045)
	if _row_of(first) == _row_of(last):
		var y: float = _get_cell_position(grid, cell_size, first).y + cell_size * 0.5
		var from := Vector2(_get_cell_position(grid, cell_size, first).x, y)
		var to := Vector2(_get_cell_position(grid, cell_size, last).x + cell_size, y)
		_draw_fading_streak(from, from.lerp(to, head), streak, width)
	elif _column_of(first) == _column_of(last):
		var x: float = _get_cell_position(grid, cell_size, first).x + cell_size * 0.5
		var from := Vector2(x, _get_cell_position(grid, cell_size, first).y)
		var to := Vector2(x, _get_cell_position(grid, cell_size, last).y + cell_size)
		_draw_fading_streak(from, from.lerp(to, head), streak, width)
	else:
		var origin: Vector2 = _get_cell_position(grid, cell_size, first)
		streak.a = strength * head * 0.8
		draw_rect(Rect2(origin, Vector2(cell_size * float(box_width), cell_size * float(box_height))), streak, false, width)


## The streak's glow follows the same fade as its core, unlike the grid lines.
func _draw_fading_streak(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	if color.a <= 0.01 or from.distance_to(to) < 0.5:
		return
	var fade: float = color.a
	var outer := color
	outer.a = 0.28 * fade
	draw_line(from, to, outer, width * 5.5, true)
	var mid := color
	mid.a = 0.55 * fade
	draw_line(from, to, mid, width * 2.4, true)
	draw_line(from, to, color, width, true)


## How far the light has filled one cell. The last cell is fully lit once the head arrives.
func _sweep_cell_lit(slot: int, count: int, head: float) -> float:
	return clampf(head * float(count) - float(slot), 0.0, 1.0)


## 0 while the light is on its way, 1 once it has covered the whole unit.
func _sweep_head(age: float) -> float:
	var linear: float = clampf(age / SWEEP_TRAVEL_TIME, 0.0, 1.0)
	return linear * linear * (3.0 - 2.0 * linear)


## Holds at full brightness until the light arrives, then eases out.
func _sweep_strength(age: float) -> float:
	if age <= SWEEP_TRAVEL_TIME:
		return 1.0
	var linear: float = clampf((age - SWEEP_TRAVEL_TIME) / SWEEP_FADE_TIME, 0.0, 1.0)
	var fade: float = linear * linear * (3.0 - 2.0 * linear)
	return 1.0 - fade


func grid_global_rect() -> Rect2:
	var grid := _get_grid_rect()
	var xform := get_global_transform()
	return Rect2(xform * grid.position, grid.size * xform.get_scale())


func _get_board_rect() -> Rect2:
	var length: float = minf(size.x, size.y) * STAGE_SCALE
	return Rect2((size - Vector2(length, length)) * 0.5, Vector2(length, length))


## The 9x9 area, inset so highlights never spill into the paper's rounded corners.
func _get_grid_rect() -> Rect2:
	var board := _get_board_rect()
	var ratio: float = GRID_PADDING_RATIO
	if grid_size < CLASSIC_GRID:
		ratio += 0.07 * (1.0 - float(grid_size) / float(CLASSIC_GRID))
	var padding: float = board.size.x * ratio
	return Rect2(board.position + Vector2(padding, padding), board.size - Vector2(padding, padding) * 2.0)


func _get_cell_position(grid: Rect2, cell_size: float, index: int) -> Vector2:
	return grid.position + Vector2(_column_of(index) * cell_size, _row_of(index) * cell_size)


func _select_cell_at(position: Vector2) -> void:
	var grid := _get_grid_rect()
	if grid.size.x <= 1.0:
		return
	var cell_size: float = grid.size.x / float(grid_size)
	# Clamp onto the 9x9 even if the tap lands in the paper lip, so a slightly
	# transformed phone touch still selects a cell.
	var column: int = clampi(int(floor((position.x - grid.position.x) / cell_size)), 0, grid_size - 1)
	var row: int = clampi(int(floor((position.y - grid.position.y) / cell_size)), 0, grid_size - 1)
	var index: int = row * grid_size + column
	if has_algae(index):
		return
	if is_cyber_locked(index):
		_deny_cyber(index)
		return
	_selected = index
	queue_redraw()


func _move_selection(column_step: int, row_step: int) -> void:
	if _selected < 0:
		_selected = _first_selectable_cell()
		queue_redraw()
		return
	var column: int = _column_of(_selected)
	var row: int = _row_of(_selected)
	for _step in grid_size:
		column += column_step
		row += row_step
		if column < 0 or column >= grid_size or row < 0 or row >= grid_size:
			break
		var index: int = row * grid_size + column
		if has_algae(index) or is_cyber_locked(index):
			continue
		_selected = index
		break
	queue_redraw()


func _first_selectable_cell() -> int:
	for index in cell_count:
		if not has_algae(index) and not is_cyber_locked(index):
			return index
	return 0


func _play_place_effect(index: int, completed_before: int) -> void:
	if _conflicts[index]:
		if loud_pops:
			_haptic(HAPTIC_CLEAR_MS, HAPTIC_CLEAR_AMP)
		return
	var pulse := LockPulse.new()
	pulse.index = index
	_locks.append(pulse)
	var completed_after: int = _completed_unit_mask()
	var cleared: bool = false
	for unit_index in _units.size():
		var bit: int = 1 << unit_index
		if (completed_after & bit) == 0 or (completed_before & bit) != 0:
			continue
		if not _unit_matches_solution(_units[unit_index]):
			continue
		var sweep := UnitSweep.new()
		sweep.cells = _units[unit_index].duplicate()
		_sweeps.append(sweep)
		call_deferred("_spawn_line_drift", sweep.cells)
		cleared = true
	if cleared:
		_haptic(HAPTIC_CLEAR_MS, HAPTIC_CLEAR_AMP)
	else:
		_haptic(HAPTIC_PLACE_MS, HAPTIC_PLACE_AMP)


func _cue_move_audio(index: int, completed_before: int) -> void:
	if index < 0 or index >= cell_count or _values[index] == 0 or _conflicts[index]:
		return
	var cleared_unit: bool = _cleared_correct_unit(completed_before)
	_cool_ember(EMBER_UNIT_COOL if cleared_unit else EMBER_CELL_COOL)
	if cleared_unit:
		unit_cleared.emit()
		return
	correct_placed.emit()


func _cleared_correct_unit(completed_before: int) -> bool:
	var completed_after: int = _completed_unit_mask()
	for unit_index in _units.size():
		var bit: int = 1 << unit_index
		if (completed_after & bit) == 0 or (completed_before & bit) != 0:
			continue
		if _unit_matches_solution(_units[unit_index]):
			return true
	return false


func _haptic(duration_ms: int, amplitude: float) -> void:
	if not haptics_enabled:
		return
	# JS vibrate is synchronous on web and would stall the audio mixer this frame.
	call_deferred("_pulse_deferred", duration_ms, amplitude)


func _pulse_deferred(duration_ms: int, amplitude: float) -> void:
	if not haptics_enabled:
		return
	pulse_device(duration_ms, amplitude)


## Native phones feel short pulses. Browsers need a longer `navigator.vibrate` call,
## and itch.io iframes / iPhone Safari often ignore it entirely.
static func pulse_device(duration_ms: int, amplitude: float) -> void:
	var ms: int = duration_ms
	if OS.has_feature("web"):
		ms = maxi(duration_ms * 4, 60)
	Input.vibrate_handheld(ms, amplitude)
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	var js: Object = Engine.get_singleton("JavaScriptBridge")
	js.call("eval", "try{if(navigator.vibrate){navigator.vibrate(%d);}}catch(e){}" % ms)


## A correct digit that finishes a row, column, or box scores. Mistakes break the streak.
## `stake` is the poison multiplier captured before the cell was written.
func _award_unit_points(index: int, completed_before: int, stake: int = 1) -> void:
	var move_stake: int = maxi(1, stake)
	var wrong: bool = _conflicts[index]
	if seal_filling and index < _solution.size() and _values[index] == _solution[index]:
		wrong = false
	if wrong:
		_break_streak(index)
		if _ember_active:
			ember_heat = minf(1.0, ember_heat + EMBER_MISTAKE_HEAT)
		mistake_made.emit(index, move_stake)
		if move_stake > 1:
			flash_poison_miss()
		return
	var completed_after: int = _completed_unit_mask()
	var gained_any: bool = false
	var unit_count: int = 0
	var gained_total: int = 0
	for unit_index in _units.size():
		var bit: int = 1 << unit_index
		if (completed_after & bit) == 0 or (completed_before & bit) != 0:
			continue
		var unit: PackedInt32Array = _units[unit_index]
		if not _unit_matches_solution(unit):
			continue
		_streak += 1
		var gained: int = int(round(float(UNIT_POINTS * _streak) * maxf(score_mult, 0.5)))
		if _poison_bounty <= 0:
			gained *= move_stake
		score += gained
		gained_total += gained
		unit_count += 1
		_spawn_score_pop(unit, gained, _streak)
		gained_any = true
	var vine_cleared: bool = move_stake > 1 and (_solution.is_empty() or _values[index] == _solution[index])
	if vine_cleared:
		poison_solved.emit(index)
	if not gained_any and vine_cleared and _poison_bounty <= 0:
		var bonus: int = int(round(float(UNIT_POINTS) * maxf(score_mult, 0.5))) * move_stake
		score += bonus
		gained_total += bonus
		_spawn_cell_score_pop(index, bonus, move_stake)
		gained_any = true
	elif vine_cleared and _poison_bounty <= 0:
		_spawn_poison_tag(index)
	if unit_count >= 2:
		_spawn_combo_caption(unit_count, index)
		combo_cleared.emit(unit_count, gained_total)
	if gained_any:
		score_changed.emit(score, _streak)


func _break_streak(cell_index: int) -> void:
	if _streak == 0:
		return
	var lost: int = _streak
	_streak = 0
	_spawn_streak_break(lost, cell_index)
	score_changed.emit(score, _streak)


func _spawn_streak_break(lost: int, cell_index: int) -> void:
	var grid := _get_grid_rect()
	var board := _get_board_rect()
	var cell_size: float = grid.size.x / float(grid_size)
	var cell_center: Vector2 = _get_cell_position(grid, cell_size, cell_index) + Vector2(cell_size, cell_size) * 0.5
	var from_cell := ScorePop.new()
	from_cell.broken = true
	from_cell.streak = lost
	from_cell.origin = cell_center
	from_cell.drift = Vector2(0.0, minf(cell_size, grid.size.x / float(CLASSIC_GRID)) * 0.55)
	from_cell.life = STREAK_BREAK_LIFE
	_score_pops.append(from_cell)
	if lost < 2:
		return
	var from_badge := ScorePop.new()
	from_badge.broken = true
	from_badge.streak = lost
	from_badge.origin = Vector2(board.get_center().x, (board.position.y + grid.position.y) * 0.5)
	from_badge.drift = Vector2(0.0, 26.0)
	from_badge.life = STREAK_BREAK_LIFE
	_score_pops.append(from_badge)


func _unit_matches_solution(unit: PackedInt32Array) -> bool:
	if _solution.is_empty():
		return _unit_is_clear(unit)
	for index in unit:
		if _values[index] != _solution[index]:
			return false
	return true


func _spawn_score_pop(cells: PackedInt32Array, amount: int, streak: int) -> void:
	var pose: PackedVector2Array = _score_pop_pose(cells)
	var pop := ScorePop.new()
	pop.origin = pose[0]
	pop.drift = pose[1]
	pop.amount = amount
	pop.streak = streak
	if loud_pops:
		pop.life = SCORE_POP_LIFE * 1.35
	_score_pops.append(pop)


func _spawn_combo_caption(unit_count: int, at_index: int) -> void:
	var pop := ScorePop.new()
	if unit_count >= 3:
		pop.caption = "TRIPLE"
	else:
		pop.caption = "DOUBLE"
	var pose: PackedVector2Array = _caption_pose(at_index)
	pop.origin = pose[0]
	pop.drift = pose[1]
	pop.life = 1.5 if loud_pops else 1.35
	_score_pops.append(pop)
	queue_redraw()


func spawn_gold_pop(amount: int, index: int) -> void:
	if amount <= 0:
		return
	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(maxi(1, grid_size))
	var pop := ScorePop.new()
	pop.gold = true
	pop.amount = amount
	if index >= 0 and index < cell_count:
		pop.origin = _get_cell_position(grid, cell_size, index) + Vector2(cell_size, cell_size) * 0.5
	else:
		pop.origin = grid.get_center()
	pop.drift = Vector2(0.0, -cell_size * 0.95)
	pop.life = 1.2
	_score_pops.append(pop)
	queue_redraw()


func spawn_caption(text: String, cell_index: int = -1) -> void:
	if text.is_empty():
		return
	var pop := ScorePop.new()
	pop.caption = text
	var pose: PackedVector2Array = _caption_pose(cell_index)
	pop.origin = pose[0]
	pop.drift = pose[1]
	pop.life = 1.25
	_score_pops.append(pop)
	queue_redraw()


func _spawn_cell_score_pop(index: int, amount: int, stake: int) -> void:
	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(maxi(1, grid_size))
	var pop := ScorePop.new()
	pop.origin = _get_cell_position(grid, cell_size, index) + Vector2(cell_size, cell_size) * 0.5
	pop.drift = Vector2(0.0, -cell_size * 0.85)
	pop.amount = amount
	pop.streak = maxi(1, stake)
	_score_pops.append(pop)
	queue_redraw()


func _spawn_poison_tag(index: int) -> void:
	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(maxi(1, grid_size))
	var pop := ScorePop.new()
	pop.caption = "×2"
	pop.origin = _get_cell_position(grid, cell_size, index) + Vector2(cell_size, cell_size) * 0.5
	pop.drift = Vector2(0.0, -cell_size * 1.15)
	pop.life = 1.15
	_score_pops.append(pop)
	queue_redraw()


func spawn_clock_pop(seconds: int, cell_index: int = -1) -> void:
	if seconds == 0:
		return
	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(maxi(1, grid_size))
	var pop := ScorePop.new()
	pop.clock = true
	pop.amount = seconds
	pop.broken = seconds < 0
	pop.life = 1.25 if loud_pops else 1.0
	var at: int = cell_index if cell_index >= 0 else last_place_index
	if at >= 0 and at < cell_count:
		pop.origin = _get_cell_position(grid, cell_size, at) + Vector2(cell_size, cell_size) * 0.5
		var lift: float = -cell_size * 0.9 if seconds > 0 else cell_size * 0.4
		pop.drift = Vector2(0.0, lift)
	else:
		var pose: PackedVector2Array = _caption_pose(-1)
		pop.origin = pose[0]
		pop.drift = pose[1]
	pop.origin = _nudge_from_pops(pop.origin)
	_score_pops.append(pop)
	queue_redraw()


func _score_pop_pose(cells: PackedInt32Array) -> PackedVector2Array:
	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(grid_size)
	var first: int = cells[0]
	var last: int = cells[cells.size() - 1]
	var horizontal: bool = _row_of(first) == _row_of(last)
	var vertical: bool = _column_of(first) == _column_of(last)
	var origin := Vector2.ZERO
	var drift := Vector2.ZERO
	if horizontal and not vertical:
		var row: int = _row_of(first)
		origin = Vector2(lerpf(grid.end.x, size.x, 0.58), grid.position.y + (float(row) + 0.5) * cell_size)
		drift = Vector2(28.0, 0.0)
	elif vertical and not horizontal:
		var column: int = _column_of(first)
		origin = Vector2(grid.position.x + (float(column) + 0.5) * cell_size, lerpf(grid.end.y, size.y, 0.58))
		drift = Vector2(0.0, 24.0)
	else:
		var box_center := Vector2.ZERO
		for index in cells:
			box_center += _get_cell_position(grid, cell_size, index)
		box_center = box_center / float(cells.size()) + Vector2(cell_size, cell_size) * 0.5
		origin = Vector2(lerpf(0.0, grid.position.x, 0.45), box_center.y)
		drift = Vector2(-28.0, 0.0)
	origin.x = clampf(origin.x, 28.0, size.x - 28.0)
	origin.y = clampf(origin.y, 18.0, size.y - 18.0)
	return PackedVector2Array([origin, drift])


## Parks named pops beside the cell that caused them, just outside the grid.
func _caption_pose(cell_index: int) -> PackedVector2Array:
	var grid := _get_grid_rect()
	var board := _get_board_rect()
	var cell_size: float = grid.size.x / float(maxi(1, grid_size))
	var at: int = cell_index if cell_index >= 0 else last_place_index
	var cell_center: Vector2 = grid.get_center()
	if at >= 0 and at < cell_count:
		cell_center = _get_cell_position(grid, cell_size, at) + Vector2(cell_size, cell_size) * 0.5
	var grid_c: Vector2 = grid.get_center()
	var origin := Vector2.ZERO
	var drift := Vector2.ZERO
	var dx: float = cell_center.x - grid_c.x
	var dy: float = cell_center.y - grid_c.y
	if absf(dx) >= absf(dy):
		var right: bool = dx >= 0.0
		origin = Vector2(
			lerpf(grid.end.x, size.x, 0.52) if right else lerpf(0.0, grid.position.x, 0.48),
			clampf(cell_center.y, grid.position.y + 18.0, grid.end.y - 18.0)
		)
		drift = Vector2(22.0 if right else -22.0, -16.0)
	else:
		var below: bool = dy >= 0.0
		origin = Vector2(
			clampf(cell_center.x, grid.position.x + 28.0, grid.end.x - 28.0),
			lerpf(grid.end.y, size.y, 0.5) if below else lerpf(board.position.y, grid.position.y, 0.58)
		)
		drift = Vector2(0.0, 22.0 if below else -28.0)
	var stacked: int = 0
	for pop in _score_pops:
		if pop.age < 0.55 and not pop.caption.is_empty():
			stacked += 1
	origin += Vector2(0.0, float(stacked) * 34.0)
	origin = _nudge_from_pops(origin)
	origin.x = clampf(origin.x, 28.0, size.x - 28.0)
	origin.y = clampf(origin.y, 18.0, size.y - 18.0)
	return PackedVector2Array([origin, drift])


func _nudge_from_pops(origin: Vector2) -> Vector2:
	var pos: Vector2 = origin
	for _pass in 4:
		var push := Vector2.ZERO
		var hits: int = 0
		for pop in _score_pops:
			if pop.age > 0.7:
				continue
			var delta: Vector2 = pos - pop.origin
			var dist: float = delta.length()
			if dist >= POP_SEPARATION:
				continue
			hits += 1
			if dist < 0.5:
				delta = Vector2(0.0, -POP_SEPARATION)
			else:
				delta = delta.normalized() * (POP_SEPARATION - dist)
			push += delta
		if hits == 0:
			break
		pos += push / float(hits)
	return pos


func _advance_score_pops(step: float) -> void:
	var index: int = 0
	while index < _score_pops.size():
		_score_pops[index].age += step
		if _score_pops[index].age >= _score_pops[index].life:
			_score_pops.remove_at(index)
		else:
			index += 1


func _clear_effects() -> void:
	_locks.clear()
	_oracle.clear()
	_sweeps.clear()
	_drifts.clear()
	_score_pops.clear()


func _on_board_resized() -> void:
	_flow.clear()
	_layout_hit_cells()
	_layout_algae()
	_layout_poison()
	_layout_cyber_locks()
	queue_redraw()


func _rebuild_flow() -> void:
	_flow.clear()
	if _style == ArtStyle.NIGHT or size.x < 2.0 or size.y < 2.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var count: int = 36
	match _style:
		ArtStyle.DESERT:
			count = 20
		ArtStyle.FOREST:
			count = 28
		ArtStyle.EMBER:
			count = 24
		_:
			count = 36
	count = int(float(count) * _style_strength())
	for _mote in count:
		var drift := Drift.new()
		drift.wraps = true
		drift.sand = _style == ArtStyle.DESERT
		drift.position = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		drift.seed = rng.randf() * TAU
		drift.life = rng.randf_range(2.6, 5.4)
		drift.age = rng.randf() * drift.life
		drift.base_size = rng.randf_range(1.4, 2.8)
		match _style:
			ArtStyle.DESERT:
				drift.velocity = Vector2(rng.randf_range(22.0, 48.0), rng.randf_range(10.0, 26.0))
			ArtStyle.FOREST:
				if rng.randf() < 0.55:
					drift.leaf = true
					drift.velocity = Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(26.0, 58.0))
					drift.base_size = rng.randf_range(4.2, 7.5)
					drift.life = rng.randf_range(3.4, 6.2)
				else:
					drift.velocity = Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-22.0, -8.0))
					drift.base_size = rng.randf_range(1.8, 3.4)
			ArtStyle.EMBER:
				if rng.randf() < 0.4:
					drift.flame = true
					drift.velocity = Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-64.0, -28.0))
					drift.base_size = rng.randf_range(3.8, 6.6)
					drift.life = rng.randf_range(2.8, 5.0)
				else:
					drift.velocity = Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-52.0, -24.0))
					drift.base_size = rng.randf_range(1.2, 2.5)
			_:
				drift.velocity = Vector2(rng.randf_range(18.0, 46.0), rng.randf_range(-6.0, 6.0))
		_flow.append(drift)


func _advance_drifts(step: float) -> void:
	if _style != ArtStyle.NIGHT and _flow.is_empty() and size.x > 2.0:
		_rebuild_flow()
	_step_drifts(_flow, step)
	_step_drifts(_drifts, step)


func _step_drifts(motes: Array[Drift], step: float) -> void:
	var index: int = 0
	while index < motes.size():
		var mote: Drift = motes[index]
		mote.age += step
		if not mote.wraps:
			var fall: float = burst_fall
			if mote.sand and fall <= 0.001:
				fall = 1.0
			if mote.flame:
				mote.velocity.y -= 280.0 * step
				mote.velocity.x += sin(_ambient_time * 16.0 + mote.seed) * 55.0 * step
			elif mote.leaf:
				mote.velocity.y += 210.0 * step
				mote.velocity.x = sin(mote.age * 4.6 + mote.seed) * 42.0
			elif _style == ArtStyle.EMBER:
				mote.velocity.y -= 190.0 * step
			elif fall > 0.0:
				mote.velocity.y += SAND_GRAVITY * fall * step
		mote.position += mote.velocity * step
		if not mote.sand and not mote.leaf and not mote.flame:
			mote.position.y += sin(_ambient_time * 3.4 + mote.seed) * 16.0 * step
		if mote.wraps:
			if mote.age >= mote.life:
				mote.age = 0.0
			if mote.position.x > size.x + 8.0:
				mote.position.x = -8.0
				mote.position.y = fmod(absf(mote.position.y + mote.seed * 40.0), size.y)
			if mote.position.y > size.y + 8.0:
				mote.position.y = -8.0
			if mote.position.y < -8.0:
				mote.position.y = size.y + 8.0
			index += 1
		elif mote.age >= mote.life or mote.position.y > size.y + 16.0 or mote.position.y < -16.0:
			motes.remove_at(index)
		else:
			index += 1


## Sand, water, or neon kicks out of a finished row, column, or box.
func _spawn_line_drift(cells: PackedInt32Array) -> void:
	if cells.is_empty() or burst_strength <= 0.02:
		return
	var grid := _get_grid_rect()
	var cell_size: float = grid.size.x / float(grid_size)
	var fx: float = cell_size if grid_size >= CLASSIC_GRID else grid.size.x / float(CLASSIC_GRID)
	var first: int = cells[0]
	var last: int = cells[cells.size() - 1]
	var horizontal: bool = _row_of(first) == _row_of(last)
	var vertical: bool = _column_of(first) == _column_of(last)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var budget: int = 14 if _style == ArtStyle.DESERT else 10
	budget = clampi(int(round(float(budget) * burst_strength)), 6, 18)
	if OS.has_feature("web"):
		budget = mini(budget, 8)
	# A second or third line in the same combo only adds a small puff.
	if _drifts.size() >= 8:
		budget = mini(budget, 5 if OS.has_feature("web") else 6)
	budget = mini(budget, BURST_CAP - _drifts.size())
	if budget <= 0:
		return
	var count: int = cells.size()
	for mote_index in budget:
		var cell: int = cells[mote_index % count]
		var center: Vector2 = _get_cell_position(grid, cell_size, cell) + Vector2(cell_size, cell_size) * 0.5
		_drifts.append(_make_burst(rng, center, cell_size, fx, horizontal, vertical))


func _make_burst(rng: RandomNumberGenerator, center: Vector2, cell_size: float, fx: float, horizontal: bool, vertical: bool) -> Drift:
	var mote := Drift.new()
	mote.sand = _style == ArtStyle.DESERT
	mote.seed = rng.randf() * TAU
	mote.position = center + Vector2(rng.randf_range(-cell_size * 0.32, cell_size * 0.32), rng.randf_range(-cell_size * 0.32, cell_size * 0.32))
	var outward := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if outward.length_squared() < 0.05:
		outward = Vector2.RIGHT
	outward = outward.normalized()
	if horizontal and not vertical:
		outward = Vector2(rng.randf_range(-0.35, 0.35), -1.0 if rng.randf() < 0.55 else 1.0).normalized()
	elif vertical and not horizontal:
		outward = Vector2(-1.0 if rng.randf() < 0.5 else 1.0, rng.randf_range(-0.35, 0.35)).normalized()
	match _style:
		ArtStyle.DESERT:
			mote.life = rng.randf_range(1.05, 1.7)
			mote.base_size = fx * rng.randf_range(0.018, 0.042)
			mote.velocity = Vector2(
				rng.randf_range(-52.0, 52.0),
				-fx * rng.randf_range(0.45, 0.95)
			)
		ArtStyle.WATER:
			mote.life = rng.randf_range(1.05, 1.7)
			mote.base_size = fx * rng.randf_range(0.12, 0.24)
			mote.velocity = outward * fx * rng.randf_range(0.35, 0.85)
			mote.hollow = burst_hollow
		ArtStyle.FOREST:
			mote.leaf = true
			mote.life = rng.randf_range(1.15, 1.85)
			mote.base_size = fx * rng.randf_range(0.12, 0.22)
			mote.velocity = Vector2(
				rng.randf_range(-48.0, 48.0),
				fx * rng.randf_range(0.15, 0.55)
			)
		ArtStyle.EMBER:
			mote.flame = true
			mote.life = rng.randf_range(0.55, 0.95)
			mote.base_size = fx * rng.randf_range(0.1, 0.2)
			mote.velocity = Vector2(
				rng.randf_range(-36.0, 36.0),
				-fx * rng.randf_range(0.85, 1.65)
			)
		_:
			mote.life = rng.randf_range(0.55, 0.95)
			mote.base_size = fx * rng.randf_range(0.08, 0.16)
			mote.velocity = outward * fx * rng.randf_range(0.9, 1.7)
			mote.hollow = burst_hollow
	return mote


func _draw_world_flow() -> void:
	_draw_drift_list(_flow, false)


func _draw_line_drifts() -> void:
	_draw_drift_list(_drifts, true)


func _draw_pyramids(board: Rect2) -> void:
	var strength: float = _style_strength()
	if strength <= 0.02:
		return
	var left := PackedVector2Array([
		Vector2(board.position.x - 86.0, board.end.y + 18.0),
		Vector2(board.position.x - 18.0, board.position.y + board.size.y * 0.42),
		Vector2(board.position.x + 42.0, board.end.y + 18.0),
	])
	var right := PackedVector2Array([
		Vector2(board.end.x - 36.0, board.end.y + 22.0),
		Vector2(board.end.x + 28.0, board.position.y + board.size.y * 0.36),
		Vector2(board.end.x + 98.0, board.end.y + 22.0),
	])
	var far := PackedVector2Array([
		Vector2(board.position.x - 28.0, board.position.y + 8.0),
		Vector2(board.position.x + 18.0, board.position.y - 54.0),
		Vector2(board.position.x + 68.0, board.position.y + 8.0),
	])
	draw_colored_polygon(left, Color(0.18, 0.08, 0.03, 0.34 * strength))
	draw_colored_polygon(right, Color(0.16, 0.07, 0.02, 0.3 * strength))
	draw_colored_polygon(far, Color(0.12, 0.06, 0.03, 0.18 * strength))


func _draw_trees(board: Rect2) -> void:
	var strength: float = _style_strength()
	if strength <= 0.02:
		return
	var left := PackedVector2Array([
		Vector2(board.position.x - 72.0, board.end.y + 16.0),
		Vector2(board.position.x - 22.0, board.position.y + board.size.y * 0.28),
		Vector2(board.position.x + 28.0, board.end.y + 16.0),
	])
	var mid := PackedVector2Array([
		Vector2(board.end.x - 18.0, board.end.y + 20.0),
		Vector2(board.end.x + 22.0, board.position.y + board.size.y * 0.22),
		Vector2(board.end.x + 68.0, board.end.y + 20.0),
	])
	var far := PackedVector2Array([
		Vector2(board.position.x - 8.0, board.position.y + 14.0),
		Vector2(board.position.x + 26.0, board.position.y - 62.0),
		Vector2(board.position.x + 62.0, board.position.y + 14.0),
	])
	draw_colored_polygon(left, Color(0.02, 0.08, 0.03, 0.42 * strength))
	draw_colored_polygon(mid, Color(0.03, 0.1, 0.04, 0.36 * strength))
	draw_colored_polygon(far, Color(0.02, 0.06, 0.02, 0.22 * strength))


func _draw_crags(board: Rect2) -> void:
	var strength: float = _style_strength()
	if strength <= 0.02:
		return
	var left := PackedVector2Array([
		Vector2(board.position.x - 90.0, board.end.y + 20.0),
		Vector2(board.position.x - 38.0, board.position.y + board.size.y * 0.5),
		Vector2(board.position.x - 8.0, board.end.y - 8.0),
		Vector2(board.position.x + 36.0, board.end.y + 20.0),
	])
	var right := PackedVector2Array([
		Vector2(board.end.x - 40.0, board.end.y + 22.0),
		Vector2(board.end.x + 8.0, board.position.y + board.size.y * 0.4),
		Vector2(board.end.x + 42.0, board.end.y - 4.0),
		Vector2(board.end.x + 96.0, board.end.y + 22.0),
	])
	draw_colored_polygon(left, Color(0.12, 0.03, 0.01, 0.4 * strength))
	draw_colored_polygon(right, Color(0.16, 0.04, 0.01, 0.34 * strength))


func _draw_drift_list(motes: Array[Drift], burst: bool) -> void:
	var strength: float = burst_strength if burst else _style_strength()
	if strength <= 0.02:
		return
	var size_scale: float = burst_size_scale if burst else _style_size()
	for mote in motes:
		var fade: float = 1.0
		if burst:
			var linear: float = clampf(mote.age / mote.life, 0.0, 1.0)
			fade = 1.0 - linear * linear
		elif mote.wraps:
			fade = sin((mote.age / mote.life) * PI)
		var radius: float = maxf(0.6, mote.base_size * size_scale)
		if burst and mote.flame:
			radius *= 1.0 + mote.age * 0.7
		elif burst and not mote.sand and not mote.leaf:
			radius *= 1.0 + mote.age * 0.35
		var color: Color
		var core: Color
		if mote.sand:
			color = Color(1.0, 0.72, 0.28, (0.28 if not burst else 0.95) * fade * strength)
			core = Color(1.0, 0.94, 0.72, color.a * 0.85)
		elif mote.leaf:
			var mix_gold: float = 0.5 + 0.5 * sin(mote.seed)
			color = Color(0.38, 0.72, 0.22).lerp(Color(0.86, 0.68, 0.18), mix_gold)
			color = color.lerp(Color(0.72, 0.38, 0.12), 0.25 + 0.2 * sin(mote.seed * 1.7))
			color.a = (0.55 if not burst else 0.92) * fade * strength
			core = Color(0.95, 0.9, 0.45, color.a * 0.75)
		elif mote.flame:
			var mix_gold: float = 0.5 + 0.5 * sin(mote.seed * 1.3)
			color = Color(1.0, 0.28, 0.05).lerp(Color(1.0, 0.62, 0.1), mix_gold)
			color.a = (0.55 if not burst else 0.92) * fade * strength
			core = Color(1.0, 0.94, 0.52, color.a * 0.95)
		elif _style == ArtStyle.WATER:
			color = Color(0.45, 0.88, 1.0, (0.28 if not burst else 0.9) * fade * strength)
			core = Color(0.9, 0.98, 1.0, color.a * 0.8)
		elif _style == ArtStyle.FOREST:
			color = Color(0.55, 0.95, 0.32, (0.3 if not burst else 0.92) * fade * strength)
			core = Color(0.9, 1.0, 0.55, color.a * 0.88)
		elif _style == ArtStyle.EMBER:
			color = Color(1.0, 0.4, 0.1, (0.32 if not burst else 0.95) * fade * strength)
			core = Color(1.0, 0.86, 0.4, color.a * 0.9)
		else:
			color = Color(0.96, 0.55, 1.0, (0.22 if not burst else 0.95) * fade * strength)
			core = Color(1.0, 0.86, 1.0, color.a * 0.9)
		if mote.leaf:
			var spin: float = mote.seed + mote.age * 3.2
			_draw_leaf(mote.position, radius, spin, color, core)
			continue
		if mote.flame:
			_draw_flame(mote.position, radius, mote.seed, mote.age, color, core)
			continue
		if burst and mote.hollow > 0.05:
			_draw_bubble(mote.position, radius, color, core, mote.hollow)
			continue
		if burst and not mote.sand:
			var halo := color
			halo.a *= 0.28
			draw_circle(mote.position, radius * 1.8, halo)
		draw_circle(mote.position, radius, color)
		draw_circle(mote.position, radius * 0.42, core)


func _draw_leaf(center: Vector2, radius: float, angle: float, color: Color, vein: Color) -> void:
	draw_set_transform(center, angle, Vector2.ONE)
	var leaf := PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius * 0.52, radius * 0.08),
		Vector2(0.0, radius * 0.92),
		Vector2(-radius * 0.52, radius * 0.08),
	])
	draw_colored_polygon(leaf, color)
	var inner := PackedVector2Array([
		Vector2(0.0, -radius * 0.55),
		Vector2(radius * 0.22, radius * 0.05),
		Vector2(0.0, radius * 0.5),
		Vector2(-radius * 0.22, radius * 0.05),
	])
	draw_colored_polygon(inner, vein)
	draw_line(Vector2(0.0, -radius * 0.7), Vector2(0.0, radius * 0.65), vein, maxf(1.0, radius * 0.08), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_flame(center: Vector2, radius: float, seed: float, age: float, color: Color, core: Color) -> void:
	var flicker: float = 0.78 + 0.22 * sin(age * 26.0 + seed)
	var lean: float = sin(age * 14.0 + seed * 1.4) * 0.18
	draw_set_transform(center, lean, Vector2.ONE)
	var height: float = radius * 2.6 * flicker
	var width: float = radius * (0.62 + 0.12 * sin(age * 19.0 + seed * 2.0))
	var outer := PackedVector2Array([
		Vector2(0.0, -height),
		Vector2(width * 0.55, -height * 0.28),
		Vector2(width, height * 0.38),
		Vector2(0.0, height * 0.5),
		Vector2(-width, height * 0.38),
		Vector2(-width * 0.55, -height * 0.28),
	])
	var glow := color
	glow.a *= 0.35
	draw_colored_polygon(outer, glow)
	var mid := PackedVector2Array([
		Vector2(0.0, -height * 0.78),
		Vector2(width * 0.34, -height * 0.12),
		Vector2(width * 0.55, height * 0.22),
		Vector2(0.0, height * 0.32),
		Vector2(-width * 0.55, height * 0.22),
		Vector2(-width * 0.34, -height * 0.12),
	])
	draw_colored_polygon(mid, color)
	var inner := PackedVector2Array([
		Vector2(0.0, -height * 0.42),
		Vector2(width * 0.18, height * 0.02),
		Vector2(0.0, height * 0.22),
		Vector2(-width * 0.18, height * 0.02),
	])
	draw_colored_polygon(inner, core)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bubble(center: Vector2, radius: float, color: Color, shine: Color, hollow: float) -> void:
	var rim: float = maxf(1.15, radius * lerpf(0.4, 0.13, hollow))
	var glow := color
	glow.a *= 0.22
	draw_circle(center, radius * 1.22, glow, false, rim * 0.8, true)
	draw_circle(center, radius, color, false, rim, true)
	var inner := color
	inner.a *= 0.28
	var inner_radius: float = maxf(radius * lerpf(0.42, 0.72, hollow), rim * 1.4)
	if inner_radius < radius - rim:
		draw_circle(center, inner_radius, inner, false, maxf(0.8, rim * 0.35), true)
	var spec := shine
	spec.a *= 0.75
	draw_circle(center + Vector2(-radius, -radius) * 0.38, maxf(1.0, rim * 0.9), spec)


func _advance_effects(step: float) -> void:
	var lock_index: int = 0
	while lock_index < _locks.size():
		_locks[lock_index].age += step
		if _locks[lock_index].age >= LOCK_DURATION:
			_locks.remove_at(lock_index)
		else:
			lock_index += 1
	var oracle_index: int = 0
	while oracle_index < _oracle.size():
		_oracle[oracle_index].age += step
		if _oracle[oracle_index].age >= ORACLE_LIFE:
			_oracle.remove_at(oracle_index)
		else:
			oracle_index += 1
	var sweep_index: int = 0
	while sweep_index < _sweeps.size():
		_sweeps[sweep_index].age += step
		if _sweeps[sweep_index].age >= SWEEP_DURATION:
			_sweeps.remove_at(sweep_index)
		else:
			sweep_index += 1


func _completed_unit_mask() -> int:
	var mask: int = 0
	for unit_index in _units.size():
		if _unit_is_clear(_units[unit_index]):
			mask |= 1 << unit_index
	return mask


func _unit_is_clear(unit: PackedInt32Array) -> bool:
	for index in unit:
		if _values[index] == 0 or _conflicts[index]:
			return false
	return true


func _lock_scale(index: int) -> float:
	for pulse in _locks:
		if pulse.index != index:
			continue
		var travel: float = clampf(pulse.age / LOCK_DURATION, 0.0, 1.0)
		return lerpf(1.26, 1.0, 1.0 - pow(1.0 - travel, 3.0))
	return 1.0


## A repeat is always painted. Show mistakes also paints a digit that is not the finished answer.
func _paint_as_mistake(index: int) -> bool:
	if _conflicts[index]:
		return true
	if not check_mistakes or _solution.size() != cell_count:
		return false
	if _givens[index] != 0 or _values[index] == 0:
		return false
	return _values[index] != _solution[index]


## A slow wobble on a repeated digit. The cell and the grid stay still.
func _conflict_shake(index: int, cell_size: float) -> Vector2:
	if not _paint_as_mistake(index):
		return Vector2.ZERO
	var phase: float = float(index) * 1.37
	var across: float = sin(_ambient_time * 4.4 + phase)
	var lift: float = sin(_ambient_time * 3.1 + phase * 0.8)
	return Vector2(across * cell_size * 0.045, lift * cell_size * 0.016)


func _draw_conflict_motes(grid: Rect2, cell_size: float, fx: float) -> void:
	for index in cell_count:
		if not _paint_as_mistake(index) or _values[index] == 0:
			continue
		var center: Vector2 = _get_cell_position(grid, cell_size, index) + Vector2(cell_size, cell_size) * 0.5
		center += _conflict_shake(index, fx)
		for mote in CONFLICT_MOTE_COUNT:
			var angle: float = _ambient_time * (0.7 + float(mote) * 0.22) + float(index) * 0.4 + float(mote) * TAU / float(CONFLICT_MOTE_COUNT)
			var radius: float = minf(cell_size * 0.38, fx * (0.22 + float(mote) * 0.035))
			var speck := COLOR_CONFLICT_TEXT
			speck.a = 0.45 + 0.3 * absf(sin(_ambient_time * 1.8 + float(mote + index)))
			draw_circle(center + Vector2(cos(angle), sin(angle)) * radius, maxf(1.6, fx * 0.028), speck)


func _get_digit_color(index: int) -> Color:
	var color: Color = _get_text_color(index)
	for pulse in _locks:
		if pulse.index != index:
			continue
		var travel: float = clampf(pulse.age / LOCK_DURATION, 0.0, 1.0)
		return color.lerp(Color(1.0, 1.0, 1.0), (1.0 - travel) * 0.85)
	return color


func _build_sparkles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _spark in SPARK_COUNT:
		_spark_positions.append(Vector2(rng.randf(), rng.randf()))
		_spark_seeds.append(rng.randf() * TAU)


func _get_highlight(index: int) -> Color:
	if _paint_as_mistake(index):
		return COLOR_CONFLICT_CELL
	if _selected < 0:
		return COLOR_NONE
	if index == _selected:
		return _c_selected()
	var selected_value: int = _values[_selected]
	if selected_value != 0 and _values[index] == selected_value:
		return _c_same()
	if _is_peer_of(index, _selected):
		return _c_peer()
	return COLOR_NONE


func _get_text_color(index: int) -> Color:
	if _paint_as_mistake(index):
		return COLOR_CONFLICT_TEXT
	return _c_given() if _givens[index] != 0 else _c_player()


## Flags a digit only when it is already repeated in its row, column, or box.
func _update_conflicts() -> void:
	_conflicts.fill(false)
	for unit in _units:
		var first_seen: Dictionary = {}
		for index in unit:
			var value: int = _values[index]
			if value == 0:
				continue
			if first_seen.has(value):
				_conflicts[index] = true
				_conflicts[first_seen[value]] = true
			else:
				first_seen[value] = index


func _is_solved() -> bool:
	for index in cell_count:
		if _values[index] == 0 or _conflicts[index]:
			return false
	return true


func _count_empty_cells() -> int:
	var empty: int = 0
	for value in _values:
		if value == 0:
			empty += 1
	return empty


func digit_counts() -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(grid_size)
	counts.fill(0)
	for value in _values:
		if value >= 1 and value <= grid_size:
			counts[value - 1] += 1
	return counts


func _count_digit(digit: int) -> int:
	if digit < 1 or digit > grid_size:
		return 0
	var count: int = 0
	for value in _values:
		if value == digit:
			count += 1
	return count


func _digit_mask() -> int:
	return (1 << grid_size) - 1


func _emit_progress() -> void:
	progress_changed.emit(_count_empty_cells())
	digits_changed.emit()


func _is_peer_of(index: int, other: int) -> bool:
	return _row_of(index) == _row_of(other) or _column_of(index) == _column_of(other) or _box_of(index) == _box_of(other)


func _build_units() -> void:
	_units.clear()
	for unit in range(grid_size):
		var row_cells := PackedInt32Array()
		var column_cells := PackedInt32Array()
		for step in range(grid_size):
			row_cells.append(unit * grid_size + step)
			column_cells.append(step * grid_size + unit)
		_units.append(row_cells)
		_units.append(column_cells)
	@warning_ignore("integer_division")
	var boxes_across: int = grid_size / box_width
	@warning_ignore("integer_division")
	var boxes_down: int = grid_size / box_height
	for box_row in range(boxes_down):
		for box_column in range(boxes_across):
			var box_cells := PackedInt32Array()
			for row in range(box_height):
				for column in range(box_width):
					box_cells.append((box_row * box_height + row) * grid_size + box_column * box_width + column)
			_units.append(box_cells)


@warning_ignore("integer_division")
func _row_of(index: int) -> int:
	return index / grid_size


func _column_of(index: int) -> int:
	return index % grid_size


@warning_ignore("integer_division")
func _box_of(index: int) -> int:
	var boxes_across: int = grid_size / box_width
	return (index / (grid_size * box_height)) * boxes_across + (index % grid_size) / box_width
