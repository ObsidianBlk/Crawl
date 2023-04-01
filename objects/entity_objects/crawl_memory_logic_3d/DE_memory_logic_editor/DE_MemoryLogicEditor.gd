extends Control


# --
# Memory Logic
# --

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const META_KEY_INIT_MEMORY : String = "initial_memory"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null:				set = set_entity



# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _available_trigger_connections : Control = $AvailableTriggerConnections
@onready var _check_init_memory_state : CheckButton = $Check_InitMemoryState


# ------------------------------------------------------------------------------
# Settings
# ------------------------------------------------------------------------------
func set_entity(e : CrawlEntity) -> void:
	if e != entity:
		entity = e
		_UpdateControls()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateControls()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateControls() -> void:
	if _available_trigger_connections == null: return
	_available_trigger_connections.entity = entity
	if entity == null:
		_check_init_memory_state.button_pressed = false
	else:
		_check_init_memory_state.button_pressed = entity.get_meta_value(META_KEY_INIT_MEMORY, false)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_check_init_memory_state_toggled(button_pressed : bool) -> void:
	if entity == null: return
	entity.set_meta_value(META_KEY_INIT_MEMORY, button_pressed)
