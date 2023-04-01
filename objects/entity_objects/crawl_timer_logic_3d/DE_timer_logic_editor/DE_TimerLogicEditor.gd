extends Control


# --
# Timer Logic
# --

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const META_KEY_INTERVAL : String = "timer_interval"


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null:				set = set_entity


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _available_trigger_connections : Control = $AvailableTriggerConnections
@onready var _lineedit_timerinterval : LineEdit = %LineEdit_TimerInterval


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
	
	if entity != null:
		_lineedit_timerinterval.text = "%s"%[entity.get_meta_value(META_KEY_INTERVAL, 1.0)]

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_line_edit_timer_interval_text_submitted(new_text : String) -> void:
	if new_text.is_empty(): return
	if new_text.is_valid_float():
		entity.set_meta_value(META_KEY_INTERVAL, new_text.to_float())
	else:
		_lineedit_timerinterval.text = "%s"%[entity.get_meta_value(META_KEY_INTERVAL, 1.0)]
