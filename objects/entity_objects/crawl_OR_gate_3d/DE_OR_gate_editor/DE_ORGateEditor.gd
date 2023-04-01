extends Control

# --
# OR Gate
# --

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null:				set = set_entity



# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _available_trigger_connections : Control = $AvailableTriggerConnections


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
