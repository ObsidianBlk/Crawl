extends Node3D


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _dungeon : Node3D = $Dungeon

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Settings.config_reset_requested.connect(_on_config_reset_requested)
	
	if Settings.load_config() != OK:
		Settings.reset()
		Settings.save_config()
	
	if _dungeon.load_dungeon("user://map.tres") != OK:
		_dungeon.create_default()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_config_reset_requested() -> void:
	Settings.set_value("Graphics", "SSAO", true)
	Settings.set_value("Graphics", "SSIL", true)
	Settings.set_value("Graphics", "Fog", true)
	Settings.set_value("Graphics", "VFog", true)
