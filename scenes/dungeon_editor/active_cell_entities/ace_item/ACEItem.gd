extends PanelContainer


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal selection_changed(uuid, selected)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ARROW_NORTH : Texture = preload("res://assets/icons/arrow_up.svg")
const ARROW_EAST : Texture = preload("res://assets/icons/arrow_right.svg")
const ARROW_SOUTH : Texture = preload("res://assets/icons/arrow_down.svg")
const ARROW_WEST : Texture = preload("res://assets/icons/arrow_left.svg")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var uuid : StringName = &""
@export var type : StringName = &"":										set = set_type
@export var entity_name : String = "":										set = set_entity_name
@export var facing : CrawlGlobals.SURFACE = CrawlGlobals.SURFACE.North:		set = set_facing

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _facing_indicator : TextureRect = $Layout/FacingIndicator
@onready var _label_type : Label = $Layout/LabelType

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_type(t : StringName) -> void:
	if t != type:
		type = t
		_UpdateValues()

func set_entity_name(en : String) -> void:
	if en != entity_name:
		entity_name = en
		_UpdateValues()

func set_facing(f : CrawlGlobals.SURFACE) -> void:
	if f != facing and CrawlGlobals.ALL_COMPASS_SURFACES & f != 0:
		facing = f
		_UpdateValues()


# ------------------------------------------------------------------------------
# Onready Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateValues()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateValues() -> void:
	if _facing_indicator == null or _label_type == null: return
	if entity_name.is_empty():
		_label_type.text = String(type)
	else:
		_label_type.text = "%s [ %s ]"%[entity_name, type]
	match facing:
		CrawlGlobals.SURFACE.North:
			_facing_indicator.texture = ARROW_NORTH
		CrawlGlobals.SURFACE.East:
			_facing_indicator.texture = ARROW_EAST
		CrawlGlobals.SURFACE.South:
			_facing_indicator.texture = ARROW_SOUTH
		CrawlGlobals.SURFACE.West:
			_facing_indicator.texture = ARROW_WEST

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_select_check_box_toggled(button_pressed : bool):
	selection_changed.emit(uuid, button_pressed)
