extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal config_loaded()
signal config_saved()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const USER_CONFIG_PATH_DEFAULT : String = "user://game.cfg"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _config : ConfigFile = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	var res : int = load_config()
	if res != OK:
		_config = ConfigFile.new()
		print("WARNING: Config file failed to load.")


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func load_config(filepath : String = USER_CONFIG_PATH_DEFAULT) -> int:
	var c : ConfigFile = ConfigFile.new()
	var res : int = c.load(filepath)
	if res != OK:
		c.free()
		return res
	
	if _config != null:
		_config.free()
	_config = c
	config_loaded.emit()
	return OK


func save_config(filepath : String = USER_CONFIG_PATH_DEFAULT) -> int:
	if _config != null:
		var res : int = _config.save(filepath)
		if res != OK:
			return res
		config_saved.emit()
		
	return OK

