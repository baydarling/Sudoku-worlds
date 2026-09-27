extends Control
## Drives the flow between the menus, Journey, a single level, and the win screen.

enum Difficulty { EASY, MEDIUM, HARD }
enum Mode { JOURNEY, LEVEL, QUICK, MINI }
enum JourneyPace { STANDARD, RELAXED }

const DIFFICULTY_NAMES: Array[String] = ["Easy", "Medium", "Hard"]


## How many cells are blanked out for each difficulty.
const DIFFICULTY_BLANKS: Array[int] = [40, 48, 54]
## Mini 4x4 blanks for Easy / Medium / Hard.
const MINI_BLANKS: Array[int] = [6, 8, 10]
## 6x6 blanks for Easy / Medium / Hard.
const WIDE_BLANKS: Array[int] = [12, 16, 20]
## Opening clock for a Mini Race. A clear adds bonus seconds.
const MINI_RACE_START: float = 60.0
const MINI_RACE_BONUS: float = 19.0
const MINI_RACE_CAP: float = 99.0
const WIDE_RACE_START: float = 90.0
const WIDE_RACE_BONUS: float = 29.0
const WIDE_RACE_CAP: float = 120.0
const MINI_CHAIN_HOLD: float = 0.28
const MINI_CHAIN_OUT: float = 0.32
const MINI_CHAIN_IN: float = 0.38
## Caps uniqueness search so a race deal cannot stall a frame.
const RACE_SEARCH_BUDGET: int = 12000
## A wrong digit in Race subtracts this many seconds.
const RACE_MISTAKE_PENALTY: float = 4.0
## Journey walks each world in order. Difficulty climbs toward Ember.
const JOURNEY_STAGES: int = 3
const JOURNEY_DIFFICULTY: Array[int] = [
	Difficulty.EASY, Difficulty.EASY, Difficulty.MEDIUM,
	Difficulty.EASY, Difficulty.MEDIUM, Difficulty.MEDIUM,
	Difficulty.MEDIUM, Difficulty.MEDIUM, Difficulty.HARD,
	Difficulty.MEDIUM, Difficulty.HARD, Difficulty.HARD,
	Difficulty.HARD, Difficulty.HARD, Difficulty.HARD,
]

## Padding around the game screen, before any screen cutout is taken into account.
const BASE_MARGIN: int = 16
## Extra space above the phone home indicator / itch.io chrome.
const TOUCH_BOTTOM_INSET: int = 40
## Touch + emulated mouse can fire twice; keep only the first tap.
const TAP_GUARD_MS: int = 90
## Warm amber with almost no blue, for playing in bed.
const NIGHT_TINT: Color = Color(0.9, 0.52, 0.16)
const SETTINGS_PATH: String = "user://settings.cfg"
const RUN_JOURNEY: String = "run_journey"
const RUN_LEVEL: String = "run_level"
const RUN_QUICK: String = "run_quick"
const RUN_MINI: String = "run_mini"
const COLOR_HIGHSCORE: Color = Color(1.0, 0.82, 0.32)
const COLOR_HIGHSCORE_MUTED: Color = Color(0.7, 0.55, 0.84)
## Designed bus levels. Player sliders sit on top of these.
const MUSIC_BUS_DB: float = -6.0
const SFX_BUS_DB: float = -12.0
const UI_BUS_DB: float = -8.0
const WIN_BUS_DB: float = -6.0
const COMPLETION_A: AudioStream = preload("res://audio/completion_1.wav")
const COMPLETION_B: AudioStream = preload("res://audio/completion_2.wav")
## About ±0.8 semitones so each clear is a little different.
const COMPLETION_PITCH: float = 1.05
const CLICK_A: AudioStream = preload("res://audio/click_1.wav")
const CLICK_B: AudioStream = preload("res://audio/click_2.wav")
const CLICK_PITCH: float = 1.05
## Short one-shots on their own players so web polyphony cannot drop a tap.
const ONESHOT_VOICES: int = 3
const MENU_STREAM: AudioStream = preload("res://audio/menu.mp3")
const WIN_STREAM: AudioStream = preload("res://audio/win.mp3")
const TREASURE_STREAM: AudioStream = preload("res://audio/treasure.mp3")
const OVERHEAT_STREAM: AudioStream = preload("res://audio/overheat.wav")
const RELIC_BUY_STREAM: AudioStream = preload("res://audio/relic_buy.wav")
const CYBER_UNLOCK_STREAM: AudioStream = preload("res://audio/cyber_unlock.mp3")
const ALGAE_SPLASH_STREAM: AudioStream = preload("res://audio/algae_splash.wav")
const ALGAE_TAP_STREAM: AudioStream = preload("res://audio/algae_tap.wav")
const LEAF_CLEAR_STREAM: AudioStream = preload("res://audio/leaf_clear.wav")
const AUDIO_SILENCE_DB: float = -42.0
const AMBIENCE_FADE_IN: float = 1.7
const AMBIENCE_FADE_OUT: float = 0.55
const MENU_FADE_IN: float = 0.9
const MENU_FADE_OUT: float = 0.7
const SAVE_DEBOUNCE: float = 0.45
const CONFIRM_TIMEOUT: float = 2.6
## Hints granted at the start of a puzzle, by Easy / Medium / Hard.
const HINTS_BY_DIFFICULTY: Array[int] = [3, 2, 1]
const MINI_HINTS_BY_DIFFICULTY: Array[int] = [2, 1, 1]
const WIDE_HINTS_BY_DIFFICULTY: Array[int] = [2, 2, 1]
## Optional star clocks by Easy / Medium / Hard. Relaxed adds half again.
const STAR_TIME_LIMITS: Array[float] = [240.0, 480.0, 720.0]
const MISTAKE_SHAKE_TIME: float = 0.32
const MISTAKE_SHAKE_PX: float = 8.0
const OVERHEAT_SHAKE_TIME: float = 0.5
const OVERHEAT_SHAKE_PX: float = 15.0
const OVERHEAT_SCORE_COST: int = 300
const MISTAKE_FLASH_HOLD: float = 0.35
const MISTAKE_FLASH_FADE: float = 0.55
const LAVA_RED: Color = Color(1.0, 0.28, 0.08)

## How a new screen and its buttons arrive after a choice.
const MOTION_REVEAL: float = 0.56
const MOTION_STAGGER: float = 0.06


## In-game pad and action buttons, painted to match the current world.
class Chrome extends RefCounted:
	var fill: Color = Color(0.11, 0.05, 0.16)
	var hover: Color = Color(0.18, 0.08, 0.26)
	var pressed: Color = Color(0.07, 0.03, 0.11)
	var disabled: Color = Color(0.07, 0.035, 0.1)
	var border: Color = Color(0.9, 0.48, 1.0)
	var ink: Color = Color(0.94, 0.88, 1.0)
	var muted: Color = Color(0.66, 0.52, 0.78)
	var disabled_ink: Color = Color(0.42, 0.32, 0.48)
	var radius: int = 18
	var glow: Color = Color(0.9, 0.4, 1.0, 0.38)


## Worlds on the Levels list. Open one in the inspector to change its particles.
@export var worlds: Array[WorldLook] = []

@onready var _background: ColorRect = $Background
@onready var _main_menu: Control = $MainMenu
@onready var _journey_menu: Control = $JourneyMenu
@onready var _journey_hint: Label = $JourneyMenu/Center/VBox/Hint
@onready var _pace_row: HBoxContainer = $JourneyMenu/Center/VBox/PaceRow
@onready var _standard_pace_button: Button = $JourneyMenu/Center/VBox/PaceRow/StandardButton
@onready var _relaxed_pace_button: Button = $JourneyMenu/Center/VBox/PaceRow/RelaxedButton
@onready var _continue_button: Button = $JourneyMenu/Center/VBox/ContinueButton
@onready var _new_journey_button: Button = $JourneyMenu/Center/VBox/NewButton
@onready var _journey_back_button: Button = $JourneyMenu/Center/VBox/BackButton
@onready var _levels_menu: Control = $LevelsMenu
@onready var _level_list: VBoxContainer = $LevelsMenu/Center/VBox/List
@onready var _levels_back_button: Button = $LevelsMenu/Center/VBox/BackButton
@onready var _difficulty_menu: Control = $DifficultyMenu
@onready var _difficulty_title: Label = $DifficultyMenu/Center/VBox/Title
@onready var _easy_button: Button = $DifficultyMenu/Center/VBox/EasyButton
@onready var _medium_button: Button = $DifficultyMenu/Center/VBox/MediumButton
@onready var _hard_button: Button = $DifficultyMenu/Center/VBox/HardButton
@onready var _difficulty_back_button: Button = $DifficultyMenu/Center/VBox/BackButton
@onready var _race_menu: Control = $RaceMenu
@onready var _quick_play_button: Button = $MainMenu/Body/QuickPlayButton
@onready var _race_mode_button: Button = $MainMenu/Body/RaceButton
@onready var _race_mini_button: Button = $RaceMenu/Center/VBox/MiniButton
@onready var _race_wide_button: Button = $RaceMenu/Center/VBox/WideButton
@onready var _race_back_button: Button = $RaceMenu/Center/VBox/BackButton
@onready var _game_screen: Control = $GameScreen
@onready var _game_margin: MarginContainer = $GameScreen/Margin
@onready var _win_screen: Control = $WinScreen
@onready var _win_dim: ColorRect = $WinScreen/Dim
@onready var _win_bloom: ColorRect = $WinScreen/Bloom
@onready var _win_panel: PanelContainer = $WinScreen/Center/Panel
@onready var _win_label: Label = $WinScreen/Center/Panel/Margin/VBox/WinLabel
@onready var _win_stars: WinStars = $WinScreen/Center/Panel/Margin/VBox/WinStars
@onready var _board: SudokuBoard = $GameScreen/Margin/VBox/BoardWrap/Board
@onready var _number_pad: GridContainer = $GameScreen/Margin/VBox/NumberPad
@onready var _notes_button: Button = $GameScreen/Margin/VBox/ActionBar/NotesButton
@onready var _undo_button: Button = $GameScreen/Margin/VBox/ActionBar/UndoButton
@onready var _hint_button: Button = $GameScreen/Margin/VBox/ActionBar/HintButton
var _erase_button: Button
var _digit_buttons: Array[Button] = []
var _digit_remain_labels: Array[Label] = []
var _pad_enabled: bool = false
var _chrome: Chrome = Chrome.new()
@onready var _status_label: Label = $GameScreen/Margin/VBox/TopBar/StatusLabel
@onready var _journey_button: Button = $MainMenu/Body/JourneyCluster/JourneyButton
@onready var _journey_links: HBoxContainer = $MainMenu/Body/JourneyCluster/JourneyLinks
@onready var _home_new_button: Button = $MainMenu/Body/JourneyCluster/JourneyLinks/NewGame
@onready var _home_worlds_button: Button = $MainMenu/Body/JourneyCluster/JourneyLinks/Worlds
@onready var _logo_float: Control = $MainMenu/Header/LogoSlot/LogoFloat
@onready var _home_quit_button: Button = $MainMenu/Header/Quit
@onready var _streak_button: Button = $MainMenu/Header/Streak
@onready var _streak_count: Label = $MainMenu/Header/Streak/StreakCol/Count
@onready var _levels_button: Button = $JourneyMenu/Center/VBox/WorldsButton
@onready var _quit_button: Button = $SettingsMenu/Center/VBox/QuitButton
@onready var _settings_button: Button = $MainMenu/Footer/FooterRow/SettingsButton
@onready var _profile_button: Button = $MainMenu/Footer/FooterRow/ProfileButton
@onready var _board_button: Button = $MainMenu/Footer/FooterRow/BoardButton
@onready var _profile_menu: Control = $ProfileMenu
@onready var _profile_stats: Label = $ProfileMenu/Center/VBox/Stats
@onready var _profile_worlds_button: Button = $ProfileMenu/Center/VBox/WorldsButton
@onready var _profile_back_button: Button = $ProfileMenu/Center/VBox/BackButton
@onready var _board_menu: Control = $BoardMenu
@onready var _board_list: VBoxContainer = $BoardMenu/Center/VBox/List
@onready var _board_back_button: Button = $BoardMenu/Center/VBox/BackButton
@onready var _settings_menu: Control = $SettingsMenu
@onready var _settings_hint: Label = $SettingsMenu/Center/VBox/Hint
@onready var _night_button: Button = $SettingsMenu/Center/VBox/NightButton
@onready var _buzz_button: Button = $SettingsMenu/Center/VBox/BuzzButton
@onready var _check_button: Button = $SettingsMenu/Center/VBox/CheckButton
@onready var _music_block: Control = $SettingsMenu/Center/VBox/MusicBlock
@onready var _music_label: Label = $SettingsMenu/Center/VBox/MusicBlock/MusicLabel
@onready var _music_slider: HSlider = $SettingsMenu/Center/VBox/MusicBlock/MusicSlider
@onready var _sounds_block: Control = $SettingsMenu/Center/VBox/SoundsBlock
@onready var _sounds_label: Label = $SettingsMenu/Center/VBox/SoundsBlock/SoundsLabel
@onready var _sounds_slider: HSlider = $SettingsMenu/Center/VBox/SoundsBlock/SoundsSlider
@onready var _settings_back_button: Button = $SettingsMenu/Center/VBox/BackButton
@onready var _night_tint: CanvasModulate = $NightTint
@onready var _ambience: AudioStreamPlayer = $AmbiencePlayer
@onready var _completions: AudioStreamPlayer = $CompletionsPlayer
@onready var _clicks: AudioStreamPlayer = $ClicksPlayer
@onready var _menu: AudioStreamPlayer = $MenuPlayer
@onready var _win: AudioStreamPlayer = $WinPlayer
@onready var _menu_button: Button = $GameScreen/Margin/VBox/TopBar/MenuButton
@onready var _new_button: Button = $GameScreen/Margin/VBox/TopBar/NewButton
@onready var _time_label: Label = $WinScreen/Center/Panel/Margin/VBox/TimeLabel
@onready var _highscore_label: Label = $WinScreen/Center/Panel/Margin/VBox/HighscoreLabel
@onready var _ask_label: Label = $WinScreen/Center/Panel/Margin/VBox/AskLabel
@onready var _yes_button: Button = $WinScreen/Center/Panel/Margin/VBox/Buttons/YesButton
@onready var _no_button: Button = $WinScreen/Center/Panel/Margin/VBox/Buttons/NoButton

var _difficulty: Difficulty = Difficulty.EASY
var _mode: Mode = Mode.JOURNEY
var _journey_level: int = 1
var _journey_progress: int = 0
var _journey_run_score: int = 0
var _journey_complete: bool = false
var _journey_pace: JourneyPace = JourneyPace.STANDARD
var _relics: RelicManager = RelicManager.new()
var _economy: EconomyManager = EconomyManager.new()
var _shop: ShopManager = ShopManager.new()
var _race: RaceModeManager = RaceModeManager.new()
var _journey_stars: PackedInt32Array = PackedInt32Array()
var _puzzle_hints_used: int = 0
var _puzzle_seals_used: int = 0
var _puzzle_mistakes: int = 0
## The first full heat bar this puzzle only warns. The next one is the overheat.
var _ember_warned: bool = false
var _last_puzzle_stars: int = 0
var _last_gold_paid: int = 0
var _last_gold_clear: int = 0
var _last_gold_flawless: int = 0
var _last_gold_interest: int = 0
var _last_gold_vines: int = 0
var _last_gold_sand: int = 0
var _last_gold_stars: int = 0
var _last_gold_lost: int = 0
var _last_star_hint: bool = false
var _last_star_clean: bool = false
var _last_star_clock: bool = false
var _journey_failed: bool = false
var _shop_screen: Control
var _shop_title: Label
var _shop_hint: Label
var _shop_buttons: Array[Button] = []
var _shop_glyphs: Array[RelicGlyph] = []
var _shop_owned_row: HBoxContainer
var _shop_reroll: Button
var _shop_skip: Button
var _shop_waiting: bool = false
var _relic_tray: HBoxContainer
var _play_relic_glyphs: Array[RelicGlyph] = []
var _tool_bar: VBoxContainer
var _tool_prompt: Label
var _tool_buttons: Array[Button] = []
var _tool_glyphs: Array[RelicGlyph] = []
var _armed_tool: int = -1
var _last_star_seal: bool = false
var _journey_map: VBoxContainer
var _world_index: int = 0
var _elapsed_seconds: float = 0.0
var _timer_running: bool = false
var _remaining_cells: int = 0
var _round: int = 0
var _stage_clock: float = 0.0
var _win_tween: Tween
var _logo_tween: Tween
var _night_tween: Tween
var _ambience_fade: Tween
var _menu_fade: Tween
var _transitioning: bool = false
var _night_mode: bool = false
var _haptics_enabled: bool = true
var _check_mistakes: bool = false
var _hints_left: int = 3
var _last_session: String = ""
var _music_volume: float = 1.0
var _sounds_volume: float = 1.0
var _high_scores: Dictionary[String, int] = {}
var _streak_days: int = 0
var _streak_date: String = ""
var _puzzles_cleared: int = 0
var _playing_look: WorldLook
var _ambience_should_loop: bool = false
var _menu_should_loop: bool = false
var _confirm_new_journey: bool = false
var _confirm_new_puzzle: bool = false
var _journey_confirm_id: int = 0
var _puzzle_confirm_id: int = 0
var _save_queued: bool = false
var _timer_held: bool = false
var _dealing: bool = false
var _race_hinting: bool = false
var _mini_clears: int = 0
var _mini_race_score: int = 0
var _race_seconds: float = 0.0
var _mini_chaining: bool = false
var _race_ending: bool = false
var _race_chain_tween: Tween
var _race_flash: ColorRect
var _poison_screen_flash: ColorRect
var _ember_rush: EmberRush
var _poison_screen_tween: Tween
var _race_banner: Label
var _race_next_puzzle: SudokuGenerator.Puzzle
var _race_clock_flash: float = 0.0
var _race_clock_good: bool = true
var _race_danger_mix: float = 0.0
var _status_clock_tween: Tween
var _play_camera: Camera2D
var _mistake_flash: CanvasModulate
var _mistake_flash_tween: Tween
var _mistake_shake: float = 0.0
var _shake_time: float = MISTAKE_SHAKE_TIME
var _shake_reach: float = MISTAKE_SHAKE_PX
var _race_grid: int = SudokuGenerator.MINI_SIZE
var _after_levels: Callable = Callable()
var _tap_guard: Dictionary = {}
var _last_ui_click_ms: int = 0
var _click_voices: Array[AudioStreamPlayer] = []
var _clear_voices: Array[AudioStreamPlayer] = []
var _treasure_sting: AudioStreamPlayer
var _overheat_sting: AudioStreamPlayer
var _relic_sting: AudioStreamPlayer
var _cyber_sting: AudioStreamPlayer
var _algae_sting: AudioStreamPlayer
var _algae_tap_sting: AudioStreamPlayer
var _leaf_sting: AudioStreamPlayer
var _click_cursor: int = 0
var _clear_cursor: int = 0


