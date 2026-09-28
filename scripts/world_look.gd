class_name WorldLook
extends Resource
## Inspector knobs for one world on the Levels list.

enum Style { DESERT, WATER, NIGHT, FOREST, EMBER, RAIN }

@export var title: String = "World"
@export var style: Style = Style.NIGHT
@export var ink: Color = Color(0.96, 0.55, 1.0)
## Journey walks the worlds that keep this on. Worlds-menu extras stay off.
@export var in_journey: bool = true

@export_group("Audio")
## Bed for this world. Plays from the start, then repeats only after it finishes.
@export var ambience: AudioStream
## Bus name from the Audio panel (Desert, Water, Neon, Forest, Ember, Rain).
@export var ambience_bus: String = "Ambience"

@export_group("Ambient Particles")
## How many motes and how bright they are.
@export_range(0.0, 2.0, 0.05) var particle_strength: float = 0.7
## How large those motes are. 1 is the designed size.
@export_range(0.4, 2.4, 0.05) var particle_size: float = 1.0

@export_group("Burst Particles")
## How many motes fly off a finished row, column, or box.
@export_range(0.0, 2.0, 0.05) var burst_strength: float = 1.0
## How large those motes are. 1 is the designed size for this world.
@export_range(0.2, 2.4, 0.05) var burst_size: float = 1.0
## 0 is a filled spark. 1 is a hollow ring, for bubbles.
@export_range(0.0, 1.0, 0.05) var burst_hollow: float = 0.0
## Downward pull after the pop. Raise this so sand falls.
@export_range(0.0, 2.5, 0.05) var burst_fall: float = 0.0
