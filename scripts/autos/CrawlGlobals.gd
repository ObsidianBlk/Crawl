extends Node


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# DUNGEON MAP CELL SURFACE CONSTANTS & HELPER METHODS
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# --- SIGNALS
signal crawl_config_loaded()
signal crawl_config_saved()
signal crawl_config_reset(section)
signal crawl_config_value_changed(section, key, value)

# --- PRIVATE VARIABLES
var _config_file_path : String = "user://crawl_settings.ini"
var _config : ConfigFile = null
var _config_dirty : bool = false
var _section_handlers : Dictionary = {
	"Graphics":[
		(func(config : ConfigFile, section : String, only_if_missing : bool = false):
			if config == null: return
			if section.is_empty(): return
			
			if not config.has_section_key(section, "SSAO") or not only_if_missing:
				config.set_value(section, "SSAO", true)
			if not config.has_section_key(section, "SSIL") or not only_if_missing:
				config.set_value(section, "SSIL", true)
			if not config.has_section_key(section, "Fog") or not only_if_missing:
				config.set_value(section, "Fog", true)
			if not config.has_section_key(section, "VFog") or not only_if_missing:
				config.set_value(section, "VFog", true))
	],
	
	"Gameplay":[
		(func(config : ConfigFile, section : String, only_if_missing : bool = false):
			if config == null: return
			if section.is_empty(): return
			if not config.has_section_key(section, "look_toward_stairs") or not only_if_missing:
				config.set_value(section, "look_toward_stairs", true))	
	],
	
	"Dungeon_Editor":[
		(func(config : ConfigFile, section : String, only_if_missing : bool = false):
			if config == null: return
			if section.is_empty(): return
			if not config.has_section_key(section, "ignore_collisions") or not only_if_missing:
				config.set_value(section, "ignore_collisions", true)
			if not config.has_section_key(section, "ignore_transitions") or not only_if_missing:
				config.set_value(section, "ignore_transitions", false))
	],
}

# --- PUBLIC METHODS
func Register_Config_Section_Handler(section : String, handler : Callable, auto_call : bool = false) -> void:
	if section.is_empty(): return
	if not section in _section_handlers:
		_section_handlers[section] = [handler]
		return
	for hdlr in _section_handlers[section]:
		if hdlr == handler:
			return
	_section_handlers[section].append(handler)
	if auto_call and _config != null:
		handler.call(_config, section)

func Reset_Config(section : String = "", only_if_missing : bool = false) -> void:
	if _config == null:
		_config = ConfigFile.new()
	
	if section.is_empty():
		for sec in _section_handlers.keys():
			for handler in _section_handlers[sec]:
				if typeof(handler) != TYPE_CALLABLE: continue
				handler.call(_config, sec, only_if_missing)
	elif section in _section_handlers:
		for handler in _section_handlers[section]:
			if typeof(handler) != TYPE_CALLABLE: continue
			handler.call(_config, section, only_if_missing)
	crawl_config_reset.emit(section)

func Get_Config_Filepath() -> String:
	return _config_file_path

func Set_Config_Filepath(filepath : String) -> void:
	if (filepath.is_absolute_path() or filepath.is_relative_path()) and filepath.is_valid_filename():
		_config_file_path = filepath

func Load_Config(filepath : String = "") -> int:
	if filepath.is_empty():
		filepath = _config_file_path
	
	var c : ConfigFile = ConfigFile.new()
	var res : int = c.load(filepath)
	if res != OK:
		return res
	
	_config = c
	Reset_Config("", true)
	_config_dirty = false
	if filepath != _config_file_path:
		_config_file_path = filepath
	crawl_config_loaded.emit()
	return OK

func Save_Config(filepath : String = "") -> int:
	if _config == null:
		Reset_Config()
	if filepath.is_empty():
		filepath = _config_file_path
		
	var res : int = _config.save(filepath)
	if res != OK:
		return res
	if filepath != _config_file_path:
		_config_file_path = filepath
	_config_dirty = false
	crawl_config_saved.emit()
	return OK

func Get_Config_Value(section : String, key : String, default : Variant = null) -> Variant:
	if _config == null: return default
	return _config.get_value(section, key, default)

func Set_Config_Value(section : String, key : String, value : Variant) -> void:
	if _config == null:
		Reset_Config()
	if section.is_empty() or key.is_empty(): return
	if not section in _section_handlers:
		printerr("CRAWL CONFIG WARNING: Setting value for unhandled section \"%s.%s\"."%[section, key])
	_config.set_value(section, key, value)
	_config_dirty = true
	crawl_config_value_changed.emit(section, key, value)