func _ready() -> void:
	_ensure_home_journey_links()
	_ensure_relic_tray()
	_ensure_home_quit_button()
	_ensure_journey_map()
	_ensure_shop_screen()
	_load_high_scores()
	_merge_race_high_scores()
	_load_journey_progress()
	_load_prefs()
	_refresh_journey_buttons()
	_refresh_streak_label()
	_main_menu.modulate.a = 0.0
	_start_logo_float()
	_arm_tap(_journey_button, _on_journey_button_pressed)
	_arm_tap(_home_new_button, _on_new_journey_pressed)
	_arm_tap(_home_worlds_button, _on_home_worlds_pressed)
	_arm_tap(_quick_play_button, _on_quick_play_pressed)
	_arm_tap(_race_mode_button, _on_race_mode_pressed)
	_arm_tap(_home_quit_button, _on_quit_pressed)
	_arm_tap(_streak_button, _on_home_profile_pressed.bind(_streak_button))
	_arm_tap(_profile_button, _on_home_profile_pressed.bind(_profile_button))
	_arm_tap(_board_button, _on_board_pressed)
	_arm_tap(_profile_worlds_button, _on_worlds_pressed)
	_arm_tap(_profile_back_button, _on_profile_back_pressed)
	_arm_tap(_board_back_button, _on_board_back_pressed)
	_arm_tap(_race_mini_button, _on_race_play_pressed)
	_arm_tap(_race_back_button, _on_race_back_pressed)
	_prepare_race_menu()
	_arm_tap(_continue_button, _on_continue_journey_pressed)
	_arm_tap(_new_journey_button, _on_new_journey_pressed)
	_arm_tap(_standard_pace_button, _set_journey_pace.bind(JourneyPace.STANDARD))
	_arm_tap(_relaxed_pace_button, _set_journey_pace.bind(JourneyPace.RELAXED))
	_arm_tap(_journey_back_button, _on_journey_back_pressed)
	_arm_tap(_levels_button, _on_worlds_pressed)
	_arm_tap(_levels_back_button, _on_back_pressed)
	_arm_tap(_difficulty_back_button, _on_difficulty_back_pressed)
	_arm_tap(_easy_button, _on_difficulty_button_pressed.bind(Difficulty.EASY))
	_arm_tap(_medium_button, _on_difficulty_button_pressed.bind(Difficulty.MEDIUM))
	_arm_tap(_hard_button, _on_difficulty_button_pressed.bind(Difficulty.HARD))
	_arm_tap(_quit_button, _on_quit_pressed)
	_arm_tap(_settings_button, _on_settings_button_pressed)
	_arm_tap(_settings_back_button, _on_settings_back_pressed)
	_arm_tap(_night_button, _toggle_night)
	_arm_tap(_buzz_button, _toggle_buzz)
	_arm_tap(_check_button, _toggle_check)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_music_slider.drag_ended.connect(_on_music_drag_ended)
	_sounds_slider.value_changed.connect(_on_sounds_volume_changed)
	_sounds_slider.drag_ended.connect(_on_sounds_drag_ended)
	_prepare_slider(_music_slider)
	_prepare_slider(_sounds_slider)
	_sync_audio_sliders()
	_arm_tap(_menu_button, _on_menu_pressed)
	_arm_tap(_new_button, _on_new_pressed)
	_arm_tap(_yes_button, _on_win_continue)
	_arm_tap(_no_button, _on_leave_game)
	_arm_tap(_notes_button, _toggle_notes)
	_arm_tap(_undo_button, _board.undo)
	_arm_tap(_hint_button, _on_hint_pressed)
	_build_level_list()
	_board.solved.connect(_on_board_solved)
	_board.progress_changed.connect(_on_progress_changed)
	_board.digits_changed.connect(_refresh_digit_pad)
	_board.score_changed.connect(_on_score_changed)
	_board.unit_cleared.connect(_play_completion_sound)
	_board.correct_placed.connect(_on_correct_placed)
	_board.mistake_made.connect(_on_mistake_made)
	_board.aegis_spent.connect(_on_aegis_spent)
	_board.seal_target.connect(_on_seal_target)
	_board.poison_solved.connect(_on_poison_solved)
	_board.sand_cache_solved.connect(_on_sand_cache_solved)
	_board.ember_overheated.connect(_on_ember_overheated)
	_board.cyber_unlocked.connect(_on_cyber_unlocked)
	_board.algae_tapped.connect(_on_algae_tapped)
	_board.algae_splashed.connect(_on_algae_splashed)
	_board.combo_cleared.connect(_on_combo_cleared)
	_board.notes_mode_changed.connect(_on_notes_mode_changed)
	_board.undo_availability_changed.connect(_on_undo_availability_changed)
	_build_number_pad()
	_apply_style_chrome()
	_refresh_hint_button()
	_on_notes_mode_changed(false)
	_apply_night_mode(false)
	_sync_night_buttons()
	_apply_haptics()
	_sync_buzz_button()
	_apply_check()
	_sync_check_button()
	_ambience.finished.connect(_on_ambience_finished)
	_setup_completion_audio()
	_setup_click_audio()
	_setup_mechanic_audio()
	_setup_menu_audio()
	_setup_win_audio()
	_menu.finished.connect(_on_menu_music_finished)
	_hook_ui_clicks(self)
	if _background.material != null:
		_background.material = _background.material.duplicate()
	if _win_bloom.material != null:
		_win_bloom.material = _win_bloom.material.duplicate()
	_ensure_mistake_fx()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_set_board_active(false)
	_transitioning = true
	await _enter_menu()
	_transitioning = false


## On Android the hardware/gesture back button steps back one screen instead of
## closing the app outright. Pausing or closing also writes the open puzzle.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if what == NOTIFICATION_APPLICATION_PAUSED:
			_hold_play_timer()
		_flush_save_run()
		_save_prefs()
		return
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_release_play_timer()
		return
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_node_ready() or _transitioning or _dealing:
		return
	if _shop_waiting and is_instance_valid(_shop_screen) and _shop_screen.visible:
		_on_shop_skipped()
		return
	if _game_screen.visible or _win_screen.visible:
		_on_leave_game()
	elif _journey_menu.visible:
		_on_journey_back_pressed()
	elif _settings_menu.visible:
		_on_settings_back_pressed()
	elif _profile_menu.visible:
		_on_profile_back_pressed()
	elif _board_menu.visible:
		_on_board_back_pressed()
	elif _difficulty_menu.visible:
		_on_difficulty_back_pressed()
	elif _race_menu.visible:
		_on_race_back_pressed()
	elif _levels_menu.visible:
		_on_back_pressed()
	else:
		get_tree().quit()


## Keeps the top bar clear of notches, punch holes and rounded corners.
func _apply_safe_area() -> void:
	var left: int = BASE_MARGIN
	var top: int = BASE_MARGIN
	var right: int = BASE_MARGIN
	var bottom: int = BASE_MARGIN
	if OS.has_feature("mobile"):
		var window_size: Vector2i = DisplayServer.window_get_size()
		var safe_area: Rect2i = DisplayServer.get_display_safe_area()
		if window_size.x > 0 and window_size.y > 0 and safe_area.size.x > 0:
			# The safe area is in screen pixels, the UI is in stretched viewport units.
			var viewport_size: Vector2 = get_viewport_rect().size
			var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
			left += int(maxi(safe_area.position.x, 0) * scale.x)
			top += int(maxi(safe_area.position.y, 0) * scale.y)
			right += int(maxi(window_size.x - safe_area.end.x, 0) * scale.x)
			bottom += int(maxi(window_size.y - safe_area.end.y, 0) * scale.y)
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web"):
		top = maxi(top, BASE_MARGIN + 8)
		bottom = maxi(bottom, BASE_MARGIN + TOUCH_BOTTOM_INSET)
	_game_margin.add_theme_constant_override("margin_left", left)
	_game_margin.add_theme_constant_override("margin_top", top)
	_game_margin.add_theme_constant_override("margin_right", right)
	_game_margin.add_theme_constant_override("margin_bottom", bottom)
	var screens: Array[Control] = [
		_main_menu, _journey_menu, _levels_menu, _difficulty_menu, _race_menu, _settings_menu, _profile_menu, _board_menu, _win_screen
	]
	if is_instance_valid(_shop_screen):
		screens.append(_shop_screen)
	_center_play_camera()
	for screen in screens:
		_pin_full_rect(screen)
	_inset_home(left, top, right, bottom)
	call_deferred("_place_tool_dock")


func _pin_full_rect(screen: Control) -> void:
	if not is_instance_valid(screen):
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 8.0 or view.y < 8.0:
		view = Vector2(720.0, 1280.0)
	# Position layout so a zero-size parent cannot collapse the overlay.
	screen.set("layout_mode", 0)
	screen.anchor_left = 0.0
	screen.anchor_top = 0.0
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	screen.position = Vector2.ZERO
	screen.size = view


func _inset_home(left: int, top: int, right: int, bottom: int) -> void:
	if not is_instance_valid(_main_menu):
		return
	var view: Vector2 = _main_menu.size
	if view.x < 8.0 or view.y < 8.0:
		view = Vector2(720.0, 1280.0)
	var header: Control = _main_menu.get_node_or_null("Header") as Control
	var body: Control = _main_menu.get_node_or_null("Body") as Control
	var footer: Control = _main_menu.get_node_or_null("Footer") as Control
	var col_w: float = 440.0
	var extra: float = 0.0
	if is_instance_valid(_journey_links) and _journey_links.visible:
		extra = 56.0
	var body_h: float = 340.0 + extra
	var foot_h: float = 128.0
	if header != null:
		header.set("layout_mode", 0)
		header.position = Vector2(float(left), float(top))
		header.size = Vector2(maxi(view.x - float(left + right), col_w), 380.0)
		_place_home_logo(header)
	if body != null:
		body.set("layout_mode", 0)
		body.size = Vector2(col_w, body_h)
		var body_y: float = clampf(view.y * 0.42, 280.0, view.y - body_h - foot_h - float(bottom))
		body.position = Vector2((view.x - col_w) * 0.5, body_y)
	if footer != null:
		footer.set("layout_mode", 0)
		footer.position = Vector2(float(left), view.y - foot_h - float(bottom))
		footer.size = Vector2(maxi(view.x - float(left + right), 200.0), foot_h)
		footer.add_theme_constant_override("margin_left", 36)
		footer.add_theme_constant_override("margin_right", 36)
		footer.add_theme_constant_override("margin_bottom", 8)


func _place_home_logo(header: Control) -> void:
	var slot: Control = header.get_node_or_null("LogoSlot") as Control
	var streak: Control = header.get_node_or_null("Streak") as Control
	var quit_btn: Control = header.get_node_or_null("Quit") as Control
	var slot_w: float = 400.0
	var slot_h: float = 208.0
	if slot != null:
		slot.set("layout_mode", 0)
		slot.size = Vector2(slot_w, slot_h)
		slot.position = Vector2((header.size.x - slot_w) * 0.5, 148.0)
	if quit_btn != null:
		quit_btn.set("layout_mode", 0)
		quit_btn.size = Vector2(96.0, 96.0)
		quit_btn.position = Vector2(8.0, 8.0)
	if streak != null:
		streak.set("layout_mode", 0)
		streak.size = Vector2(112.0, 72.0)
		streak.position = Vector2(header.size.x - 120.0, 8.0)
	if is_instance_valid(_logo_float):
		_logo_float.set("layout_mode", 0)
		_logo_float.size = Vector2(slot_w, slot_h)
		_logo_float.position.x = 0.0


func _process(delta: float) -> void:
	_stage_clock += delta
	_apply_stage_mood()
	_tick_mistake_shake(delta)
	if not _timer_running:
		return
	if _mode == Mode.MINI:
		_tick_mini_race(delta)
		return
	var previous_seconds: int = int(_elapsed_seconds)
	_elapsed_seconds += delta
	if int(_elapsed_seconds) != previous_seconds:
		_update_status()
		if int(_elapsed_seconds) % 10 == 0:
			_flush_save_run()


func _tick_mini_race(delta: float) -> void:
	var previous_shown: int = int(_race.seconds)
	_elapsed_seconds += delta
	_race.process_clock(delta)
	_sync_race_clock()
	if _race_clock_flash > 0.0:
		_race_clock_flash = maxf(0.0, _race_clock_flash - delta * 2.6)
		_update_status()
	elif int(_race.seconds) != previous_shown:
		_update_status()
	_apply_race_danger_fx(delta)
	if not _race.alive or _race.seconds <= 0.0:
		_on_mini_times_up()


func _on_aegis_spent() -> void:
	_relics.aegis_ready = false
	_queue_save_run()


func _on_mistake_made(index: int, life_cost: int = 1) -> void:
	_punch_mistake()
	_puzzle_mistakes += 1
	var cost: int = maxi(1, life_cost)
	if cost > 1:
		_flash_poison_screen()
	if _mode == Mode.JOURNEY and not _dealing and not _journey_failed:
		var lost: int = _relics.on_mistake(cost)
		if _relics.last_guard == RelicManager.Guard.SECOND_WIND:
			_board.spawn_caption("SAFE", index)
		elif _relics.last_guard == RelicManager.Guard.PHOENIX:
			_board.undo()
			_puzzle_mistakes = maxi(0, _puzzle_mistakes - 1)
			_board.spawn_caption("PHOENIX", index)
		elif lost > 0:
			_board.spawn_clock_pop(-lost, index)
		_update_status()
		_queue_save_run()
		if _relics.lives <= 0:
			_on_journey_failed()
			return
	if _mode != Mode.MINI or _mini_chaining or _race_ending or _dealing:
		return
	_race.on_wrong_move()
	_sync_race_clock()
	_board.spawn_clock_pop(-int(RaceModeManager.MISTAKE_PENALTY), index)
	_punch_race_clock(false)
	if not _race.alive or _race.seconds <= 0.0:
		_on_mini_times_up()


func _on_poison_solved(index: int) -> void:
	_play_sting(_leaf_sting)
	if _mode != Mode.JOURNEY:
		return
	var amount: int = _economy.vine_bounty()
	if amount <= 0:
		return
	_board.spawn_gold_pop(amount, index)


func _on_sand_cache_solved(index: int) -> void:
	_play_sting(_treasure_sting)
	if _mode != Mode.JOURNEY:
		return
	var amount: int = _economy.sand_bounty()
	if amount <= 0:
		return
	_board.spawn_gold_pop(amount, index)


func _on_ember_overheated() -> void:
	if _dealing or _journey_failed or _mode == Mode.MINI:
		return
	_play_sting(_overheat_sting)
	var relaxed: bool = _mode == Mode.JOURNEY and _journey_pace == JourneyPace.RELAXED
	if not _ember_warned:
		_ember_warned = true
		_board.spawn_caption("WARNING")
		_queue_save_run()
		return
	_puzzle_mistakes += 1
	if _mode == Mode.JOURNEY and not relaxed:
		var lost: int = _relics.on_mistake(1)
		var note := ""
		if _relics.last_guard == RelicManager.Guard.SECOND_WIND:
			note = "SAFE"
		elif _relics.last_guard == RelicManager.Guard.PHOENIX:
			note = "PHOENIX"
		elif lost > 0:
			note = "−1 LIFE"
		_begin_overheat(note)
		_update_status()
		_queue_save_run()
		if _relics.lives <= 0:
			_on_journey_failed()
		return
	var score_lost: int = _board.apply_score_penalty(OVERHEAT_SCORE_COST)
	_begin_overheat("−%d" % score_lost if score_lost > 0 else "")
	_update_status()
	_queue_save_run()


func _begin_overheat(note: String) -> void:
	_punch_overheat()
	if not is_instance_valid(_ember_rush):
		var rush := EmberRush.new()
		rush.name = "EmberRush"
		rush.z_index = 90
		_game_screen.add_child(rush)
		rush.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ember_rush = rush
	_ember_rush.play(note)


func _on_combo_cleared(unit_count: int, _gained: int) -> void:
	if _mode != Mode.MINI or _mini_chaining or _race_ending or _dealing:
		return
	var bonus: float = _race_combo_seconds(unit_count)
	if bonus <= 0.0:
		return
	_race.add_seconds(bonus)
	_sync_race_clock()
	_board.spawn_clock_pop(int(bonus), _board.last_place_index)
	_punch_race_clock(true)


func _race_combo_seconds(unit_count: int) -> float:
	if unit_count < 2:
		return 0.0
	var step: float = 4.0 if _race_grid == SudokuGenerator.WIDE_SIZE else 3.0
	return step * float(unit_count - 1)


