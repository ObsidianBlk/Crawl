extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal config_loaded()
signal config_saved()
signal config_reset_requested()
signal config_value_changed(section, key, value)

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
	_config = ConfigFile.new()
	#var res : int = load_config()
	#if res != OK:
	#	_config = ConfigFile.new()
	#	print("WARNING: Config file failed to load.")


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reset() -> void:
	_config.clear()
	config_reset_requested.emit()


func load_config(filepath : String = USER_CONFIG_PATH_DEFAULT) -> int:
	var c : ConfigFile = ConfigFile.new()
	var res : int = c.load(filepath)
	if res != OK:
		return res
	
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

func set_value(section : String, key : String, value : Variant) -> void:
	if _config == null: return
	_config.set_value(section, key, value)
	config_value_changed.emit(section, key, value)

func get_value(section : String, key : String, default : Variant = null) -> Variant:
	if _config == null: return default
	return _config.get_value(section, key, default)