func Has_Config_Section(section : String) -> bool:
	if _config == null: return false
	return _config.has_section(section)

func Get_Config_Sections() -> PackedStringArray:
	if _config == null:
		Reset_Config()
	return _config.get_sections()

func Has_Config_Section_Key(section : String, key : String) -> bool:
	if _config == null: return false
	return _config.has_section_key(section, key)

func Get_Config_Section_Keys(section : String) -> PackedStringArray:
	if _config == null:
		Reset_Config()
	return _config.get_section_keys(section)

func Is_Config_Dirty() -> bool:
	return _config_dirty

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# COMBAT CONSTANTS & HELPER METHODS
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# --- CONSTANTS & ENUMS
enum ATTACK_TYPE {Physical=0, Fire=100, Water=101, Earth=102, Air=103}




# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# DUNGEON MAP CELL SURFACE CONSTANTS & HELPER METHODS
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# --- CONSTANTS & ENUMS
enum SURFACE {North=0x01, East=0x02, South=0x04, West=0x08, Ground=0x10, Ceiling=0x20}
const ALL_COMPASS_SURFACES : int = 15
const ALL_SURFACES : int = 63

# --- PUBLIC METHODS
func Get_Surface_Index(surface : SURFACE) -> int:
	return SURFACE.values().find(surface)

func Get_Adjacent_Surface(surface : SURFACE) -> SURFACE:
	match surface:
		SURFACE.North:
			return SURFACE.South
		SURFACE.East:
			return SURFACE.West
		SURFACE.South:
			return SURFACE.North
		SURFACE.West:
			return SURFACE.East
		SURFACE.Ground:
			return SURFACE.Ceiling
		SURFACE.Ceiling:
			return SURFACE.Ground
	return surface

func Get_Direction_From_Surface(surface : SURFACE) -> Vector3i:
	match surface:
		SURFACE.North:
			return Vector3i(0,0,1)
		SURFACE.East:
			return Vector3i(-1,0,0)
		SURFACE.South:
			return Vector3i(0,0,-1)
		SURFACE.West:
			return Vector3i(1,0,0)
		SURFACE.Ground:
			return Vector3i(0,-1,0)
		SURFACE.Ceiling:
			return Vector3i(0,1,0)
	return Vector3i.ZERO

func Get_Surface_From_Direction(dir : Vector3) -> SURFACE:
	dir = dir.normalized()
	var deg45 : float = deg_to_rad(45.0)
	if dir.angle_to(Vector3(0,0,1)) < deg45:
		return SURFACE.North
	if dir.angle_to(Vector3(-1,0,0)) < deg45:
		return SURFACE.East
	if dir.angle_to(Vector3(0,0,-1)) < deg45:
		return SURFACE.South
	if dir.angle_to(Vector3(1,0,0)) < deg45:
		return SURFACE.West
	if dir.angle_to(Vector3(0,1,0)) < deg45:
		return SURFACE.Ceiling
	return SURFACE.Ground

func Get_Surface_90Deg(surface : SURFACE, amount : int) -> SURFACE:
	if surface & 0x0F == 0: return surface # Only North, South, East, and West will work
	
	var dir : Vector3 = Vector3(Get_Direction_From_Surface(surface))
	dir = dir.rotated(Vector3.UP, deg_to_rad(90.0 * float(amount)))
	return Get_Surface_From_Direction(dir)

func Get_Angle_From_Surface_To_Surface(from : SURFACE, to : SURFACE) -> float:
	if from == to: return 0.0
	var deg90 : float = deg_to_rad(90)
	match from:
		SURFACE.North:
			match to:
				SURFACE.East, SURFACE.West:
					return deg90 if to == SURFACE.West else -deg90
				SURFACE.South:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.East:
			match to:
				SURFACE.South, SURFACE.North:
					return deg90 if to == SURFACE.North else -deg90
				SURFACE.West:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.South:
			match to:
				SURFACE.East, SURFACE.West:
					return deg90 if to == SURFACE.East else -deg90
				SURFACE.North:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.West:
			match to:
				SURFACE.South, SURFACE.North:
					return deg90 if to == SURFACE.South else -deg90
				SURFACE.East:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.Ground:
			return deg90 * 2 if to == SURFACE.Ceiling else deg90
		SURFACE.Ceiling:
			return deg90 * 2 if to == SURFACE.Ground else deg90
	return 0.0


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# DUNGEON EDITOR IDENTIFIER
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

var _editor_mode: bool = false

func Set_Editor_Mode(enable : bool) -> void:
	_editor_mode = enable

func In_Editor_Mode() -> bool:
	return _editor_mode