func _punch_race_clock(good: bool) -> void:
	_race_clock_good = good
	_race_clock_flash = 1.0
	_update_status()
	if _status_clock_tween != null and is_instance_valid(_status_clock_tween):
		_status_clock_tween.kill()
	_status_label.pivot_offset = _status_label.size * 0.5
	_status_label.scale = Vector2(1.18, 1.18)
	_status_clock_tween = create_tween()
	_status_clock_tween.tween_property(_status_label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_race_danger_fx(delta: float) -> void:
	var want: float = 1.0 if _race.danger_mode_active else 0.0
	var speed: float = 8.0 if want > _race_danger_mix else 3.2
	_race_danger_mix = move_toward(_race_danger_mix, want, delta * speed)
	_status_label.pivot_offset = _status_label.size * 0.5
	var punching: bool = _status_clock_tween != null and is_instance_valid(_status_clock_tween) and _status_clock_tween.is_running()
	if _race_danger_mix <= 0.001:
		_race_danger_mix = 0.0
		if not punching:
			_status_label.scale = Vector2.ONE
		if _race_clock_flash <= 0.04:
			_status_label.add_theme_color_override("font_color", _chrome.ink)
		return
	var beat: float = (sin(float(Time.get_ticks_msec()) * 0.012) + 1.0) * 0.5
	if not punching:
		var pulse: float = 1.0 + _race_danger_mix * lerpf(0.04, 0.13, beat)
		_status_label.scale = Vector2(pulse, pulse)
	if _race_clock_flash > 0.04:
		return
	var red := Color(1.0, 0.16, 0.14)
	var heat: float = _race_danger_mix * lerpf(0.42, 1.0, beat)
	_status_label.add_theme_color_override("font_color", _chrome.ink.lerp(red, heat))


func _ensure_mistake_fx() -> void:
	if not is_instance_valid(_play_camera):
		var camera := Camera2D.new()
		camera.name = "MistakeCamera"
		camera.enabled = true
		camera.top_level = true
		camera.position_smoothing_enabled = false
		camera.zoom = Vector2.ONE
		add_child(camera)
		_play_camera = camera
		_play_camera.make_current()
	if not is_instance_valid(_mistake_flash):
		var flash := CanvasModulate.new()
		flash.name = "MistakeFlash"
		flash.color = Color.WHITE
		add_child(flash)
		_mistake_flash = flash
	_center_play_camera()


func _center_play_camera() -> void:
	if not is_instance_valid(_play_camera):
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 8.0 or view.y < 8.0:
		view = Vector2(720.0, 1280.0)
	_play_camera.position = view * 0.5
	if _mistake_shake <= 0.0:
		_play_camera.offset = Vector2.ZERO


func _punch_mistake() -> void:
	_ensure_mistake_fx()
	_shake_time = MISTAKE_SHAKE_TIME
	_shake_reach = MISTAKE_SHAKE_PX
	_mistake_shake = 1.0
	if _mistake_flash_tween != null and _mistake_flash_tween.is_valid():
		_mistake_flash_tween.kill()
	_mistake_flash.color = LAVA_RED
	_mistake_flash_tween = create_tween()
	_mistake_flash_tween.tween_interval(MISTAKE_FLASH_HOLD)
	_mistake_flash_tween.tween_property(_mistake_flash, "color", Color.WHITE, MISTAKE_FLASH_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _punch_overheat() -> void:
	_ensure_mistake_fx()
	_shake_time = OVERHEAT_SHAKE_TIME
	_shake_reach = OVERHEAT_SHAKE_PX
	_mistake_shake = 1.0


func _tick_mistake_shake(delta: float) -> void:
	if not is_instance_valid(_play_camera) or _mistake_shake <= 0.0:
		return
	_mistake_shake = maxf(0.0, _mistake_shake - delta / _shake_time)
	_center_play_camera()
	if _mistake_shake <= 0.0:
		_play_camera.offset = Vector2.ZERO
		return
	var falloff: float = _mistake_shake * _mistake_shake
	var ticks: float = float(Time.get_ticks_msec())
	var kick := Vector2(sin(ticks * 0.09), cos(ticks * 0.13))
	_play_camera.offset = kick * (_shake_reach * falloff)


func _reset_mistake_fx() -> void:
	_mistake_shake = 0.0
	_shake_time = MISTAKE_SHAKE_TIME
	_shake_reach = MISTAKE_SHAKE_PX
	if _mistake_flash_tween != null and _mistake_flash_tween.is_valid():
		_mistake_flash_tween.kill()
	_mistake_flash_tween = null
	if is_instance_valid(_mistake_flash):
		_mistake_flash.color = Color.WHITE
	if is_instance_valid(_play_camera):
		_play_camera.offset = Vector2.ZERO


func _reset_race_danger_fx() -> void:
	_race_danger_mix = 0.0
	if _status_clock_tween != null and is_instance_valid(_status_clock_tween):
		_status_clock_tween.kill()
	_status_clock_tween = null
	_status_label.scale = Vector2.ONE
	_status_label.add_theme_color_override("font_color", _chrome.ink)


## Deals a puzzle for the current journey stage or the picked world.
## `resume` reloads the saved board when one matches this slot.
func start_new_game(resume: bool = false) -> void:
	if _dealing:
		return
	_dealing = true
	_reset_new_confirm()
	if not (_mode == Mode.MINI and _mini_chaining):
		_kill_race_chain_motion()
	_board.loud_pops = _mode == Mode.MINI
	_set_board_active(true)
	_round += 1
	if _mode == Mode.MINI and not _mini_chaining:
		_race.reset()
		_sync_race_clock()
		_reset_race_danger_fx()
	_board.configure_grid(_race.grid_size if _mode == Mode.MINI else SudokuGenerator.CLASSIC_SIZE)
	_sync_number_pad()
	var style: SudokuBoard.ArtStyle = SudokuBoard.ArtStyle.NIGHT
	var look: WorldLook
	if _mode == Mode.JOURNEY:
		_difficulty = _difficulty_for_level(_journey_level)
		look = _journey_look(_journey_level)
		style = look.style as SudokuBoard.ArtStyle
	else:
		look = _world_at(_world_index)
		style = look.style as SudokuBoard.ArtStyle
	_board.set_art_style(style)
	if look != null:
		_board.apply_world_look(look)
	_apply_style_chrome()
	_stop_menu_music()
	_stop_win_sound()
	_play_world_ambience()
	_last_session = _session_name()
	_timer_running = false
	_main_menu.visible = false
	_levels_menu.visible = false
	_difficulty_menu.visible = false
	_race_menu.visible = false
	_journey_menu.visible = false
	_settings_menu.visible = false
	_profile_menu.visible = false
	_board_menu.visible = false
	_dismiss_win()
	_game_screen.visible = true
	_hide_shop_screen()
	if _mode == Mode.MINI and _mini_chaining:
		_update_status()
	else:
		_status_label.text = "Generating..."
	_board.notes_mode = false
	_set_play_chrome_locked(true)
	_set_input_enabled(false)
	# Let the "Generating..." label reach the screen before we block on the solver.
	await get_tree().process_frame
	if not is_instance_valid(self) or not _dealing:
		return
	if resume and _mode != Mode.MINI and _try_restore_run():
		_apply_run_relics(false)
		if _uses_sand_caches() and _board.sand_cache_indices().is_empty():
			_board.seed_sand_caches(_sand_cache_count())
		_apply_poison_bounty()
		_apply_sand_bounty()
		_apply_ember_pressure(false)
		_flush_save_run()
		_timer_running = true
		_set_play_chrome_locked(false)
		_set_input_enabled(true)
		_refresh_hint_button()
		_update_status()
		_dealing = false
		return
	if not resume:
		_clear_run()
	if _mode != Mode.MINI or not _mini_chaining:
		_elapsed_seconds = 0.0
	if _mode == Mode.MINI and not _mini_chaining:
		_sync_race_clock()
		_mini_clears = 0
		_mini_race_score = 0
		_race_ending = false
	var blanks: int = _blanks_for_current()
	var puzzle: SudokuGenerator.Puzzle
	if _mode == Mode.MINI:
		puzzle = SudokuGenerator.generate(blanks, _board.grid_size, RACE_SEARCH_BUDGET)
	else:
		puzzle = SudokuGenerator.generate(blanks, _board.grid_size)
	_board.load_puzzle(puzzle)
	_board.set_mood_sources(_difficulty, _remaining_cells, blanks, true)
	_hints_left = _hints_budget()
	_puzzle_hints_used = 0
	_puzzle_seals_used = 0
	_puzzle_mistakes = 0
	_armed_tool = -1
	_journey_failed = false
	_last_gold_paid = 0
	_last_gold_vines = 0
	_last_gold_sand = 0
	_last_gold_stars = 0
	_apply_run_relics(true)
	if _mode == Mode.JOURNEY:
		_hints_left += _relics.take_pending_hints()
		_refresh_hint_button()
	if _uses_algae():
		_board.seed_algae(SudokuBoard.ALGAE_COVER)
	if _uses_sand_caches():
		_board.seed_sand_caches(_sand_cache_count())
	if _uses_poison():
		_board.seed_poison()
	if _uses_cyber_locks():
		_board.seed_cyber_locks(_cyber_lock_count())
	_apply_poison_bounty()
	_apply_sand_bounty()
	_apply_ember_pressure(true)
	_flush_save_run()
	_timer_running = true
	_refresh_hint_button()
	_update_status()
	if _mode == Mode.MINI and _mini_chaining:
		_set_play_chrome_locked(true)
		_set_input_enabled(false)
		_dealing = false
		return
	_set_play_chrome_locked(false)
	_set_input_enabled(true)
	_dealing = false
	if _mode == Mode.MINI and _race.seconds <= 0.0:
		_on_mini_times_up()
		return
	if _mode == Mode.JOURNEY and _board.is_cleared():
		_on_board_solved()


func _build_number_pad() -> void:
	for child in _number_pad.get_children():
		_number_pad.remove_child(child)
		child.free()
	_digit_buttons.clear()
	_digit_remain_labels.clear()
	_erase_button = null
	var digits: int = _board.grid_size
	_number_pad.columns = _pad_columns()
	for digit in range(1, digits + 1):
		var button := Button.new()
		button.text = str(digit)
		button.custom_minimum_size = Vector2(0.0, 112.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 42)
		_arm_tap(button, _board.write_digit.bind(digit))
		button.button_down.connect(_pulse_in_game_button.bind(button))
		var remain := Label.new()
		remain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		remain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		remain.offset_left = 8.0
		remain.offset_top = 6.0
		remain.offset_right = -10.0
		remain.offset_bottom = -8.0
		remain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		remain.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		remain.add_theme_font_size_override("font_size", 18)
		button.add_child(remain)
		_number_pad.add_child(button)
		_digit_buttons.append(button)
		_digit_remain_labels.append(remain)
	var erase_button := Button.new()
	erase_button.text = "Erase"
	erase_button.custom_minimum_size = Vector2(0.0, 112.0)
	erase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	erase_button.add_theme_font_size_override("font_size", 24)
	_arm_tap(erase_button, _board.write_digit.bind(0))
	erase_button.button_down.connect(_pulse_in_game_button.bind(erase_button))
	_number_pad.add_child(erase_button)
	_erase_button = erase_button


func _sync_number_pad() -> void:
	if _digit_buttons.size() == _board.grid_size and is_instance_valid(_erase_button):
		_number_pad.columns = _pad_columns()
		return
	_build_number_pad()


func _pad_columns() -> int:
	if _board.grid_size == SudokuGenerator.WIDE_SIZE:
		return 4
	return 5


func _set_input_enabled(enabled: bool) -> void:
	_pad_enabled = enabled
	_board.set_play_enabled(enabled)
	if _erase_button != null:
		_erase_button.disabled = not enabled
	_notes_button.disabled = not enabled
	# Undo additionally needs something in the history to step back to.
	_undo_button.disabled = not (enabled and _board.can_undo())
	_refresh_digit_pad()
	_refresh_hint_button()
	if not enabled:
		_armed_tool = -1
		_board.seal_aim = -1
	_refresh_tool_bar()


func _on_undo_availability_changed(can_undo: bool) -> void:
	_undo_button.disabled = not (_pad_enabled and can_undo)


func _toggle_notes() -> void:
	if _dealing or _win_screen.visible or _notes_button.disabled:
		return
	_board.notes_mode = not _board.notes_mode


## Keeps the label in step with the board, which can also flip from the N key.
func _on_notes_mode_changed(enabled: bool) -> void:
	if not _dealing:
		_reset_new_confirm()
	_notes_button.text = "Notes · On" if enabled else "Notes"
	_paint_chrome_button(_notes_button, false, enabled, false)
	_queue_save_run()


func _on_quick_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_main_menu, _quick_play_button)
	_pick_quick_play()
	_mode = Mode.QUICK
	_arm_game()
	await start_new_game(false)
	await _settle_game()
	_transitioning = false


func _pick_quick_play() -> void:
	if worlds.is_empty():
		_world_index = 0
		_difficulty = Difficulty.EASY
		return
	var previous_world: int = _world_index
	var previous_difficulty: int = int(_difficulty)
	for _attempt in 8:
		var index: int = randi() % worlds.size()
		if worlds[index] == null:
			continue
		var difficulty: Difficulty = (randi() % 3) as Difficulty
		if index == previous_world and int(difficulty) == previous_difficulty:
			continue
		_world_index = index
		_difficulty = difficulty
		return
	_world_index = clampi(_world_index, 0, worlds.size() - 1)
	if worlds[_world_index] == null:
		_world_index = 0
	_difficulty = (randi() % 3) as Difficulty


func _pick_race_world() -> void:
	if worlds.is_empty():
		_world_index = 0
		return
	var previous_world: int = _world_index
	for _attempt in 8:
		var index: int = randi() % worlds.size()
		if worlds[index] == null:
			continue
		if index == previous_world and worlds.size() > 1:
			continue
		_world_index = index
		return
	_world_index = clampi(_world_index, 0, worlds.size() - 1)
	if worlds[_world_index] == null:
		_world_index = 0


func _mini_race_difficulty() -> Difficulty:
	if _race_grid == SudokuGenerator.WIDE_SIZE:
		if _mini_clears < 2:
			return Difficulty.EASY
		if _mini_clears < 4:
			return Difficulty.MEDIUM
		return Difficulty.HARD
	if _mini_clears < 2:
		return Difficulty.EASY
	if _mini_clears < 5:
		return Difficulty.MEDIUM
	return Difficulty.HARD


func _on_race_mode_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_main_menu, _race_mode_button)
	await _enter_race()
	_transitioning = false


func _on_race_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_race_menu, _race_back_button)
	await _enter_menu()
	_transitioning = false


func _on_race_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_race_menu, _race_mini_button)
	_mini_chaining = false
	_race_ending = false
	_race.reset()
	_sync_race_clock()
	_reset_race_danger_fx()
	_mode = Mode.MINI
	_difficulty = Difficulty.EASY
	_pick_race_world()
	_arm_game()
	await start_new_game(false)
	_ensure_race_swap_fx()
	await _settle_game()
	_transitioning = false


func _on_journey_button_pressed() -> void:
	if _transitioning:
		return
	_clear_journey_confirm()
	_transitioning = true
	await _zoom_away(_main_menu, _journey_button)
	if not _journey_complete and _journey_progress >= 1:
		await _maybe_present_shop()
		_arm_game()
		await _start_journey(_journey_progress, true)
		await _settle_game()
	else:
		await _enter_journey()
	_transitioning = false


func _on_home_worlds_pressed() -> void:
	if _transitioning or not is_instance_valid(_home_worlds_button):
		return
	_clear_journey_confirm()
	_transitioning = true
	_after_levels = _enter_menu
	await _zoom_away(_main_menu, _home_worlds_button)
	await _enter_levels()
	_transitioning = false


func _ensure_home_journey_links() -> void:
	if is_instance_valid(_journey_links) and is_instance_valid(_home_new_button) and is_instance_valid(_home_worlds_button):
		return
	if not is_instance_valid(_main_menu) or not is_instance_valid(_journey_button):
		return
	var body: VBoxContainer = _main_menu.get_node_or_null("Body") as VBoxContainer
	if body == null:
		return
	var cluster: VBoxContainer = body.get_node_or_null("JourneyCluster") as VBoxContainer
	if cluster == null:
		cluster = VBoxContainer.new()
		cluster.name = "JourneyCluster"
		cluster.add_theme_constant_override("separation", 4)
		var index: int = _journey_button.get_index()
		var old_parent: Node = _journey_button.get_parent()
		old_parent.remove_child(_journey_button)
		cluster.add_child(_journey_button)
		body.add_child(cluster)
		body.move_child(cluster, mini(index, body.get_child_count() - 1))
	if is_instance_valid(_journey_links) and is_instance_valid(_home_new_button) and is_instance_valid(_home_worlds_button):
		return
	var links := HBoxContainer.new()
	links.name = "JourneyLinks"
	links.custom_minimum_size = Vector2(440, 48)
	links.add_theme_constant_override("separation", 0)
	links.visible = false
	var new_game := _make_home_link("NewGame", "New Game")
	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.custom_minimum_size = Vector2(2, 22)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.color = Color(0.93, 0.78, 0.42, 0.28)
	var worlds := _make_home_link("Worlds", "Worlds")
	links.add_child(new_game)
	links.add_child(rule)
	links.add_child(worlds)
	cluster.add_child(links)
	_journey_links = links
	_home_new_button = new_game
	_home_worlds_button = worlds


func _make_home_link(node_name: String, caption: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = &"FooterButton"
	button.add_theme_color_override("font_color", Color(0.93, 0.78, 0.42, 0.82))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.62, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.62, 0.32, 1.0))
	button.add_theme_font_size_override("font_size", 20)
	button.text = caption
	return button


func _ensure_home_quit_button() -> void:
	if is_instance_valid(_home_quit_button):
		return
	var header: Control = _main_menu.get_node_or_null("Header") as Control
	if header == null:
		return
	var button := Button.new()
	button.name = "Quit"
	button.modulate = Color(1, 1, 1, 0.7)
	button.custom_minimum_size = Vector2(96, 96)
	button.theme_type_variation = &"FooterButton"
	var col := VBoxContainer.new()
	col.name = "Col"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	var icon := Control.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_script(load("res://scripts/footer_icon.gd"))
	icon.set("kind", 3)
	var caption := Label.new()
	caption.name = "Caption"
	caption.text = "Quit"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 15)
	col.add_child(icon)
	col.add_child(caption)
	button.add_child(col)
	header.add_child(button)
	button.position = Vector2(8.0, 8.0)
	button.size = Vector2(96.0, 96.0)
	_home_quit_button = button


func _on_worlds_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _profile_menu.visible:
		_after_levels = _enter_profile
	else:
		_after_levels = _enter_journey
	var from: Control = _profile_menu if _profile_menu.visible else _journey_menu
	var focus: Control = _profile_worlds_button if from == _profile_menu else _levels_button
	await _zoom_away(from, focus)
	await _enter_levels()
	_transitioning = false


func _on_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_levels_menu, _levels_back_button)
	if _after_levels.is_valid():
		await _after_levels.call()
	else:
		await _enter_journey()
	_transitioning = false


func _on_level_button_pressed(index: int) -> void:
	if _transitioning:
		return
	_transitioning = true
	_world_index = index
	await _zoom_away(_levels_menu, _level_list.get_child(index) as Control)
	await _enter_difficulty()
	_transitioning = false


func _on_difficulty_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_difficulty_menu, _difficulty_back_button)
	await _enter_levels()
	_transitioning = false


func _on_difficulty_button_pressed(difficulty: Difficulty) -> void:
	if _transitioning:
		return
	_transitioning = true
	var focus: Control = _easy_button
	if difficulty == Difficulty.MEDIUM:
		focus = _medium_button
	elif difficulty == Difficulty.HARD:
		focus = _hard_button
	await _zoom_away(_difficulty_menu, focus)
	_arm_game()
	await _on_level_pressed(_world_index, difficulty)
	await _settle_game()
	_transitioning = false


func _set_journey_pace(pace: JourneyPace) -> void:
	if _transitioning:
		return
	if _journey_pace == pace:
		return
	_clear_journey_confirm()
	_journey_pace = pace
	_refresh_journey_buttons()
	_save_journey_progress()


func _sync_pace_button() -> void:
	_paint_pace_choice(_standard_pace_button, _journey_pace == JourneyPace.STANDARD)
	_paint_pace_choice(_relaxed_pace_button, _journey_pace == JourneyPace.RELAXED)


func _paint_pace_choice(button: Button, selected: bool) -> void:
	var fill: Color = Color(0.22, 0.08, 0.32) if selected else Color(0.09, 0.04, 0.13)
	var border: Color = Color(0.96, 0.55, 1, 0.95) if selected else Color(0.72, 0.32, 0.9, 0.22)
	var ink: Color = Color(0.96, 0.55, 1) if selected else Color(0.66, 0.52, 0.78)
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2 if selected else 1)
	box.set_corner_radius_all(18)
	box.content_margin_left = 12.0
	box.content_margin_top = 10.0
	box.content_margin_right = 12.0
	box.content_margin_bottom = 10.0
	if selected:
		box.shadow_color = Color(0.9, 0.4, 1.0, 0.28)
		box.shadow_size = 8
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)


func _on_continue_journey_pressed() -> void:
	if _transitioning or _journey_complete or _journey_progress < 1:
		return
	_clear_journey_confirm()
	_transitioning = true
	await _zoom_away(_journey_menu, _continue_button)
	await _maybe_present_shop()
	_arm_game()
	await _start_journey(_journey_progress, true)
	await _settle_game()
	_transitioning = false


func _on_new_journey_pressed() -> void:
	if _transitioning:
		return
	var can_continue: bool = not _journey_complete and _journey_progress >= 1
	if can_continue and not _confirm_new_journey:
		_arm_journey_confirm()
		return
	_clear_journey_confirm()
	_transitioning = true
	if _main_menu.visible and is_instance_valid(_home_new_button):
		await _zoom_away(_main_menu, _home_new_button)
	else:
		await _zoom_away(_journey_menu, _new_journey_button)
	_clear_run_section(RUN_JOURNEY)
	_journey_run_score = 0
	_journey_complete = false
	_economy.reset()
	_relics.reset_run()
	_journey_failed = false
	_arm_game()
	await _start_journey(1, false)
	await _settle_game()
	_transitioning = false


func _on_journey_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_journey_menu, _journey_back_button)
	await _enter_menu()
	_transitioning = false


func _on_settings_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_main_menu, _settings_button)
	await _enter_settings()
	_transitioning = false


func _on_settings_back_pressed() -> void:
	if _transitioning:
		return
	_save_prefs()
	_transitioning = true
	await _zoom_away(_settings_menu, _settings_back_button)
	await _enter_menu()
	_transitioning = false


func _on_home_profile_pressed(focus: Control) -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_main_menu, focus)
	await _enter_profile()
	_transitioning = false


func _on_profile_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_profile_menu, _profile_back_button)
	await _enter_menu()
	_transitioning = false


func _on_board_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_main_menu, _board_button)
	await _enter_board()
	_transitioning = false


func _on_board_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _zoom_away(_board_menu, _board_back_button)
	await _enter_menu()
	_transitioning = false


func _start_journey(level: int, resume: bool = false) -> void:
	_mode = Mode.JOURNEY
	_journey_complete = false
	_journey_level = maxi(1, level)
	_journey_progress = _journey_level
	_save_journey_progress()
	await start_new_game(resume)


func _on_level_pressed(index: int, difficulty: Difficulty) -> void:
	_mode = Mode.LEVEL
	_world_index = index
	_difficulty = difficulty
	await start_new_game(true)


func _on_win_continue() -> void:
	if _transitioning:
		return
	if _journey_failed and _mode == Mode.JOURNEY:
		_transitioning = true
		_stop_win_motion()
		await _fade_away([_win_screen, _game_screen])
		_dismiss_win()
		_journey_failed = false
		_arm_game()
		await start_new_game(false)
		await _settle_game()
		_transitioning = false
		return
	if _is_journey_finale():
		await _on_leave_game()
		return
	_transitioning = true
	_stop_win_motion()
	await _fade_away([_win_screen, _game_screen])
	_dismiss_win()
	if _mode == Mode.JOURNEY:
		_journey_level += 1
		await _maybe_present_shop()
	elif _mode == Mode.QUICK:
		_pick_quick_play()
	elif _mode == Mode.MINI:
		_mini_chaining = false
		_race_ending = false
		_difficulty = Difficulty.EASY
		_pick_race_world()
	_arm_game()
	await start_new_game(false)
	await _settle_game()
	_transitioning = false


## In-game Menu returns to the hub for that mode.
func _on_menu_pressed() -> void:
	if _dealing:
		return
	if _mode == Mode.JOURNEY:
		await _exit_play(_enter_journey)
	elif _mode == Mode.QUICK:
		await _exit_play(_enter_menu)
	elif _mode == Mode.MINI:
		await _exit_play(_enter_race)
	else:
		await _exit_play(_enter_menu)


## Journey rest returns to the path. A picked world's Levels button returns to difficulty.
func _on_leave_game() -> void:
	if _dealing:
		return
	if _mode == Mode.LEVEL:
		await _exit_play(_enter_difficulty)
	elif _mode == Mode.QUICK:
		await _exit_play(_enter_menu)
	elif _mode == Mode.MINI:
		await _exit_play(_enter_race)
	else:
		await _exit_play(_enter_journey)


func _exit_play(next: Callable) -> void:
	if _transitioning or _dealing:
		return
	_transitioning = true
	_reset_new_confirm()
	_flush_save_run()
	_timer_running = false
	_timer_held = false
	_mini_chaining = false
	_race_ending = false
	_board.loud_pops = false
	_race_clock_flash = 0.0
	_reset_race_danger_fx()
	_reset_mistake_fx()
	_kill_race_chain_motion()
	_stop_ambience()
	_stop_win_sound()
	_stop_win_motion()
	await _fade_away([_win_screen, _game_screen])
	_dismiss_win()
	_set_board_active(false)
	_journey_failed = false
	await next.call()
	_transitioning = false


func _enter_menu() -> void:
	_timer_running = false
	_clear_journey_confirm()
	_ensure_menu_music()
	_refresh_journey_buttons()
	_refresh_streak_label()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_levels_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_race_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	_hide_shop_screen()
	_start_logo_float()
	await _reveal(_main_menu, _menu_items())


func _enter_journey() -> void:
	_timer_running = false
	_clear_journey_confirm()
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_levels_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_race_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	_hide_shop_screen()
	_refresh_journey_buttons()
	await _reveal(_journey_menu, _journey_items())


func _enter_levels() -> void:
	_timer_running = false
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_race_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	await _reveal(_levels_menu, _level_items())


func _enter_difficulty() -> void:
	_timer_running = false
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_levels_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_race_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	var look: WorldLook = _world_at(_world_index)
	_difficulty_title.text = look.title.to_upper()
	_difficulty_title.add_theme_color_override("font_color", look.ink)
	_easy_button.text = _difficulty_button_text(Difficulty.EASY)
	_medium_button.text = _difficulty_button_text(Difficulty.MEDIUM)
	_hard_button.text = _difficulty_button_text(Difficulty.HARD)
	await _reveal(_difficulty_menu, _difficulty_items())


func _enter_race() -> void:
	_timer_running = false
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_levels_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	await _reveal(_race_menu, _race_items())


func _enter_settings() -> void:
	_timer_running = false
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_levels_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_race_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	_sync_night_buttons()
	_sync_buzz_button()
	_sync_check_button()
	_sync_audio_sliders()
	_sync_settings_hint()
	await _reveal(_settings_menu, _settings_items())


func _enter_profile() -> void:
	_timer_running = false
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_levels_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_race_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_board_menu)
	_hide_reset(_win_screen)
	_refresh_profile()
	await _reveal(_profile_menu, _profile_items())


func _enter_board() -> void:
	_timer_running = false
	_ensure_menu_music()
	_dismiss_win()
	_hide_reset(_game_screen)
	_hide_reset(_main_menu)
	_hide_reset(_levels_menu)
	_hide_reset(_difficulty_menu)
	_hide_reset(_race_menu)
	_hide_reset(_journey_menu)
	_hide_reset(_settings_menu)
	_hide_reset(_profile_menu)
	_hide_reset(_win_screen)
	_refresh_leaderboard()
	await _reveal(_board_menu, _board_items())


## Grows toward the pressed control, lets the rest fall back, then dissolves.
func _zoom_away(screen: Control, focus: Control) -> void:
	focus.pivot_offset = focus.size * 0.5
	var center: Vector2 = focus.get_global_rect().get_center()
	screen.pivot_offset = screen.get_global_transform().affine_inverse() * center
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(focus, "modulate", Color(1.55, 1.55, 1.55), 0.16)
	tween.tween_property(screen, "modulate:a", 0.0, 0.4).set_delay(0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for item in _items_of(screen):
		if item == focus:
			continue
		tween.tween_property(item, "modulate:a", 0.28, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_reset_screen(screen)
	screen.visible = false


func _fade_away(screens: Array[Control]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var active: int = 0
	for screen in screens:
		if not screen.visible:
			continue
		active += 1
		screen.pivot_offset = screen.size * 0.5
		tween.tween_property(screen, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if active == 0:
		tween.kill()
		return
	await tween.finished
	for screen in screens:
		_reset_screen(screen)
		screen.visible = false


func _reveal(screen: Control, items: Array[Control]) -> void:
	_pin_full_rect(screen)
	_reset_screen(screen)
	screen.modulate.a = 0.0
	screen.scale = Vector2.ONE
	for item in items:
		item.modulate.a = 0.0
		item.scale = Vector2.ONE
	screen.visible = true
	_transitioning = false
	await get_tree().process_frame
	_pin_full_rect(screen)
	screen.pivot_offset = screen.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(screen, "modulate:a", 1.0, MOTION_REVEAL).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var delay: float = 0.05
	for item in items:
		tween.tween_property(item, "modulate:a", 1.0, 0.38).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		delay += MOTION_STAGGER
	await tween.finished


func _arm_game() -> void:
	_game_screen.scale = Vector2.ONE
	_game_screen.modulate.a = 0.0
	_game_screen.visible = true


func _settle_game() -> void:
	await get_tree().process_frame
	_game_screen.pivot_offset = _game_screen.size * 0.5
	_game_screen.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(_game_screen, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _race_chain_alive(round_id: int) -> bool:
	return is_instance_valid(self) and round_id == _round and _game_screen.visible and _mode == Mode.MINI and _mini_chaining


func _finish_race_chain(restore_play: bool = true) -> void:
	_mini_chaining = false
	_race_next_puzzle = null
	_kill_race_chain_motion()
	if restore_play and _game_screen.visible and _mode == Mode.MINI and not _race_ending:
		_set_play_chrome_locked(false)
		_set_input_enabled(true)
		_refresh_hint_button()


func _kill_race_chain_motion() -> void:
	if _race_chain_tween != null and is_instance_valid(_race_chain_tween):
		_race_chain_tween.kill()
	_race_chain_tween = null
	_board.modulate = Color.WHITE
	_board.scale = Vector2.ONE
	_board.set_fx_paused(false)
	if is_instance_valid(_race_flash):
		_race_flash.color.a = 0.0
	if is_instance_valid(_race_banner):
		_race_banner.modulate.a = 0.0


func _ensure_race_swap_fx() -> void:
	if not is_instance_valid(_race_flash):
		_race_flash = ColorRect.new()
		_race_flash.name = "RaceFlash"
		_race_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_race_flash.color = Color(1.0, 1.0, 1.0, 0.0)
		_race_flash.z_index = 20
		_board.add_child(_race_flash)
		_race_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if is_instance_valid(_race_banner):
		return
	_race_banner = Label.new()
	_race_banner.name = "RaceBanner"
	_race_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_race_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_race_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_race_banner.add_theme_font_size_override("font_size", 80)
	_race_banner.modulate.a = 0.0
	_race_banner.z_index = 21
	var font: Font = _status_label.get_theme_font("font")
	if font != null:
		_race_banner.add_theme_font_override("font", font)
	_board.add_child(_race_banner)
	_race_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _race_banner_copy() -> String:
	return "+%d" % int(_race.last_bonus)


func _deal_race_chain() -> void:
	_round += 1
	_board.notes_mode = false
	var look: WorldLook = _world_at(_world_index)
	if look != null:
		_board.set_art_style(look.style as SudokuBoard.ArtStyle)
		_board.apply_world_look(look)
	var puzzle: SudokuGenerator.Puzzle = _race_next_puzzle
	_race_next_puzzle = null
	if puzzle == null or puzzle.grid_size != _race.grid_size:
		puzzle = SudokuGenerator.generate(_blanks_for_current(), _race.grid_size, RACE_SEARCH_BUDGET)
	_board.load_puzzle(puzzle)
	_board.score = _mini_race_score
	_board.score_mult = 1.0
	_board.magnet_enabled = false
	_board.aegis_ready = false
	_puzzle_hints_used = 0
	_puzzle_seals_used = 0
	_puzzle_mistakes = 0
	_armed_tool = -1
	_board.seal_aim = -1
	_board.queue_redraw()
	_board.set_mood_sources(_difficulty, _remaining_cells, _blanks_for_current(), true)
	_hints_left = _hints_budget()
	_update_status()


func _stop_race_chain_tween() -> void:
	if _race_chain_tween != null and is_instance_valid(_race_chain_tween):
		_race_chain_tween.kill()
	_race_chain_tween = null


func _race_board_out() -> void:
	_ensure_race_swap_fx()
	_stop_race_chain_tween()
	_board.pivot_offset = _board.size * 0.5
	var glow: Color = _board.glow_color.lerp(Color.WHITE, 0.22)
	_race_flash.color = Color(glow.r, glow.g, glow.b, 0.0)
	_race_banner.text = _race_banner_copy()
	_race_banner.add_theme_color_override("font_color", Color.WHITE)
	_race_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.85))
	_race_banner.add_theme_constant_override("outline_size", 4)
	_race_banner.modulate.a = 0.0
	_race_chain_tween = create_tween()
	_race_chain_tween.set_parallel(true)
	_race_chain_tween.tween_property(_race_flash, "color:a", 0.94, MINI_CHAIN_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_race_chain_tween.tween_property(_race_banner, "modulate:a", 1.0, MINI_CHAIN_OUT * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_race_chain_tween.tween_property(_board, "scale", Vector2(0.92, 0.92), MINI_CHAIN_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _race_chain_tween.finished


func _race_board_in() -> void:
	_ensure_race_swap_fx()
	_stop_race_chain_tween()
	_board.pivot_offset = _board.size * 0.5
	_board.modulate = Color.WHITE
	_board.scale = Vector2(1.06, 1.06)
	var glow: Color = _board.glow_color.lerp(Color.WHITE, 0.18)
	_race_flash.color = Color(glow.r, glow.g, glow.b, 0.94)
	_race_banner.text = _race_banner_copy()
	_race_banner.add_theme_color_override("font_color", Color.WHITE)
	_race_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.85))
	_race_banner.add_theme_constant_override("outline_size", 4)
	_race_banner.modulate.a = 1.0
	_race_chain_tween = create_tween()
	_race_chain_tween.set_parallel(true)
	_race_chain_tween.tween_property(_board, "scale", Vector2.ONE, MINI_CHAIN_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_race_chain_tween.tween_property(_race_flash, "color:a", 0.0, MINI_CHAIN_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_race_chain_tween.tween_property(_race_banner, "modulate:a", 0.0, MINI_CHAIN_IN * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _race_chain_tween.finished
	_board.scale = Vector2.ONE
	if is_instance_valid(_race_flash):
		_race_flash.color.a = 0.0
	if is_instance_valid(_race_banner):
		_race_banner.modulate.a = 0.0


func _hide_reset(screen: Control) -> void:
	screen.visible = false
	_reset_screen(screen)


func _reset_screen(screen: Control) -> void:
	screen.modulate = Color.WHITE
	screen.scale = Vector2.ONE
	var items: Array[Control] = []
	if screen == _main_menu:
		items = _menu_items()
	elif screen == _levels_menu:
		items = _level_items()
	elif screen == _difficulty_menu:
		items = _difficulty_items()
	elif screen == _race_menu:
		items = _race_items()
	elif screen == _journey_menu:
		items = _journey_items()
	elif screen == _settings_menu:
		items = _settings_items()
	elif screen == _profile_menu:
		items = _profile_items()
	elif screen == _board_menu:
		items = _board_items()
	elif screen == _shop_screen:
		items = _shop_items()
	for item in items:
		item.modulate = Color.WHITE
		item.scale = Vector2.ONE


func _items_of(screen: Control) -> Array[Control]:
	if screen == _main_menu:
		return _menu_items()
	if screen == _levels_menu:
		return _level_items()
	if screen == _difficulty_menu:
		return _difficulty_items()
	if screen == _race_menu:
		return _race_items()
	if screen == _journey_menu:
		return _journey_items()
	if screen == _settings_menu:
		return _settings_items()
	if screen == _profile_menu:
		return _profile_items()
	if screen == _board_menu:
		return _board_items()
	if screen == _shop_screen:
		return _shop_items()
	var empty: Array[Control] = []
	return empty


func _menu_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_logo_float)
	if is_instance_valid(_home_quit_button):
		items.append(_home_quit_button)
	items.append(_streak_button)
	var cluster: Control = _main_menu.get_node_or_null("Body/JourneyCluster") as Control
	if cluster != null:
		items.append(cluster)
	else:
		items.append(_journey_button)
	if is_instance_valid(_journey_links) and _journey_links.visible and cluster == null:
		items.append(_journey_links)
	items.append(_quick_play_button)
	items.append(_race_mode_button)
	items.append(_settings_button)
	items.append(_profile_button)
	items.append(_board_button)
	return items


func _level_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_levels_menu.get_node("Center/VBox/Title") as Control)
	items.append(_levels_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_levels_menu.get_node("Center/VBox/RuleWrap") as Control)
	for child in _level_list.get_children():
		items.append(child as Control)
	items.append(_levels_back_button)
	return items


func _difficulty_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_difficulty_title)
	items.append(_difficulty_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_difficulty_menu.get_node("Center/VBox/RuleWrap") as Control)
	items.append(_easy_button)
	items.append(_medium_button)
	items.append(_hard_button)
	items.append(_difficulty_back_button)
	return items


func _race_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_race_menu.get_node("Center/VBox/Title") as Control)
	items.append(_race_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_race_menu.get_node("Center/VBox/RuleWrap") as Control)
	items.append(_race_mini_button)
	items.append(_race_back_button)
	return items


func _journey_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_journey_menu.get_node("Center/VBox/Title") as Control)
	items.append(_journey_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_journey_menu.get_node("Center/VBox/RuleWrap") as Control)
	if is_instance_valid(_journey_map):
		items.append(_journey_map)
	items.append(_continue_button)
	items.append(_new_journey_button)
	items.append(_levels_button)
	items.append(_journey_menu.get_node("Center/VBox/PaceLabel") as Control)
	items.append(_pace_row)
	items.append(_journey_back_button)
	return items


func _settings_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_settings_menu.get_node("Center/VBox/Title") as Control)
	items.append(_settings_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_settings_menu.get_node("Center/VBox/RuleWrap") as Control)
	items.append(_settings_menu.get_node("Center/VBox/FeelLabel") as Control)
	items.append(_night_button)
	items.append(_buzz_button)
	items.append(_check_button)
	items.append(_settings_menu.get_node("Center/VBox/SoundLabel") as Control)
	items.append(_music_block)
	items.append(_sounds_block)
	items.append(_quit_button)
	items.append(_settings_back_button)
	return items


func _profile_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_profile_menu.get_node("Center/VBox/Title") as Control)
	items.append(_profile_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_profile_menu.get_node("Center/VBox/RuleWrap") as Control)
	items.append(_profile_stats)
	items.append(_profile_worlds_button)
	items.append(_profile_back_button)
	return items


func _board_items() -> Array[Control]:
	var items: Array[Control] = []
	items.append(_board_menu.get_node("Center/VBox/Title") as Control)
	items.append(_board_menu.get_node("Center/VBox/Hint") as Control)
	items.append(_board_menu.get_node("Center/VBox/RuleWrap") as Control)
	items.append(_board_list)
	items.append(_board_back_button)
	return items


func _refresh_journey_buttons() -> void:
	var can_continue: bool = not _journey_complete and _journey_progress >= 1
	_continue_button.visible = true
	_continue_button.disabled = not can_continue
	_continue_button.modulate = Color.WHITE
	_continue_button.scale = Vector2.ONE
	_new_journey_button.modulate = Color.WHITE
	_new_journey_button.scale = Vector2.ONE
	if can_continue:
		var look: WorldLook = _journey_look(_journey_progress)
		_continue_button.text = "Continue · %s" % look.title
		_continue_button.add_theme_color_override("font_color", look.ink)
		_journey_hint.text = "%s · %s" % [look.title, DIFFICULTY_NAMES[_difficulty_for_level(_journey_progress)]]
		_journey_hint.add_theme_color_override("font_color", look.ink.lerp(Color(0.66, 0.52, 0.78), 0.45))
		if _confirm_new_journey:
			_new_journey_button.text = "Start over?"
			_new_journey_button.add_theme_color_override("font_color", Color(1.0, 0.45, 0.42))
			_journey_hint.text = "This ends the path you are on."
		else:
			_new_journey_button.text = "New Game"
			_new_journey_button.add_theme_color_override("font_color", Color(0.86, 0.9, 1.0))
	elif _journey_complete:
		_confirm_new_journey = false
		_continue_button.text = "Continue"
		_continue_button.add_theme_color_override("font_color", Color(0.66, 0.52, 0.78))
		_journey_hint.text = "The journey is finished.\nTake a rest."
		_journey_hint.add_theme_color_override("font_color", Color(0.66, 0.52, 0.78))
		_new_journey_button.text = "New Game"
		_new_journey_button.add_theme_color_override("font_color", Color(0.86, 0.9, 1.0))
	else:
		_confirm_new_journey = false
		_continue_button.text = "Continue"
		_continue_button.add_theme_color_override("font_color", Color(0.66, 0.52, 0.78))
		if _journey_pace == JourneyPace.RELAXED:
			_journey_hint.text = "A gentler path through every world.\nShop between worlds."
		else:
			_journey_hint.text = "A path through every world.\nShop between worlds."
		_journey_hint.add_theme_color_override("font_color", Color(0.66, 0.52, 0.78))
		_new_journey_button.text = "New Game"
		_new_journey_button.add_theme_color_override("font_color", Color(0.86, 0.9, 1.0))
	_rebuild_journey_map()
	_refresh_home_cta()
	_sync_pace_button()


func _ensure_journey_map() -> void:
	if not is_instance_valid(_journey_menu):
		return
	var vbox: VBoxContainer = _journey_menu.get_node_or_null("Center/VBox") as VBoxContainer
	if vbox == null:
		return
	_journey_map = vbox.get_node_or_null("Map") as VBoxContainer
	if _journey_map == null:
		_journey_map = VBoxContainer.new()
		_journey_map.name = "Map"
		_journey_map.custom_minimum_size = Vector2(440.0, 168.0)
		_journey_map.add_theme_constant_override("separation", 2)
		var rule: Node = vbox.get_node_or_null("RuleWrap")
		var insert_at: int = rule.get_index() + 1 if rule != null else 2
		vbox.add_child(_journey_map)
		vbox.move_child(_journey_map, mini(insert_at, vbox.get_child_count() - 1))
	var needed: int = maxi(1, worlds.size())
	while _journey_map.get_child_count() < needed:
		var row := Label.new()
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 18)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_journey_map.add_child(row)


func _rebuild_journey_map() -> void:
	_ensure_journey_map()
	if not is_instance_valid(_journey_map):
		return
	_ensure_star_slots()
	var count: int = mini(worlds.size(), _journey_map.get_child_count())
	for world_i in count:
		var row := _journey_map.get_child(world_i) as Label
		if row == null:
			continue
		var look: WorldLook = _world_at(world_i)
		var cells: PackedStringArray = PackedStringArray()
		for stage in JOURNEY_STAGES:
			var level: int = world_i * JOURNEY_STAGES + stage + 1
			cells.append(_map_star_cell(level))
		row.text = "%s    %s" % [look.title, "   ".join(cells)]
		var current_world: int = _journey_world_index(_journey_progress) if _journey_progress >= 1 and not _journey_complete else -1
		if current_world == world_i:
			row.add_theme_color_override("font_color", look.ink)
		else:
			row.add_theme_color_override("font_color", Color(0.66, 0.52, 0.78, 0.86))


func _map_star_cell(level: int) -> String:
	var stars: int = _stars_at(level)
	var current: bool = not _journey_complete and _journey_progress == level
	if stars < 0 and not current:
		return "···"
	if stars <= 0:
		return "◯◯◯" if current else "☆☆☆"
	return _star_glyphs(stars)


func _ensure_star_slots() -> void:
	var needed: int = _journey_length()
	var old: int = _journey_stars.size()
	if old < needed:
		_journey_stars.resize(needed)
		for i in range(old, needed):
			_journey_stars[i] = -1


func _stars_at(level: int) -> int:
	_ensure_star_slots()
	var index: int = level - 1
	if index < 0 or index >= _journey_stars.size():
		return -1
	return _journey_stars[index]


func _record_stars(level: int, earned: int) -> void:
	_ensure_star_slots()
	var index: int = clampi(level - 1, 0, _journey_stars.size() - 1)
	_journey_stars[index] = maxi(_journey_stars[index], clampi(earned, 0, 3))


func _capture_stars() -> void:
	_last_star_seal = _puzzle_seals_used > 0
	_last_star_hint = _puzzle_hints_used <= 0 and _puzzle_seals_used <= 0
	_last_star_clean = _puzzle_mistakes <= 0
	_last_star_clock = _elapsed_seconds <= _star_time_limit()
	_last_puzzle_stars = int(_last_star_hint) + int(_last_star_clean) + int(_last_star_clock)


func _star_marks() -> String:
	if _last_puzzle_stars <= 0:
		return "☆☆☆"
	return _star_glyphs(_last_puzzle_stars)


func _star_sentence() -> String:
	var missed: PackedStringArray = PackedStringArray()
	if not _last_star_hint:
		missed.append("a seal" if _last_star_seal else "a hint")
	if not _last_star_clean:
		missed.append("a mistake")
	if not _last_star_clock:
		missed.append("the clock")
	if missed.is_empty():
		return "No hints, no mistakes, and inside the clock, so these stars paid %d gold." % _last_gold_stars
	if missed.size() == 3:
		var aid: String = "A seal" if _last_star_seal else "A hint"
		return "%s, a mistake, and the clock left no star gold." % aid
	if missed.size() == 1:
		return "%s, so these stars paid %d gold." % [_star_miss_line(missed[0]), _last_gold_stars]
	return "%s and %s cost two stars, so the last paid %d gold." % [_star_pair(missed[0]), missed[1], _last_gold_stars]


func _star_pair(reason: String) -> String:
	if reason == "a hint":
		return "A hint"
	if reason == "a seal":
		return "A seal"
	if reason == "a mistake":
		return "A mistake"
	return "The clock"


func _star_miss_line(reason: String) -> String:
	if reason == "a hint":
		return "A hint was used"
	if reason == "a seal":
		return "A seal was used"
	if reason == "a mistake":
		return "A mistake landed"
	return "The clock ran long"


func _star_time_limit() -> float:
	var limit: float = STAR_TIME_LIMITS[clampi(int(_difficulty), 0, STAR_TIME_LIMITS.size() - 1)]
	if _journey_pace == JourneyPace.RELAXED:
		limit *= 1.5
	return limit


func _star_glyphs(count: int) -> String:
	var filled: int = clampi(count, 0, 3)
	if filled <= 0:
		return ""
	return "★".repeat(filled) + "☆".repeat(3 - filled)


func _star_total() -> int:
	_ensure_star_slots()
	var total: int = 0
	for value in _journey_stars:
		total += maxi(0, value)
	return total


func _star_cap() -> int:
	return _journey_length() * 3


func _stars_to_text() -> String:
	_ensure_star_slots()
	var parts: PackedStringArray = PackedStringArray()
	for value in _journey_stars:
		parts.append(str(value))
	return ",".join(parts)


func _stars_from_text(raw: String) -> PackedInt32Array:
	var packed := PackedInt32Array()
	if raw.is_empty():
		return packed
	for part in raw.split(","):
		packed.append(clampi(int(part), -1, 3))
	return packed


func _ensure_shop_screen() -> void:
	if is_instance_valid(_shop_screen) and _shop_buttons.size() == ShopManager.SHELF:
		return
	if is_instance_valid(_shop_screen):
		_shop_screen.queue_free()
		_shop_screen = null
		_shop_buttons.clear()
		_shop_glyphs.clear()
		_shop_reroll = null
		_shop_skip = null
	var screen := Control.new()
	screen.name = "ShopScreen"
	screen.visible = false
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.z_index = 40
	screen.theme = theme
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.name = "Title"
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.96, 0.86, 0.42, 1.0))
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Gold  ·  0"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(440.0, 0.0)
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.7, 0.55, 0.84, 1.0))
	vbox.add_child(title)
	vbox.add_child(hint)
	var owned_row := HBoxContainer.new()
	owned_row.name = "Owned"
	owned_row.alignment = BoxContainer.ALIGNMENT_CENTER
	owned_row.add_theme_constant_override("separation", 6)
	owned_row.custom_minimum_size = Vector2(440.0, 40.0)
	vbox.add_child(owned_row)
	for token_slot in RelicManager.COUNT:
		var token := RelicGlyph.new()
		token.name = "Owned%d" % token_slot
		token.custom_minimum_size = Vector2(36.0, 36.0)
		token.set_look(token_slot, true)
		owned_row.add_child(token)
	_shop_owned_row = owned_row
	_shop_buttons.clear()
	_shop_glyphs.clear()
	for slot in ShopManager.SHELF:
		var button := Button.new()
		button.name = "Shelf%d" % slot
		button.custom_minimum_size = Vector2(0.0, 118.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.theme_type_variation = &"PlayButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = false
		_arm_tap(button, _on_shop_slot_pressed.bind(slot))
		var row := HBoxContainer.new()
		row.name = "Row"
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 14)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 18.0
		row.offset_right = -18.0
		row.offset_top = 10.0
		row.offset_bottom = -10.0
		var glyph := RelicGlyph.new()
		glyph.name = "Glyph"
		glyph.custom_minimum_size = Vector2(72.0, 72.0)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var col := VBoxContainer.new()
		col.name = "Copy"
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		var name_label := Label.new()
		name_label.name = "Name"
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.72, 1.0))
		var blurb := Label.new()
		blurb.name = "Blurb"
		blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		blurb.add_theme_font_size_override("font_size", 15)
		blurb.add_theme_color_override("font_color", Color(0.78, 0.7, 0.88, 0.95))
		col.add_child(name_label)
		col.add_child(blurb)
		row.add_child(glyph)
		row.add_child(col)
		button.add_child(row)
		vbox.add_child(button)
		_shop_buttons.append(button)
		_shop_glyphs.append(glyph)
	var reroll := Button.new()
	reroll.name = "Reroll"
	reroll.custom_minimum_size = Vector2(0.0, 72.0)
	reroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll.theme_type_variation = &"PlayButton"
	reroll.add_theme_font_size_override("font_size", 26)
	reroll.text = "Reroll  ·  100"
	_arm_tap(reroll, _on_shop_reroll_pressed)
	vbox.add_child(reroll)
	var skip := Button.new()
	skip.name = "Leave"
	skip.custom_minimum_size = Vector2(0.0, 72.0)
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip.theme_type_variation = &"GhostButton"
	skip.add_theme_font_size_override("font_size", 26)
	skip.text = "Leave"
	_arm_tap(skip, _on_shop_skipped)
	vbox.add_child(skip)
	margin.add_child(vbox)
	screen.add_child(dim)
	screen.add_child(margin)
	add_child(screen)
	move_child(screen, get_child_count() - 1)
	_shop_screen = screen
	_shop_title = title
	_shop_hint = hint
	_shop_reroll = reroll
	_shop_skip = skip
	_pin_full_rect(screen)


func _shop_items() -> Array[Control]:
	var items: Array[Control] = []
	if is_instance_valid(_shop_title):
		items.append(_shop_title)
	if is_instance_valid(_shop_hint):
		items.append(_shop_hint)
	if is_instance_valid(_shop_owned_row):
		items.append(_shop_owned_row)
	for button in _shop_buttons:
		if is_instance_valid(button):
			items.append(button)
	if is_instance_valid(_shop_reroll):
		items.append(_shop_reroll)
	if is_instance_valid(_shop_skip):
		items.append(_shop_skip)
	return items


func _hide_shop_screen() -> void:
	_shop_waiting = false
	if is_instance_valid(_shop_screen):
		_hide_reset(_shop_screen)


func _fill_shop_buttons() -> void:
	_economy.sync_level(maxi(_journey_level, _journey_progress))
	_relics.sync_level(maxi(_journey_level, _journey_progress))
	if is_instance_valid(_shop_hint):
		var hint: String = "Gold  ·  %d" % _economy.gold
		var world_mult: float = _economy.world_multiplier()
		if world_mult > 1.01:
			hint += "  ·  ×%s prices" % _economy.format_multiplier(world_mult)
		_shop_hint.text = hint
	if is_instance_valid(_shop_owned_row):
		for slot in _shop_owned_row.get_child_count():
			var token := _shop_owned_row.get_child(slot) as RelicGlyph
			if token != null:
				token.set_look(slot, not _relics.has_relic(slot as RelicManager.Relic))
	for slot in _shop_buttons.size():
		var button: Button = _shop_buttons[slot]
		var offer: ShopManager.Offer = _shop.offer_at(slot)
		button.text = ""
		var name_label := button.get_node_or_null("Row/Copy/Name") as Label
		var blurb := button.get_node_or_null("Row/Copy/Blurb") as Label
		var sold: bool = offer == null or offer.empty
		var can_buy: bool = not sold and _economy.can_spend(offer.price)
		button.disabled = sold or not can_buy
		if slot < _shop_glyphs.size() and is_instance_valid(_shop_glyphs[slot]):
			_shop_glyphs[slot].visible = not sold
			if not sold:
				_shop_glyphs[slot].set_look(offer.glyph, not can_buy)
		if sold:
			if name_label != null:
				name_label.text = "Sold"
				name_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.78, 1.0))
			if blurb != null:
				blurb.text = "This shelf is empty."
			continue
		if name_label != null:
			name_label.text = "%s  ·  %d" % [offer.title, offer.price]
			name_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.72, 1.0) if can_buy else Color(0.72, 0.68, 0.78, 1.0))
		if blurb != null:
			blurb.text = "%s  ·  %s" % [offer.tag, offer.blurb]
	if is_instance_valid(_shop_reroll):
		var cost: int = _shop.reroll_price()
		_shop_reroll.text = "Reroll  ·  %d" % cost
		_shop_reroll.disabled = not _economy.can_spend(cost)


func _maybe_present_shop() -> void:
	if not _relics.shop_pending:
		return
	_economy.sync_level(maxi(_journey_level, _journey_progress))
	_relics.sync_level(maxi(_journey_level, _journey_progress))
	_shop.begin_visit()
	_shop.restock(_economy, _relics)
	await _present_shop()
	_relics.shop_pending = false
	_save_journey_progress()


func _present_shop() -> void:
	_ensure_shop_screen()
	_fill_shop_buttons()
	_shop_waiting = true
	_pin_full_rect(_shop_screen)
	await _reveal(_shop_screen, _shop_items())
	while _shop_waiting and is_instance_valid(self):
		await get_tree().process_frame
	if is_instance_valid(_shop_screen) and _shop_screen.visible:
		await _fade_away([_shop_screen])


func _on_shop_slot_pressed(slot: int) -> void:
	if not _shop_waiting:
		return
	if not _shop.try_buy(slot, _economy, _relics):
		_fill_shop_buttons()
		return
	_play_sting(_relic_sting)
	_fill_shop_buttons()
	_save_journey_progress()


func _on_shop_reroll_pressed() -> void:
	if not _shop_waiting:
		return
	if not _shop.try_reroll(_economy, _relics):
		_fill_shop_buttons()
		return
	_fill_shop_buttons()
	_save_journey_progress()


func _on_shop_skipped() -> void:
	if not _shop_waiting:
		return
	_shop_waiting = false


func _uses_algae() -> bool:
	return _mode != Mode.MINI and _board.current_style() == SudokuBoard.ArtStyle.WATER


func _uses_sand_caches() -> bool:
	return _mode != Mode.MINI and _board.current_style() == SudokuBoard.ArtStyle.DESERT


func _uses_poison() -> bool:
	return _mode != Mode.MINI and _board.current_style() == SudokuBoard.ArtStyle.FOREST


func _uses_cyber_locks() -> bool:
	return _mode != Mode.MINI and _board.current_style() == SudokuBoard.ArtStyle.NIGHT


func _cyber_lock_count() -> int:
	var counts: Array[int] = [2, 4, 6]
	return counts[randi() % counts.size()]


func _sand_cache_count() -> int:
	if _mode == Mode.JOURNEY:
		return SudokuBoard.SAND_CACHE_MIN + _journey_stage_index(_journey_level)
	return randi_range(SudokuBoard.SAND_CACHE_MIN, SudokuBoard.SAND_CACHE_MAX)


func _uses_ember_pressure() -> bool:
	return _mode != Mode.MINI and _board.current_style() == SudokuBoard.ArtStyle.EMBER


func _ember_overheat_seconds() -> float:
	var seconds: float
	if _mode == Mode.JOURNEY:
		var by_stage: Array[float] = [180.0, 150.0, 120.0]
		seconds = by_stage[_journey_stage_index(_journey_level)]
	else:
		var by_difficulty: Array[float] = [180.0, 150.0, 120.0]
		seconds = by_difficulty[clampi(int(_difficulty), 0, by_difficulty.size() - 1)]
	if _mode == Mode.JOURNEY and _journey_pace == JourneyPace.RELAXED:
		seconds *= 1.25
	return seconds


func _apply_poison_bounty() -> void:
	if _mode != Mode.JOURNEY or not _uses_poison():
		_board.set_poison_bounty(0)
		return
	_economy.sync_level(_journey_level)
	_board.set_poison_bounty(_economy.vine_bounty())


func _apply_sand_bounty() -> void:
	if _mode != Mode.JOURNEY or not _uses_sand_caches():
		_board.set_sand_bounty(0)
		return
	_economy.sync_level(_journey_level)
	_board.set_sand_bounty(_economy.sand_bounty())


func _apply_ember_pressure(reset_heat: bool) -> void:
	if not _uses_ember_pressure():
		_board.clear_ember_pressure()
		_ember_warned = false
		return
	if reset_heat:
		_ember_warned = false
	_board.set_ember_pressure(_ember_overheat_seconds(), reset_heat)


func _flash_poison_screen() -> void:
	if not is_instance_valid(_poison_screen_flash):
		var flash := ColorRect.new()
		flash.name = "PoisonScreenFlash"
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.color = Color(0.16, 0.9, 0.3, 0.0)
		flash.z_index = 80
		_game_screen.add_child(flash)
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_poison_screen_flash = flash
	if _poison_screen_tween != null and is_instance_valid(_poison_screen_tween):
		_poison_screen_tween.kill()
	_poison_screen_flash.visible = true
	_poison_screen_flash.color = Color(0.16, 0.9, 0.3, 0.38)
	_poison_screen_tween = create_tween()
	_poison_screen_tween.tween_property(_poison_screen_flash, "color:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_run_relics(fresh: bool) -> void:
	_board.score_mult = 1.0
	_board.magnet_enabled = false
	_board.aegis_ready = false
	_board.relay_filling = false
	_board.seal_aim = -1
	_armed_tool = -1
	if _mode != Mode.JOURNEY:
		_apply_check()
		_refresh_relic_tray()
		_refresh_tool_bar()
		return
	_apply_check()
	_relics.sync_level(_journey_level)
	_economy.sync_level(_journey_level)
	if fresh:
		_relics.reset_level()
	_relics.apply_on_deal(_board, fresh)
	_refresh_relic_tray()
	_refresh_tool_bar()


func _ensure_relic_tray() -> void:
	if is_instance_valid(_relic_tray):
		return
	var vbox := $GameScreen/Margin/VBox as VBoxContainer
	var top_bar := vbox.get_node("TopBar") as Control
	var tray := HBoxContainer.new()
	tray.name = "RelicTray"
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_theme_constant_override("separation", 6)
	tray.custom_minimum_size = Vector2(0.0, 38.0)
	tray.visible = false
	_play_relic_glyphs.clear()
	for slot in RelicManager.COUNT:
		var glyph := RelicGlyph.new()
		glyph.name = "PlayRelic%d" % slot
		glyph.custom_minimum_size = Vector2(38.0, 38.0)
		glyph.set_look(slot, false)
		glyph.visible = false
		tray.add_child(glyph)
		_play_relic_glyphs.append(glyph)
	vbox.add_child(tray)
	vbox.move_child(tray, top_bar.get_index() + 1)
	_relic_tray = tray


func _refresh_relic_tray() -> void:
	_ensure_relic_tray()
	var show_any: bool = false
	var on_journey: bool = _mode == Mode.JOURNEY
	for slot in RelicManager.COUNT:
		var owned: bool = on_journey and _relics.has_relic(slot as RelicManager.Relic)
		if slot < _play_relic_glyphs.size() and is_instance_valid(_play_relic_glyphs[slot]):
			_play_relic_glyphs[slot].visible = owned
			if owned:
				_play_relic_glyphs[slot].set_look(slot, false)
				show_any = true
	_relic_tray.visible = show_any
	call_deferred("_place_tool_dock")


func _ensure_tool_bar() -> void:
	if is_instance_valid(_tool_bar):
		return
	var dock := VBoxContainer.new()
	dock.name = "ToolDock"
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dock.add_theme_constant_override("separation", 0)
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.z_index = 4
	dock.visible = false
	var prompt := Label.new()
	prompt.name = "ToolPrompt"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.custom_minimum_size = Vector2(0.0, 24.0)
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(prompt)
	var bar := HBoxContainer.new()
	bar.name = "ToolBoxes"
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tool_buttons.clear()
	_tool_glyphs.clear()
	for kind in RelicManager.TOOL_COUNT:
		var button := Button.new()
		button.name = "Tool%d" % kind
		button.custom_minimum_size = Vector2(36.0, 36.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.theme_type_variation = &"PlayButton"
		button.text = ""
		var glyph := RelicGlyph.new()
		glyph.name = "Symbol"
		glyph.custom_minimum_size = Vector2(28.0, 28.0)
		glyph.position = Vector2(4.0, 4.0)
		glyph.size = Vector2(28.0, 28.0)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.set_look(ShopManager.TOOL_GLYPHS[kind], false)
		button.add_child(glyph)
		_arm_tap(button, _on_tool_pressed.bind(kind))
		bar.add_child(button)
		_tool_buttons.append(button)
		_tool_glyphs.append(glyph)
	dock.add_child(bar)
	var screen := $GameScreen as Control
	screen.add_child(dock)
	if not screen.resized.is_connected(_place_tool_dock):
		screen.resized.connect(_place_tool_dock)
	_tool_prompt = prompt
	_tool_bar = dock


## Sits in the gap above the number keys, so neither the grid nor the keys shrink.
func _place_tool_dock() -> void:
	if not is_instance_valid(_tool_bar) or not _tool_bar.visible:
		return
	var height: float = maxf(_tool_bar.get_combined_minimum_size().y, 36.0)
	var pad_rect := _number_pad.get_global_rect()
	if pad_rect.size.x < 1.0:
		return
	_tool_bar.size = Vector2(pad_rect.size.x, height)
	_tool_bar.global_position = Vector2(pad_rect.position.x, pad_rect.position.y - height - 4.0)


func _refresh_tool_bar() -> void:
	_ensure_tool_bar()
	var seals_on: bool = _mode == Mode.JOURNEY
	var show_any: bool = false
	for kind in RelicManager.TOOL_COUNT:
		if kind >= _tool_buttons.size() or not is_instance_valid(_tool_buttons[kind]):
			continue
		var button: Button = _tool_buttons[kind]
		var count: int = _relics.tool_count(kind) if seals_on else 0
		var armed: bool = seals_on and _armed_tool == kind and count > 0
		button.visible = count > 0
		button.disabled = not _pad_enabled or count <= 0
		button.text = ""
		_paint_chrome_button(button, false, armed, false)
		if kind < _tool_glyphs.size() and is_instance_valid(_tool_glyphs[kind]):
			_tool_glyphs[kind].set_look(ShopManager.TOOL_GLYPHS[kind], count <= 0)
		if count > 0:
			show_any = true
	if not show_any or not seals_on:
		_armed_tool = -1
		if is_instance_valid(_board):
			_board.seal_aim = -1
	if is_instance_valid(_tool_prompt):
		var telling: bool = show_any and _armed_tool >= 0 and _armed_tool < ShopManager.TOOL_USE.size()
		_tool_prompt.text = ShopManager.TOOL_USE[_armed_tool] if telling else ""
		_tool_prompt.add_theme_color_override("font_color", _chrome.ink)
	_tool_bar.visible = show_any
	call_deferred("_place_tool_dock")


func _on_tool_pressed(kind: int) -> void:
	if _mode != Mode.JOURNEY or _dealing or _journey_failed or _win_screen.visible:
		return
	if _relics.tool_count(kind) <= 0:
		return
	if _armed_tool == kind:
		_armed_tool = -1
		_board.seal_aim = -1
	else:
		_armed_tool = kind
		_board.seal_aim = kind
	_refresh_tool_bar()


func _on_seal_target(index: int) -> void:
	if _mode != Mode.JOURNEY or _armed_tool < 0 or _dealing or _journey_failed:
		_armed_tool = -1
		_board.seal_aim = -1
		_refresh_tool_bar()
		return
	var kind: int = _armed_tool
	if not _board.seal_has_work(index, kind):
		_board.spawn_caption("FULL", index)
		return
	_relics.take_tool(kind)
	_puzzle_seals_used += 1
	_armed_tool = -1
	_board.seal_aim = -1
	_board.apply_seal(index, kind)
	_refresh_tool_bar()
	_update_status()
	if not _board.is_cleared():
		_queue_save_run()
	_save_journey_progress()


func _on_correct_placed() -> void:
	_emit_ui_click()
	_try_race_correct_streak()
	if _mode != Mode.JOURNEY or _board.magnet_filling or _board.relay_filling or _board.seal_filling or _journey_failed:
		return
	if _relics.on_player_correct() and _board.apply_relay():
		_relics.consume_relay()
		if not _board.is_cleared():
			_queue_save_run()


func _stop_win_motion() -> void:
	if _win_tween != null and _win_tween.is_valid():
		_win_tween.kill()


## The buttons live in levels_menu.tscn, in the same order as the Worlds array on Main.
func _build_level_list() -> void:
	var buttons: Array[Node] = _level_list.get_children()
	if buttons.size() != worlds.size():
		push_error("Levels menu has %d buttons and Main has %d worlds." % [buttons.size(), worlds.size()])
	var count: int = mini(buttons.size(), worlds.size())
	for index in count:
		var button := buttons[index] as Button
		var look: WorldLook = worlds[index]
		if button == null or look == null:
			continue
		button.text = look.title
		button.add_theme_color_override("font_color", look.ink)
		_arm_tap(button, _on_level_button_pressed.bind(index))


func _world_at(index: int) -> WorldLook:
	if index < 0 or index >= worlds.size() or worlds[index] == null:
		var fallback := WorldLook.new()
		fallback.title = "Neon"
		fallback.style = SudokuBoard.ArtStyle.NIGHT as int
		fallback.ink = Color(0.96, 0.55, 1.0)
		return fallback
	return worlds[index]


func _look_for_style(style: SudokuBoard.ArtStyle) -> WorldLook:
	for look in worlds:
		if look != null and look.style == int(style):
			return look
	return null


func _current_world_look() -> WorldLook:
	if _mode == Mode.JOURNEY:
		return _journey_look(_journey_level)
	return _world_at(_world_index)


func _play_world_ambience() -> void:
	_set_ambience(_current_world_look())


func _set_ambience(look: WorldLook) -> void:
	if look != null and look.ambience == null:
		look = null
	if look != null and look == _playing_look and _ambience_should_loop:
		return
	_ambience_should_loop = false
	_kill_tween(_ambience_fade)
	_ambience.stop()
	_ambience.volume_db = 0.0
	_playing_look = look
	if look == null:
		return
	_start_ambience(look)


func _start_ambience(look: WorldLook) -> void:
	if look == null or look.ambience == null:
		return
	var stream: AudioStream = look.ambience.duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_ambience.stream = stream
	var bus_name: String = look.ambience_bus
	_ambience.bus = bus_name if bus_name != "" else "Ambience"
	_ambience.volume_db = AUDIO_SILENCE_DB
	_ambience_should_loop = true
	_ambience.play(0.0)
	_ambience_fade = _fade_player(_ambience, 0.0, AMBIENCE_FADE_IN)


func _stop_ambience() -> void:
	_ambience_should_loop = false
	_playing_look = null
	_kill_tween(_ambience_fade)
	if not _ambience.playing:
		_ambience.stop()
		_ambience.volume_db = 0.0
		return
	_ambience_fade = _fade_player(_ambience, AUDIO_SILENCE_DB, AMBIENCE_FADE_OUT)
	_ambience_fade.tween_callback(_finish_ambience_fade)


func _finish_ambience_fade() -> void:
	if _ambience_should_loop:
		return
	_ambience.stop()
	_ambience.volume_db = 0.0


func _on_ambience_finished() -> void:
	if not _ambience_should_loop or _ambience.playing or _ambience.stream == null:
		return
	_ambience.play(0.0)


func _setup_menu_audio() -> void:
	var stream: AudioStream = MENU_STREAM.duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	_menu.stream = stream
	_menu.bus = "Menu"
	_menu.volume_db = 0.0


func _ensure_menu_music() -> void:
	if _menu_should_loop:
		return
	_start_menu_music()


func _start_menu_music() -> void:
	_menu_should_loop = true
	if _menu.stream == null:
		_setup_menu_audio()
	_kill_tween(_menu_fade)
	_menu.volume_db = AUDIO_SILENCE_DB
	_menu.play(0.0)
	_menu_fade = _fade_player(_menu, 0.0, MENU_FADE_IN)


func _stop_menu_music() -> void:
	_menu_should_loop = false
	_kill_tween(_menu_fade)
	if not _menu.playing:
		_menu.stop()
		_menu.volume_db = 0.0
		return
	_menu_fade = _fade_player(_menu, AUDIO_SILENCE_DB, MENU_FADE_OUT)
	_menu_fade.tween_callback(_finish_menu_fade)


func _finish_menu_fade() -> void:
	if _menu_should_loop:
		return
	_menu.stop()
	_menu.volume_db = 0.0


func _fade_player(player: AudioStreamPlayer, to_db: float, duration: float) -> Tween:
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", to_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _on_menu_music_finished() -> void:
	if not _menu_should_loop or _menu.playing or _menu.stream == null:
		return
	_menu.play(0.0)


func _setup_win_audio() -> void:
	var stream: AudioStream = WIN_STREAM.duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	_win.stream = stream
	_win.bus = "Win"
	_win.volume_db = 0.0


func _play_win_sound() -> void:
	if _win.stream == null:
		_setup_win_audio()
	_win.play(0.0)


func _stop_win_sound() -> void:
	_win.stop()


func _setup_completion_audio() -> void:
	_clear_voices = _make_oneshot_pool(_completions, COMPLETION_A, COMPLETION_B, "SFX")


func _play_completion_sound() -> void:
	_clear_cursor = _fire_oneshot(_clear_voices, _clear_cursor, COMPLETION_PITCH)
	_try_race_correct_streak()


func _try_race_correct_streak() -> void:
	if _mode != Mode.MINI or _mini_chaining or _race_ending or _dealing or _race_hinting:
		return
	var bonus: float = _race.on_correct_fill()
	if bonus <= 0.0:
		return
	_sync_race_clock()
	_board.spawn_clock_pop(int(bonus), _board.last_place_index)
	_board.spawn_caption("STREAK +3s", _board.last_place_index)
	_punch_race_clock(true)


func _setup_click_audio() -> void:
	_click_voices = _make_oneshot_pool(_clicks, CLICK_A, CLICK_B, "UI")


func _setup_mechanic_audio() -> void:
	_treasure_sting = _make_sting("TreasureSting", TREASURE_STREAM)
	_overheat_sting = _make_sting("OverheatSting", OVERHEAT_STREAM)
	_relic_sting = _make_sting("RelicSting", RELIC_BUY_STREAM)
	_cyber_sting = _make_sting("CyberSting", CYBER_UNLOCK_STREAM)
	_algae_sting = _make_sting("AlgaeSting", ALGAE_SPLASH_STREAM)
	_algae_tap_sting = _make_sting("AlgaeTapSting", ALGAE_TAP_STREAM)
	_leaf_sting = _make_sting("LeafSting", LEAF_CLEAR_STREAM)


func _make_sting(node_name: String, stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	add_child(player)
	_prep_oneshot(player, stream, "SFX")
	return player


func _play_sting(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.pitch_scale = 1.0
	player.play(0.0)


func _on_cyber_unlocked(_index: int) -> void:
	_play_sting(_cyber_sting)


func _on_algae_tapped(_index: int) -> void:
	_play_sting(_algae_tap_sting)


func _on_algae_splashed(_index: int) -> void:
	_play_sting(_algae_sting)


func _make_oneshot_pool(first: AudioStreamPlayer, stream_a: AudioStream, stream_b: AudioStream, bus: String) -> Array[AudioStreamPlayer]:
	var voices: Array[AudioStreamPlayer] = []
	var streams: Array[AudioStream] = [stream_a, stream_b, stream_a]
	for i in ONESHOT_VOICES:
		var player: AudioStreamPlayer = first if i == 0 else AudioStreamPlayer.new()
		if i != 0:
			player.name = "%sVoice%d" % [bus, i]
			add_child(player)
		_prep_oneshot(player, streams[i % streams.size()], bus)
		voices.append(player)
	_warmup_oneshots(voices)
	return voices


func _prep_oneshot(player: AudioStreamPlayer, stream: AudioStream, bus: String) -> void:
	player.stream = stream
	player.bus = bus
	player.max_polyphony = 1
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	# SAMPLE is the low-latency path in the browser. Desktop mixers already play PCM immediately.
	if OS.has_feature("web"):
		player.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
	else:
		player.playback_type = AudioServer.PLAYBACK_TYPE_DEFAULT


func _warmup_oneshots(voices: Array[AudioStreamPlayer]) -> void:
	for player in voices:
		player.volume_db = -80.0
		player.play(0.0)
		player.stop()
		player.volume_db = 0.0


func _fire_oneshot(voices: Array[AudioStreamPlayer], cursor: int, pitch: float) -> int:
	if voices.is_empty():
		return 0
	var index: int = posmod(cursor, voices.size())
	var player: AudioStreamPlayer = voices[index]
	player.pitch_scale = randf_range(1.0 / pitch, pitch)
	player.play(0.0)
	return posmod(index + 1, voices.size())


func _hook_ui_clicks(node: Node) -> void:
	if node == _game_screen:
		_hook_in_game_press_cue(node)
		return
	if node is Button:
		var button := node as Button
		_prepare_button(button)
		if not button.button_down.is_connected(_play_ui_click):
			button.button_down.connect(_play_ui_click)
	elif node is HSlider:
		_prepare_slider(node as HSlider)
	for child in node.get_children():
		_hook_ui_clicks(child)


func _hook_in_game_press_cue(node: Node) -> void:
	if node == _number_pad:
		return
	if node is Button:
		var button := node as Button
		_prepare_button(button)
		if not button.button_down.is_connected(_pulse_in_game_button.bind(button)):
			button.button_down.connect(_pulse_in_game_button.bind(button))
	for child in node.get_children():
		_hook_in_game_press_cue(child)


func _prepare_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.keep_pressed_outside = true
	button.toggle_mode = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _prepare_slider(slider: HSlider) -> void:
	slider.focus_mode = Control.FOCUS_NONE
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	slider.scrollable = false
	slider.custom_minimum_size.y = maxf(slider.custom_minimum_size.y, 72.0)


func _arm_tap(button: Button, handler: Callable) -> void:
	if not is_instance_valid(button):
		return
	_prepare_button(button)
	button.button_down.connect(_on_armed_tap.bind(button, handler))


func _on_armed_tap(button: Button, handler: Callable) -> void:
	if button.disabled:
		return
	var id: int = button.get_instance_id()
	var now: int = Time.get_ticks_msec()
	if now - int(_tap_guard.get(id, 0)) < TAP_GUARD_MS:
		return
	_tap_guard[id] = now
	handler.call()


func _pulse_in_game_button(button: Button) -> void:
	# Scale would shrink the hit box under a finger and cancel the tap on phones.
	var tween := button.create_tween()
	tween.tween_property(button, "modulate", Color(1.35, 1.35, 1.35), 0.05)
	tween.tween_property(button, "modulate", Color.WHITE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_ui_click() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_ui_click_ms < TAP_GUARD_MS:
		return
	_last_ui_click_ms = now
	_emit_ui_click()


func _emit_ui_click() -> void:
	_click_cursor = _fire_oneshot(_click_voices, _click_cursor, CLICK_PITCH)


func _difficulty_for_level(level: int) -> Difficulty:
	var index: int = maxi(1, level) - 1
	var difficulty: Difficulty = Difficulty.HARD
	if index >= 0 and index < JOURNEY_DIFFICULTY.size():
		difficulty = JOURNEY_DIFFICULTY[index] as Difficulty
	if _journey_pace == JourneyPace.RELAXED and int(difficulty) > int(Difficulty.EASY):
		difficulty = (int(difficulty) - 1) as Difficulty
	return difficulty


func _journey_stage_index(level: int) -> int:
	return posmod(maxi(1, level) - 1, JOURNEY_STAGES)


func _journey_world_index(level: int) -> int:
	if worlds.is_empty():
		return 0
	@warning_ignore("integer_division")
	return posmod((maxi(1, level) - 1) / JOURNEY_STAGES, worlds.size())


func _journey_look(level: int) -> WorldLook:
	return _world_at(_journey_world_index(level))


func _journey_length() -> int:
	return maxi(1, worlds.size()) * JOURNEY_STAGES


func _is_journey_finale() -> bool:
	return _mode == Mode.JOURNEY and _journey_level >= _journey_length()


func _on_new_pressed() -> void:
	if _transitioning or _dealing or _win_screen.visible:
		return
	if not _confirm_new_puzzle:
		_arm_new_confirm()
		return
	_reset_new_confirm()
	if _mode == Mode.MINI:
		_mini_chaining = false
		_race_ending = false
		_difficulty = Difficulty.EASY
		_pick_race_world()
	start_new_game(false)


func _on_quit_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	var focus: Control = _quit_button
	if _main_menu.visible and is_instance_valid(_home_quit_button):
		focus = _home_quit_button
	if is_instance_valid(focus):
		var tween := create_tween()
		tween.tween_property(focus, "modulate", Color(1.35, 1.35, 1.35), 0.12)
		await tween.finished
	_flush_save_run()
	_save_prefs()
	get_tree().quit()


func _toggle_night() -> void:
	_on_night_toggled(not _night_mode)


func _on_night_toggled(enabled: bool) -> void:
	if _night_mode == enabled:
		return
	_reset_new_confirm()
	_night_mode = enabled
	_sync_night_buttons()
	_apply_night_mode(true)
	_save_prefs()


func _apply_night_mode(animate: bool) -> void:
	var target: Color = NIGHT_TINT if _night_mode else Color.WHITE
	if _night_tween != null and _night_tween.is_valid():
		_night_tween.kill()
	if not animate:
		_night_tint.color = target
		return
	_night_tween = create_tween()
	_night_tween.tween_property(_night_tint, "color", target, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _sync_night_buttons() -> void:
	_night_button.text = "Night mode: On" if _night_mode else "Night mode: Off"


func _toggle_buzz() -> void:
	_on_buzz_toggled(not _haptics_enabled)


func _on_buzz_toggled(enabled: bool) -> void:
	if _haptics_enabled == enabled:
		return
	_haptics_enabled = enabled
	_apply_haptics()
	_sync_buzz_button()
	_save_prefs()
	if enabled:
		SudokuBoard.pulse_device(SudokuBoard.HAPTIC_CLEAR_MS, SudokuBoard.HAPTIC_CLEAR_AMP)


func _apply_haptics() -> void:
	_board.haptics_enabled = _haptics_enabled


func _sync_buzz_button() -> void:
	_buzz_button.text = "Buzz: On" if _haptics_enabled else "Buzz: Off"


func _sync_settings_hint() -> void:
	var rule := "Show mistakes paints a number that is not the finished answer."
	if OS.has_feature("web"):
		_settings_hint.text = "Buzz is often blocked in the itch.io browser.\nAn Android app can vibrate; iPhone web cannot.\n" + rule
	else:
		_settings_hint.text = "Feel and sound\n" + rule


func _toggle_check() -> void:
	_on_check_toggled(not _check_mistakes)


func _on_check_toggled(enabled: bool) -> void:
	if _check_mistakes == enabled:
		return
	_reset_new_confirm()
	_check_mistakes = enabled
	_apply_check()
	_sync_check_button()
	_save_prefs()


func _apply_check() -> void:
	_board.check_mistakes = _check_mistakes


func _sync_check_button() -> void:
	_check_button.text = "Show mistakes: On" if _check_mistakes else "Show mistakes: Off"


func _hints_budget() -> int:
	var table: Array[int] = HINTS_BY_DIFFICULTY
	if _mode == Mode.MINI:
		table = WIDE_HINTS_BY_DIFFICULTY if _race_grid == SudokuGenerator.WIDE_SIZE else MINI_HINTS_BY_DIFFICULTY
	var index: int = clampi(int(_difficulty), 0, table.size() - 1)
	var budget: int = table[index]
	if _mode == Mode.JOURNEY:
		budget += _relics.extra_hints()
	return budget


func _refresh_hint_button() -> void:
	var can_hint: bool = _pad_enabled and _hints_left > 0
	_hint_button.disabled = not can_hint
	_hint_button.text = "Hint · %d" % _hints_left if _hints_left > 0 else "Hint"
	_paint_chrome_button(_hint_button, _hints_left <= 0, false, false)


func _on_hint_pressed() -> void:
	if _transitioning or _dealing or _win_screen.visible or _journey_failed:
		return
	_reset_new_confirm()
	if _hints_left <= 0:
		return
	_race_hinting = true
	var filled: bool = _board.apply_hint()
	_race_hinting = false
	if not filled:
		return
	_hints_left -= 1
	_puzzle_hints_used += 1
	_refresh_hint_button()
	_queue_save_run()


func _on_music_volume_changed(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_mix()
	_sync_audio_labels()


func _on_music_drag_ended(_changed: bool) -> void:
	_save_prefs()


func _on_sounds_volume_changed(value: float) -> void:
	_sounds_volume = clampf(value, 0.0, 1.0)
	_apply_audio_mix()
	_sync_audio_labels()


func _on_sounds_drag_ended(changed: bool) -> void:
	_save_prefs()
	if changed and _sounds_volume > 0.001:
		_play_ui_click()


func _sync_audio_sliders() -> void:
	_music_slider.set_value_no_signal(_music_volume)
	_sounds_slider.set_value_no_signal(_sounds_volume)
	_sync_audio_labels()


func _sync_audio_labels() -> void:
	_music_label.text = _volume_label("Music", _music_volume)
	_sounds_label.text = _volume_label("Sounds", _sounds_volume)


func _volume_label(title: String, amount: float) -> String:
	if amount <= 0.001:
		return "%s  Off" % title
	return "%s  %d%%" % [title, int(round(amount * 100.0))]


func _apply_audio_mix() -> void:
	_set_bus_mix("Ambience", _music_volume, MUSIC_BUS_DB)
	_set_bus_mix("SFX", _sounds_volume, SFX_BUS_DB)
	_set_bus_mix("UI", _sounds_volume, UI_BUS_DB)
	_set_bus_mix("Win", _sounds_volume, WIN_BUS_DB)


func _set_bus_mix(bus_name: String, amount: float, designed_db: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var silent: bool = amount <= 0.001
	AudioServer.set_bus_mute(index, silent)
	if silent:
		return
	AudioServer.set_bus_volume_db(index, designed_db + linear_to_db(amount))




func _on_progress_changed(remaining: int) -> void:
	_remaining_cells = remaining
	if not _dealing:
		_reset_new_confirm()
	_board.set_mood_sources(_difficulty, remaining, _blanks_for_current())
	_update_status()
	_queue_save_run()


func _on_score_changed(score: int, _streak: int) -> void:
	if _mode == Mode.MINI and not _mini_chaining:
		_mini_race_score = score
	_update_status()


func _apply_stage_mood() -> void:
	var material := _background.material as ShaderMaterial
	if material == null:
		return
	var shown: float = _board.mood
	var top: Color = _board.sky_top
	var bottom: Color = _board.sky_bottom
	var glow: Color = _board.glow_color
	var world: int = SudokuBoard.ArtStyle.NIGHT
	if _game_screen.visible:
		world = _board.current_style()
	else:
		shown = 0.48 + sin(_stage_clock * TAU / SudokuBoard.MOOD_CYCLE) * 0.18
		top = Color(0.02, 0.0, 0.04)
		bottom = Color(0.05, 0.0, 0.08)
		glow = Color(0.55, 0.12, 0.75)
	material.set_shader_parameter("mood", shown)
	material.set_shader_parameter("sky_top", top)
	material.set_shader_parameter("sky_bottom", bottom)
	material.set_shader_parameter("glow_color", glow)
	material.set_shader_parameter("world", world)


func _apply_style_chrome() -> void:
	_chrome = _chrome_for(_board.current_style())
	_status_label.add_theme_color_override("font_color", _chrome.ink)
	for child in _number_pad.get_children():
		var button := child as Button
		if button == null:
			continue
		_paint_chrome_button(button, button == _erase_button, false, true)
	_paint_chrome_button(_menu_button, false, false, false)
	_paint_chrome_button(_new_button, false, _confirm_new_puzzle, false)
	_paint_chrome_button(_undo_button, false, false, false)
	_paint_chrome_button(_hint_button, _hints_left <= 0, false, false)
	_paint_chrome_button(_notes_button, false, _board.notes_mode, false)
	_refresh_digit_pad()
	_refresh_tool_bar()


func _refresh_digit_pad() -> void:
	if _digit_buttons.is_empty():
		return
	var counts: PackedInt32Array = _board.digit_counts()
	for index in _digit_buttons.size():
		var remaining: int = maxi(0, _board.grid_size - counts[index])
		var done: bool = remaining <= 0
		var button: Button = _digit_buttons[index]
		button.disabled = not _pad_enabled or done
		_paint_chrome_button(button, done, false, true)
		var remain: Label = _digit_remain_labels[index]
		remain.visible = remaining > 0
		remain.text = str(remaining) if remaining > 0 else ""
		remain.add_theme_color_override("font_color", _chrome.muted)


func _chrome_for(style: SudokuBoard.ArtStyle) -> Chrome:
	var chrome := Chrome.new()
	match style:
		SudokuBoard.ArtStyle.DESERT:
			chrome.fill = Color(0.22, 0.1, 0.03)
			chrome.hover = Color(0.34, 0.16, 0.04)
			chrome.pressed = Color(0.14, 0.06, 0.02)
			chrome.disabled = Color(0.12, 0.07, 0.03)
			chrome.border = Color(1.0, 0.74, 0.28)
			chrome.ink = Color(1.0, 0.93, 0.76)
			chrome.muted = Color(0.86, 0.62, 0.28)
			chrome.disabled_ink = Color(0.55, 0.38, 0.18)
			chrome.radius = 12
			chrome.glow = Color(1.0, 0.55, 0.12, 0.32)
		SudokuBoard.ArtStyle.WATER:
			chrome.fill = Color(0.02, 0.08, 0.14, 0.92)
			chrome.hover = Color(0.04, 0.16, 0.24, 0.96)
			chrome.pressed = Color(0.01, 0.04, 0.08, 0.94)
			chrome.disabled = Color(0.02, 0.05, 0.08, 0.7)
			chrome.border = Color(0.38, 0.88, 1.0)
			chrome.ink = Color(0.84, 0.97, 1.0)
			chrome.muted = Color(0.4, 0.72, 0.86)
			chrome.disabled_ink = Color(0.28, 0.46, 0.56)
			chrome.radius = 24
			chrome.glow = Color(0.2, 0.78, 1.0, 0.34)
		SudokuBoard.ArtStyle.FOREST:
			chrome.fill = Color(0.04, 0.1, 0.04)
			chrome.hover = Color(0.07, 0.17, 0.06)
			chrome.pressed = Color(0.02, 0.06, 0.02)
			chrome.disabled = Color(0.03, 0.06, 0.03)
			chrome.border = Color(0.5, 0.92, 0.38)
			chrome.ink = Color(0.88, 0.98, 0.74)
			chrome.muted = Color(0.5, 0.72, 0.38)
			chrome.disabled_ink = Color(0.3, 0.44, 0.24)
			chrome.radius = 20
			chrome.glow = Color(0.48, 0.95, 0.28, 0.3)
		SudokuBoard.ArtStyle.EMBER:
			chrome.fill = Color(0.13, 0.03, 0.012)
			chrome.hover = Color(0.22, 0.06, 0.02)
			chrome.pressed = Color(0.07, 0.015, 0.006)
			chrome.disabled = Color(0.08, 0.03, 0.015)
			chrome.border = Color(1.0, 0.42, 0.12)
			chrome.ink = Color(1.0, 0.88, 0.7)
			chrome.muted = Color(0.88, 0.46, 0.2)
			chrome.disabled_ink = Color(0.52, 0.26, 0.14)
			chrome.radius = 8
			chrome.glow = Color(1.0, 0.32, 0.06, 0.4)
		_:
			chrome.fill = Color(0.11, 0.05, 0.16)
			chrome.hover = Color(0.18, 0.08, 0.26)
			chrome.pressed = Color(0.07, 0.03, 0.11)
			chrome.disabled = Color(0.07, 0.035, 0.1)
			chrome.border = Color(0.9, 0.48, 1.0)
			chrome.ink = Color(0.94, 0.88, 1.0)
			chrome.muted = Color(0.66, 0.52, 0.78)
			chrome.disabled_ink = Color(0.42, 0.32, 0.48)
			chrome.radius = 18
			chrome.glow = Color(0.9, 0.4, 1.0, 0.38)
	return chrome


func _paint_chrome_button(button: Button, muted: bool, lit: bool, tile: bool = false) -> void:
	if button == null or _chrome == null:
		return
	var fill: Color = _chrome.fill
	var border: Color = _chrome.border
	if tile:
		fill = fill.lerp(Color.WHITE, 0.07)
	if lit:
		fill = _chrome.hover.lerp(_chrome.border, 0.16)
		border = _chrome.border.lerp(Color.WHITE, 0.28)
	button.add_theme_stylebox_override("normal", _chrome_box(fill, border, 1.0 if not lit else 1.25))
	button.add_theme_stylebox_override("hover", _chrome_box(_chrome.hover, border.lerp(Color.WHITE, 0.18), 1.2))
	button.add_theme_stylebox_override("pressed", _chrome_box(_chrome.pressed, border, 0.7))
	var dim_border := Color(border.r, border.g, border.b, 0.28)
	button.add_theme_stylebox_override("disabled", _chrome_box(_chrome.disabled, dim_border, 0.15))
	button.add_theme_stylebox_override("focus", _chrome_focus_box(border))
	var ink: Color = _chrome.muted if muted else _chrome.ink
	if lit:
		ink = _chrome.ink.lerp(Color.WHITE, 0.22)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink.lerp(Color.WHITE, 0.18))
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	button.add_theme_color_override("font_disabled_color", _chrome.disabled_ink)


func _chrome_box(fill: Color, border: Color, glow_scale: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(_chrome.radius)
	box.content_margin_left = 12.0
	box.content_margin_top = 10.0
	box.content_margin_right = 12.0
	box.content_margin_bottom = 10.0
	box.shadow_color = Color(_chrome.glow.r, _chrome.glow.g, _chrome.glow.b, _chrome.glow.a * glow_scale)
	box.shadow_size = int(round(10.0 * glow_scale))
	return box


func _chrome_focus_box(border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = border.lerp(Color.WHITE, 0.25)
	box.set_border_width_all(3)
	box.set_corner_radius_all(_chrome.radius)
	box.content_margin_left = 12.0
	box.content_margin_top = 10.0
	box.content_margin_right = 12.0
	box.content_margin_bottom = 10.0
	return box


func _on_board_solved() -> void:
	if _dealing or _journey_failed:
		return
	var round_id: int = _round
	_reset_new_confirm()
	_save_queued = false
	if _mode == Mode.MINI:
		await _on_mini_cleared(round_id)
		return
	_timer_running = false
	_clear_run()
	_set_input_enabled(false)
	_board.lift_mood()
	_touch_daily_streak()
	if _mode == Mode.JOURNEY:
		_capture_stars()
		_record_stars(_journey_level, _last_puzzle_stars)
		_economy.sync_level(_journey_level)
		var slip: EconomyManager.Payout = _economy.collect_clear(
			_puzzle_mistakes,
			_board.poison_cleared_count(),
			_board.sand_caches_cleared_count(),
			_last_puzzle_stars
		)
		_last_gold_paid = slip.total
		_last_gold_clear = slip.clear_reward
		_last_gold_flawless = slip.flawless_bonus
		_last_gold_interest = slip.interest
		_last_gold_vines = slip.vine_bonus
		_last_gold_sand = slip.sand_bonus
		_last_gold_stars = slip.star_bonus
		_journey_run_score += _last_gold_paid
		if _is_journey_finale():
			_journey_complete = true
			_journey_progress = 0
		else:
			_journey_complete = false
			_journey_progress = _journey_level + 1
			if _journey_level % JOURNEY_STAGES == 0:
				_relics.shop_pending = true
		_save_journey_progress()
	_time_label.text = _cleared_line()
	_apply_high_score()
	# Hold the win screen until the line-clear on the last digit has played.
	await get_tree().create_timer(SudokuBoard.CELEBRATION_TIME).timeout
	if round_id != _round or not _game_screen.visible:
		return
	await _present_win(round_id)


func _on_mini_cleared(round_id: int) -> void:
	_mini_chaining = true
	_set_play_chrome_locked(true)
	_set_input_enabled(false)
	_board.lift_mood()
	_mini_clears += 1
	_mini_race_score = _board.score
	_touch_daily_streak(false)
	_race.on_grid_completed()
	_sync_race_clock()
	if _race.last_perfect:
		_board.spawn_caption("PERFECT! +5s", _board.last_place_index)
		_board.spawn_clock_pop(int(RaceModeManager.PERFECT_BONUS), _board.last_place_index)
	_punch_race_clock(true)
	_update_status()
	_difficulty = _mini_race_difficulty()
	_pick_race_world()
	await get_tree().process_frame
	if not _race_chain_alive(round_id):
		_finish_race_chain()
		return
	_race_next_puzzle = SudokuGenerator.generate(_blanks_for_current(), _race_grid, RACE_SEARCH_BUDGET)
	await get_tree().create_timer(MINI_CHAIN_HOLD).timeout
	if not _race_chain_alive(round_id):
		_finish_race_chain()
		return
	_board.set_fx_paused(true)
	await _race_board_out()
	if not _race_chain_alive(round_id):
		_finish_race_chain()
		return
	if _race_seconds <= 0.0:
		_finish_race_chain(false)
		_on_mini_times_up()
		return
	var previous_style: SudokuBoard.ArtStyle = _board.current_style()
	_deal_race_chain()
	if not is_instance_valid(self) or not _game_screen.visible or _mode != Mode.MINI or not _mini_chaining:
		_finish_race_chain()
		return
	await _race_board_in()
	_board.set_fx_paused(false)
	if _board.current_style() != previous_style:
		_apply_style_chrome()
	_set_play_chrome_locked(false)
	_set_input_enabled(true)
	_refresh_hint_button()
	_mini_chaining = false
	_save_prefs()
	if _race_seconds <= 0.0:
		_on_mini_times_up()


func _on_mini_times_up() -> void:
	if _mode != Mode.MINI or _race_ending or _dealing or _mini_chaining:
		return
	if _win_screen.visible:
		return
	_race_ending = true
	_timer_running = false
	_reset_race_danger_fx()
	_reset_new_confirm()
	_save_queued = false
	_clear_run()
	_set_input_enabled(false)
	_time_label.text = _mini_race_summary()
	_apply_high_score()
	await _present_win(_round)


func _on_journey_failed() -> void:
	if _mode != Mode.JOURNEY or _journey_failed or _dealing:
		return
	if _win_screen.visible:
		return
	_journey_failed = true
	_timer_running = false
	_reset_new_confirm()
	_save_queued = false
	_clear_run()
	_set_input_enabled(false)
	_set_play_chrome_locked(true)
	_last_gold_lost = _economy.take_fail_tax()
	_save_journey_progress()
	_board.conceal_level_mechanics()
	if is_instance_valid(_poison_screen_flash):
		_poison_screen_flash.color.a = 0.0
	if _last_gold_lost > 0:
		_time_label.text = "−%d gold" % _last_gold_lost
	else:
		_time_label.text = "Purse was empty."
	_highscore_label.text = "Gold  ·  %d" % _economy.gold
	_highscore_label.add_theme_color_override("font_color", COLOR_HIGHSCORE_MUTED)
	_highscore_label.remove_theme_font_size_override("font_size")
	await _present_win(_round)


func _present_win(round_id: int) -> void:
	_win_screen.visible = true
	_win_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_dim.color.a = 0.0
	_win_panel.modulate.a = 0.0
	_win_panel.scale = Vector2.ONE
	var flash: Color = _board.glow_color.lerp(Color.WHITE, 0.2)
	_win_label.modulate = Color(flash.r * 1.25, flash.g * 1.15, flash.b * 1.2)
	_set_win_spread(0.0)
	await get_tree().process_frame
	if round_id != _round or not _game_screen.visible:
		_dismiss_win()
		return
	_apply_win_copy()
	_present_win_stars()
	if _is_journey_finale():
		_stop_ambience()
		_ensure_menu_music()
	if not _journey_failed:
		_play_win_sound()
	_win_panel.pivot_offset = _win_panel.size * 0.5
	_win_tween = create_tween()
	_win_tween.set_parallel(true)
	_win_tween.tween_property(_win_dim, "color:a", 0.76, 0.45)
	_win_tween.tween_method(_set_win_spread, 0.0, 1.0, 0.75)
	_win_tween.tween_property(_win_panel, "modulate:a", 1.0, 0.4).set_delay(0.14)
	_win_tween.tween_property(_win_label, "modulate", Color.WHITE, 0.55).set_delay(0.12)
	_highscore_label.modulate.a = 0.0
	_win_tween.tween_property(_highscore_label, "modulate:a", 1.0, 0.4).set_delay(0.22)
	await _win_tween.finished
	if round_id == _round and _game_screen.visible:
		_yes_button.release_focus()
		_no_button.release_focus()


func _set_win_spread(spread: float) -> void:
	var material := _win_bloom.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("spread", spread)
		material.set_shader_parameter("neon", _board.glow_color)


func _dismiss_win() -> void:
	if _win_tween != null and _win_tween.is_valid():
		_win_tween.kill()
	_stop_win_sound()
	_win_screen.visible = false
	_win_panel.scale = Vector2.ONE
	_win_panel.modulate = Color.WHITE
	_win_label.modulate = Color.WHITE
	_win_label.text = "YOU WON!"
	_win_label.remove_theme_font_size_override("font_size")
	_yes_button.visible = true
	_highscore_label.modulate = Color.WHITE
	_highscore_label.remove_theme_font_size_override("font_size")
	if is_instance_valid(_win_stars):
		_win_stars.stop()
	_set_win_spread(1.0)


func _apply_high_score() -> void:
	_highscore_label.remove_theme_font_size_override("font_size")
	var key: String = _score_key()
	var best: int = _high_scores.get(key, 0)
	var run: int = _journey_run_score if _mode == Mode.JOURNEY else (_mini_clears if _mode == Mode.MINI else _board.score)
	var slot: String = _score_slot_name()
	if _mode == Mode.JOURNEY:
		_highscore_label.add_theme_font_size_override("font_size", 48)
		_highscore_label.add_theme_color_override("font_color", COLOR_HIGHSCORE)
		if run > best:
			_high_scores[key] = run
			_save_high_scores()
			_highscore_label.text = "+%d\nNEW BEST" % _last_gold_paid
		else:
			_highscore_label.text = "+%d" % _last_gold_paid
		return
	if run > best:
		_high_scores[key] = run
		_save_high_scores()
		_highscore_label.text = "NEW HIGHSCORE  ·  %s  ·  %d" % [slot, run]
		_highscore_label.add_theme_color_override("font_color", COLOR_HIGHSCORE)
	elif _mode == Mode.MINI:
		_highscore_label.text = "This race  ·  %d    Best  ·  %d" % [run, best]
		_highscore_label.add_theme_color_override("font_color", COLOR_HIGHSCORE_MUTED)
	else:
		_highscore_label.text = "%s  ·  High score  ·  %d" % [slot, best]
		_highscore_label.add_theme_color_override("font_color", COLOR_HIGHSCORE_MUTED)


func _present_win_stars() -> void:
	if not is_instance_valid(_win_stars):
		return
	if _mode != Mode.JOURNEY or _journey_failed:
		_win_stars.stop()
		return
	var glow: Color = _board.glow_color.lerp(Color(1.0, 0.86, 0.46), 0.58)
	_win_stars.set_result(_last_puzzle_stars, glow)
	_win_stars.play()


func _score_key() -> String:
	if _mode == Mode.JOURNEY:
		return "journey"
	if _mode == Mode.MINI:
		return "mini_race"
	var world: String = _world_at(_world_index).title.strip_edges().to_lower().replace(" ", "_")
	var difficulty: String = DIFFICULTY_NAMES[_difficulty].to_lower()
	return "%s_%s" % [world, difficulty]


func _score_slot_name() -> String:
	if _mode == Mode.JOURNEY:
		return "Journey run"
	if _mode == Mode.MINI:
		return "Race"
	return "%s %s" % [_world_at(_world_index).title, DIFFICULTY_NAMES[_difficulty]]


func _run_section() -> String:
	if _mode == Mode.JOURNEY:
		return RUN_JOURNEY
	if _mode == Mode.QUICK:
		return RUN_QUICK
	if _mode == Mode.MINI:
		return RUN_MINI
	return RUN_LEVEL


func _arm_journey_confirm() -> void:
	_confirm_new_journey = true
	_journey_confirm_id += 1
	var id: int = _journey_confirm_id
	_refresh_journey_buttons()
	get_tree().create_timer(CONFIRM_TIMEOUT).timeout.connect(_on_journey_confirm_timeout.bind(id), CONNECT_ONE_SHOT)


func _on_journey_confirm_timeout(id: int) -> void:
	if id != _journey_confirm_id or not _confirm_new_journey:
		return
	_confirm_new_journey = false
	if _journey_menu.visible:
		_refresh_journey_buttons()


func _clear_journey_confirm() -> void:
	_journey_confirm_id += 1
	_confirm_new_journey = false


func _arm_new_confirm() -> void:
	_confirm_new_puzzle = true
	_puzzle_confirm_id += 1
	var id: int = _puzzle_confirm_id
	_new_button.text = "Sure?"
	_paint_chrome_button(_new_button, false, true, false)
	get_tree().create_timer(CONFIRM_TIMEOUT).timeout.connect(_on_new_confirm_timeout.bind(id), CONNECT_ONE_SHOT)


func _on_new_confirm_timeout(id: int) -> void:
	if id != _puzzle_confirm_id:
		return
	_reset_new_confirm()


func _reset_new_confirm() -> void:
	if not _confirm_new_puzzle:
		return
	_puzzle_confirm_id += 1
	_confirm_new_puzzle = false
	_new_button.text = "New"
	_paint_chrome_button(_new_button, false, false, false)


func _set_play_chrome_locked(locked: bool) -> void:
	_new_button.disabled = locked
	_menu_button.disabled = locked
	_hint_button.disabled = locked or _hints_left <= 0


func _set_board_active(active: bool) -> void:
	_board.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _hold_play_timer() -> void:
	if _timer_running:
		_timer_held = true
		_timer_running = false
	else:
		_timer_held = false


func _release_play_timer() -> void:
	if _timer_held and _game_screen.visible and not _win_screen.visible and not _dealing and not _race_ending and not _journey_failed:
		_timer_running = true
	_timer_held = false


func _queue_save_run() -> void:
	if not is_node_ready() or not _board.can_save_run():
		return
	if _save_queued:
		return
	_save_queued = true
	get_tree().create_timer(SAVE_DEBOUNCE).timeout.connect(_on_save_debounce, CONNECT_ONE_SHOT)


func _on_save_debounce() -> void:
	if not _save_queued:
		return
	_save_queued = false
	_save_run()


func _flush_save_run() -> void:
	_save_queued = false
	_save_run()


func _save_run() -> void:
	if _mode == Mode.MINI:
		return
	if not is_node_ready() or not _board.can_save_run():
		return
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var section: String = _run_section()
	var data: Dictionary = _board.export_run()
	config.set_value(section, "active", true)
	config.set_value(section, "mode", int(_mode))
	config.set_value(section, "world", _world_index)
	config.set_value(section, "difficulty", int(_difficulty))
	config.set_value(section, "level", _journey_level)
	config.set_value(section, "elapsed", _elapsed_seconds)
	config.set_value(section, "givens", data["givens"])
	config.set_value(section, "solution", data["solution"])
	config.set_value(section, "values", data["values"])
	config.set_value(section, "notes", data["notes"])
	config.set_value(section, "undo", data["undo"])
	config.set_value(section, "selected", data["selected"])
	config.set_value(section, "score", data["score"])
	config.set_value(section, "streak", data["streak"])
	config.set_value(section, "notes_mode", data["notes_mode"])
	config.set_value(section, "algae", data.get("algae", PackedInt32Array()))
	config.set_value(section, "poison", data.get("poison", PackedInt32Array()))
	config.set_value(section, "cyber", data.get("cyber", PackedInt32Array()))
	config.set_value(section, "sand_caches", data.get("sand_caches", PackedInt32Array()))
	config.set_value(section, "ember_active", bool(data.get("ember_active", false)))
	config.set_value(section, "ember_heat", float(data.get("ember_heat", 0.0)))
	config.set_value(section, "ember_warned", _ember_warned)
	config.set_value(section, "hints", _hints_left)
	config.set_value(section, "puzzle_hints", _puzzle_hints_used)
	config.set_value(section, "puzzle_seals", _puzzle_seals_used)
	config.set_value(section, "puzzle_mistakes", _puzzle_mistakes)
	if _mode == Mode.JOURNEY:
		config.set_value(section, "lives", _relics.lives)
		config.set_value(section, "combo_streak", _relics.combo_place_streak)
		config.set_value(section, "relay_procs", _relics.relay_procs)
		config.set_value(section, "aegis_ready", _relics.aegis_ready)
		config.set_value(section, "second_wind", _relics.second_wind_ready)
		config.set_value(section, "phoenix_spent", _relics.phoenix_spent)
	config.set_value("prefs", "last_session", _last_session)
	config.save(SETTINGS_PATH)


func _clear_run() -> void:
	if _mode == Mode.MINI:
		return
	_clear_run_section(_run_section())


func _clear_run_section(section: String) -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	if not config.has_section(section):
		return
	config.erase_section(section)
	config.save(SETTINGS_PATH)


func _try_restore_run() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	var section: String = _run_section()
	if not bool(config.get_value(section, "active", false)):
		return false
	if int(config.get_value(section, "mode", -1)) != int(_mode):
		return false
	if _mode == Mode.JOURNEY:
		if int(config.get_value(section, "level", 0)) != _journey_level:
			return false
	else:
		if int(config.get_value(section, "world", -1)) != _world_index:
			return false
		if int(config.get_value(section, "difficulty", -1)) != int(_difficulty):
			return false
	var data := {
		"givens": _read_packed(config, section, "givens"),
		"solution": _read_packed(config, section, "solution"),
		"values": _read_packed(config, section, "values"),
		"notes": _read_packed(config, section, "notes"),
		"undo": _read_packed(config, section, "undo"),
		"selected": int(config.get_value(section, "selected", -1)),
		"score": int(config.get_value(section, "score", 0)),
		"streak": int(config.get_value(section, "streak", 0)),
		"notes_mode": bool(config.get_value(section, "notes_mode", false)),
		"algae": _read_packed(config, section, "algae"),
		"poison": _read_packed(config, section, "poison"),
		"cyber": _read_packed(config, section, "cyber"),
		"sand_caches": _read_packed(config, section, "sand_caches"),
		"ember_active": bool(config.get_value(section, "ember_active", false)),
		"ember_heat": clampf(float(config.get_value(section, "ember_heat", 0.0)), 0.0, 1.0),
	}
	if not _board.restore_run(data):
		_clear_run_section(section)
		return false
	_elapsed_seconds = maxf(0.0, float(config.get_value(section, "elapsed", 0.0)))
	_hints_left = clampi(int(config.get_value(section, "hints", _hints_budget())), 0, _hints_budget())
	_puzzle_hints_used = maxi(0, int(config.get_value(section, "puzzle_hints", 0)))
	_puzzle_seals_used = maxi(0, int(config.get_value(section, "puzzle_seals", 0)))
	_puzzle_mistakes = maxi(0, int(config.get_value(section, "puzzle_mistakes", 0)))
	_ember_warned = bool(config.get_value(section, "ember_warned", false))
	if _mode == Mode.JOURNEY:
		_relics.lives = clampi(int(config.get_value(section, "lives", _relics.lives_budget())), 0, _relics.lives_budget())
		_relics.combo_place_streak = maxi(0, int(config.get_value(section, "combo_streak", 0)))
		_relics.relay_procs = clampi(int(config.get_value(section, "relay_procs", 0)), 0, RelicManager.RELAY_CAP)
		_relics.aegis_ready = bool(config.get_value(section, "aegis_ready", _relics.has_relic(RelicManager.Relic.STEEL_SHIELD)))
		_relics.second_wind_ready = bool(config.get_value(section, "second_wind", _relics.has_relic(RelicManager.Relic.SECOND_WIND)))
		_relics.phoenix_spent = bool(config.get_value(section, "phoenix_spent", _relics.phoenix_spent))
	_board.set_mood_sources(_difficulty, _remaining_cells, _blanks_for_current(), true)
	return true


func _has_level_run(world: int, difficulty: Difficulty) -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	if not bool(config.get_value(RUN_LEVEL, "active", false)):
		return false
	return int(config.get_value(RUN_LEVEL, "world", -1)) == world and int(config.get_value(RUN_LEVEL, "difficulty", -1)) == int(difficulty)


func _difficulty_button_text(difficulty: Difficulty) -> String:
	var label: String = DIFFICULTY_NAMES[difficulty]
	if _has_level_run(_world_index, difficulty):
		return "%s · Resume" % label
	return label


func _read_packed(config: ConfigFile, section: String, key: String) -> PackedInt32Array:
	var value: Variant = config.get_value(section, key, PackedInt32Array())
	if value is PackedInt32Array:
		return value
	var packed := PackedInt32Array()
	if value is Array:
		for item in value:
			packed.append(int(item))
	return packed


func _load_high_scores() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	if not config.has_section("score"):
		return
	for key in config.get_section_keys("score"):
		if key == "high":
			continue
		_high_scores[String(key)] = maxi(0, int(config.get_value("score", key, 0)))


func _save_high_scores() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var key: String = _score_key()
	config.set_value("score", key, _high_scores.get(key, 0))
	config.save(SETTINGS_PATH)


func _load_journey_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_journey_progress = maxi(0, int(config.get_value("journey", "level", 0)))
	_journey_run_score = maxi(0, int(config.get_value("journey", "run_score", 0)))
	_journey_complete = bool(config.get_value("journey", "complete", false))
	_journey_pace = clampi(int(config.get_value("journey", "pace", JourneyPace.STANDARD)), 0, 1) as JourneyPace
	_economy.gold = maxi(0, int(config.get_value("journey", "gold", 0)))
	if _economy.gold > 8000:
		_economy.gold = clampi(int(_economy.gold / 40), 250, 1500)
	_relics.apply_mask(int(config.get_value("journey", "relics", 0)))
	_relics.shop_pending = bool(config.get_value("journey", "shop_pending", false))
	_relics.phoenix_spent = bool(config.get_value("journey", "phoenix_spent", false))
	_relics.pending_lives = maxi(0, int(config.get_value("journey", "pending_lives", 0)))
	_relics.pending_hints = maxi(0, int(config.get_value("journey", "pending_hints", 0)))
	_relics.apply_tools(String(config.get_value("journey", "tools", "")))
	_journey_stars = _stars_from_text(String(config.get_value("journey", "stars", "")))
	_ensure_star_slots()
	if _journey_progress > _journey_length():
		_journey_complete = true
	if _journey_complete:
		# Rest is only for this sitting. Next launch is a fresh walk from Desert.
		_journey_complete = false
		_journey_progress = 1
		_journey_run_score = 0
		_economy.reset()
		_relics.reset_run()
		_save_journey_progress()


func _save_journey_progress() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("journey", "level", _journey_progress)
	config.set_value("journey", "run_score", _journey_run_score)
	config.set_value("journey", "complete", _journey_complete)
	config.set_value("journey", "pace", int(_journey_pace))
	config.set_value("journey", "gold", _economy.gold)
	config.set_value("journey", "relics", _relics.owned_mask())
	config.set_value("journey", "shop_pending", _relics.shop_pending)
	config.set_value("journey", "phoenix_spent", _relics.phoenix_spent)
	config.set_value("journey", "pending_lives", _relics.pending_lives)
	config.set_value("journey", "pending_hints", _relics.pending_hints)
	config.set_value("journey", "tools", _relics.tools_to_text())
	config.set_value("journey", "stars", _stars_to_text())
	config.save(SETTINGS_PATH)


func _load_prefs() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_haptics_enabled = bool(config.get_value("prefs", "haptics", true))
		_music_volume = clampf(float(config.get_value("prefs", "music", 1.0)), 0.0, 1.0)
		_sounds_volume = clampf(float(config.get_value("prefs", "sounds", 1.0)), 0.0, 1.0)
		_night_mode = bool(config.get_value("prefs", "night", false))
		_check_mistakes = bool(config.get_value("prefs", "show_mistakes", false))
		_last_session = String(config.get_value("prefs", "last_session", ""))
		_streak_days = maxi(0, int(config.get_value("prefs", "streak_days", 0)))
		_streak_date = String(config.get_value("prefs", "streak_date", ""))
		_puzzles_cleared = maxi(0, int(config.get_value("prefs", "puzzles_cleared", 0)))
	_apply_haptics()
	_apply_audio_mix()
	_apply_check()


func _save_prefs() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("prefs", "haptics", _haptics_enabled)
	config.set_value("prefs", "music", _music_volume)
	config.set_value("prefs", "sounds", _sounds_volume)
	config.set_value("prefs", "night", _night_mode)
	config.set_value("prefs", "show_mistakes", _check_mistakes)
	config.set_value("prefs", "last_session", _last_session)
	config.set_value("prefs", "streak_days", _streak_days)
	config.set_value("prefs", "streak_date", _streak_date)
	config.set_value("prefs", "puzzles_cleared", _puzzles_cleared)
	config.save(SETTINGS_PATH)


func _apply_win_copy() -> void:
	if _journey_failed:
		_win_label.text = "OUT OF LIVES"
		_win_label.add_theme_font_size_override("font_size", 52)
		_ask_label.text = "Relics stay. Retry this stage?"
		_ask_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.42))
		_yes_button.visible = true
		_yes_button.text = "Retry"
		_no_button.text = "Menu"
		return
	if _is_journey_finale():
		_win_label.text = "The journey\nis finished."
		_win_label.add_theme_font_size_override("font_size", 52)
		_ask_label.text = "Take a rest."
		_ask_label.add_theme_color_override("font_color", Color(0.86, 0.72, 1.0))
		_yes_button.visible = false
		_no_button.text = "Rest"
		return
	_win_label.text = "YOU WON!"
	_win_label.remove_theme_font_size_override("font_size")
	_yes_button.visible = true
	if _mode == Mode.JOURNEY:
		var next_level: int = _journey_level + 1
		var next_look: WorldLook = _journey_look(next_level)
		var next_name: String = DIFFICULTY_NAMES[_difficulty_for_level(next_level)]
		if _journey_world_index(next_level) == _journey_world_index(_journey_level):
			_ask_label.text = "Next in %s · %s?" % [next_look.title, next_name]
		else:
			_ask_label.text = "Enter %s · %s?" % [next_look.title, next_name]
		if _relics.shop_pending:
			_ask_label.text = "Shop, then %s" % _ask_label.text.to_lower()
		_ask_label.add_theme_color_override("font_color", next_look.ink)
		_yes_button.text = "Next"
		_no_button.text = "Menu"
	elif _mode == Mode.QUICK:
		var look: WorldLook = _world_at(_world_index)
		_ask_label.text = "Another random puzzle?"
		if look != null:
			_ask_label.add_theme_color_override("font_color", look.ink)
		_yes_button.text = "Play"
		_no_button.text = "Menu"
	elif _mode == Mode.MINI:
		_win_label.text = "TIME'S UP!"
		_win_label.add_theme_font_size_override("font_size", 58)
		var look: WorldLook = _world_at(_world_index)
		_ask_label.text = "Race again?"
		if look != null:
			_ask_label.add_theme_color_override("font_color", look.ink)
		_yes_button.text = "Play"
		_no_button.text = "Menu"
	else:
		_ask_label.text = "Play again?"
		_ask_label.remove_theme_color_override("font_color")
		_yes_button.text = "Again"
		_no_button.text = "Worlds"


func _cleared_line() -> String:
	var clock: String = _format_time(_elapsed_seconds)
	if _mode == Mode.JOURNEY:
		var look: WorldLook = _journey_look(_journey_level)
		return "%s · %s · %s\n%s" % [look.title, DIFFICULTY_NAMES[_difficulty], clock, _star_sentence()]
	if _mode == Mode.MINI:
		return "%s Mini %s in %s · %d pts" % [_world_at(_world_index).title, DIFFICULTY_NAMES[_difficulty], clock, _board.score]
	return "%s %s cleared in %s · %d pts" % [_world_at(_world_index).title, DIFFICULTY_NAMES[_difficulty], clock, _board.score]


func _update_status() -> void:
	var clock: String = _format_time(_elapsed_seconds)
	_status_label.add_theme_color_override("font_color", _chrome.ink)
	if _mode == Mode.JOURNEY:
		var look: WorldLook = _journey_look(_journey_level)
		if _board.ember_active():
			_status_label.text = "HEAT %d%% · ♥%d · %dg · %s" % [int(round(_board.ember_heat * 100.0)), _relics.lives, _economy.gold, clock]
		else:
			_status_label.text = "%s · ♥%d · %dg · %s" % [look.title, _relics.lives, _economy.gold, clock]
	elif _mode == Mode.MINI:
		var flash: float = clampf(_race_clock_flash, 0.0, 1.0)
		_status_label.text = "%s  ·  %d pts  ·  %d" % [_format_time(_race_seconds), _mini_race_score, _mini_clears]
		if flash > 0.04:
			var hit: Color = Color(1.0, 0.86, 0.34) if _race_clock_good else Color(1.0, 0.38, 0.34)
			_status_label.add_theme_color_override("font_color", hit.lerp(_chrome.ink, 1.0 - flash))
	else:
		_status_label.text = "%s · %s · %d · %s · %d left" % [_world_at(_world_index).title, DIFFICULTY_NAMES[_difficulty], _board.score, clock, _remaining_cells]


func _mini_race_summary() -> String:
	var puzzles: String = "1 puzzle" if _mini_clears == 1 else "%d puzzles" % _mini_clears
	return "%s · %d pts" % [puzzles, _mini_race_score]


func _session_name() -> String:
	match _mode:
		Mode.JOURNEY:
			return "journey"
		Mode.QUICK:
			return "quick"
		Mode.MINI:
			return "mini"
		_:
			return "level"


func _blanks_for_current() -> int:
	var table: Array[int] = DIFFICULTY_BLANKS
	if _mode == Mode.MINI:
		table = WIDE_BLANKS if _race_grid == SudokuGenerator.WIDE_SIZE else MINI_BLANKS
	var index: int = clampi(int(_difficulty), 0, table.size() - 1)
	return table[index]


func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	@warning_ignore("integer_division")
	var minutes: int = total / 60
	return "%02d:%02d" % [minutes, total % 60]


func _race_size_label() -> String:
	return "6×6" if _race.grid_size == SudokuGenerator.WIDE_SIZE else "4×4"


func _race_start_seconds() -> float:
	return RaceModeManager.START_SECONDS


func _race_bonus_seconds() -> float:
	return _race.bonus_for(_race.grid_size)


func _race_cap_seconds() -> float:
	return RaceModeManager.CAP_SECONDS


func _sync_race_clock() -> void:
	_race_seconds = _race.seconds
	_race_grid = _race.grid_size


func _prepare_race_menu() -> void:
	_race_mini_button.text = "Play"
	_race_wide_button.visible = false
	var hint := _race_menu.get_node_or_null("Center/VBox/Hint") as Label
	if hint != null:
		hint.text = "60 seconds. 4×4 warms up, then 6×6 spikes in. Clears add +19 / +29. Wrong −4s."


func _merge_race_high_scores() -> void:
	var race4: int = int(_high_scores.get("mini_race", 0))
	var race6: int = int(_high_scores.get("mini_race_6", 0))
	if race6 > race4:
		_high_scores["mini_race"] = race6


func _refresh_home_cta() -> void:
	if not is_instance_valid(_journey_button):
		return
	var can_continue: bool = not _journey_complete and _journey_progress >= 1
	if can_continue:
		_journey_button.text = "Continue · Level %d" % _journey_progress
	else:
		_journey_button.text = "Journey Mode"
	if is_instance_valid(_journey_links):
		_journey_links.visible = can_continue
	if is_instance_valid(_home_new_button):
		if _confirm_new_journey:
			_home_new_button.text = "Start over?"
			_home_new_button.add_theme_color_override("font_color", Color(1.0, 0.45, 0.42, 1.0))
		else:
			_home_new_button.text = "New Game"
			_home_new_button.add_theme_color_override("font_color", Color(0.93, 0.78, 0.42, 0.82))
	if is_node_ready():
		_apply_safe_area()


func _start_logo_float() -> void:
	if _logo_tween != null and _logo_tween.is_valid():
		return
	if not is_instance_valid(_logo_float):
		return
	_logo_float.position.x = 0.0
	_logo_float.position.y = 0.0
	_logo_tween = create_tween()
	_logo_tween.set_loops()
	_logo_tween.set_trans(Tween.TRANS_SINE)
	_logo_tween.set_ease(Tween.EASE_IN_OUT)
	_logo_tween.tween_property(_logo_float, "position:y", -10.0, 2.4)
	_logo_tween.tween_property(_logo_float, "position:y", 10.0, 2.4)


func _today_key() -> String:
	var date: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(date.get("year", 0)), int(date.get("month", 0)), int(date.get("day", 0))]


func _yesterday_key() -> String:
	var unix: int = int(Time.get_unix_time_from_system()) - 86400
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [int(date.get("year", 0)), int(date.get("month", 0)), int(date.get("day", 0))]


func _visible_streak() -> int:
	var today: String = _today_key()
	if _streak_date == today or _streak_date == _yesterday_key():
		return _streak_days
	return 0


func _refresh_streak_label() -> void:
	if not is_instance_valid(_streak_count):
		return
	_streak_count.text = str(_visible_streak())


func _touch_daily_streak(flush: bool = true) -> void:
	var today: String = _today_key()
	_puzzles_cleared += 1
	if _streak_date != today:
		if _streak_date == _yesterday_key():
			_streak_days += 1
		else:
			_streak_days = 1
		_streak_date = today
	if flush:
		_save_prefs()
	_refresh_streak_label()


func _refresh_profile() -> void:
	var streak: int = _visible_streak()
	var streak_line: String = "1 day streak" if streak == 1 else "%d day streak" % streak
	var puzzles: String = "1 puzzle cleared" if _puzzles_cleared == 1 else "%d puzzles cleared" % _puzzles_cleared
	var path: String
	if not _journey_complete and _journey_progress >= 1:
		var look: WorldLook = _journey_look(_journey_progress)
		path = "Journey  ·  Level %d  ·  %s" % [_journey_progress, look.title]
	else:
		path = "Journey  ·  ready to begin"
	var race_best: int = int(_high_scores.get("mini_race", 0))
	var journey_best: int = int(_high_scores.get("journey", 0))
	_profile_stats.text = "%s\n%s\n%s\n%s\nJourney stars  ·  %d / %d\nBest journey  ·  %d\nRace  ·  %d" % [
		streak_line, puzzles, path, _relics.catalog_line(), _star_total(), _star_cap(), journey_best, race_best
	]


func _refresh_leaderboard() -> void:
	for child in _board_list.get_children():
		_board_list.remove_child(child)
		child.free()
	var rows: Array[PackedStringArray] = []
	rows.append(PackedStringArray(["Journey", str(int(_high_scores.get("journey", 0)))]))
	rows.append(PackedStringArray(["Race", str(int(_high_scores.get("mini_race", 0)))]))
	for look in worlds:
		if look == null:
			continue
		var slug: String = look.title.strip_edges().to_lower().replace(" ", "_")
		var best: int = 0
		for difficulty_name in DIFFICULTY_NAMES:
			best = maxi(best, int(_high_scores.get("%s_%s" % [slug, difficulty_name.to_lower()], 0)))
		rows.append(PackedStringArray([look.title, str(best)]))
	for row in rows:
		var line := Label.new()
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_font_size_override("font_size", 24)
		var score: int = int(row[1])
		if score <= 0:
			line.add_theme_color_override("font_color", Color(0.62, 0.58, 0.74, 1.0))
			line.text = "%s  ·  —" % row[0]
		else:
			line.add_theme_color_override("font_color", Color(0.93, 0.86, 0.62, 1.0))
			line.text = "%s  ·  %d" % [row[0], score]
		_board_list.add_child(line)
