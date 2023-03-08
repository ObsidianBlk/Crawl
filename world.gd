extends Node3D


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var cmv : Node3D = $CrawlMapView
@onready var cmm : CrawlMiniMap = $CanvasLayer/CrawlMiniMap
@onready var player : Node3D = $Player
@onready var wenv : WorldEnvironment = $WorldEnvironment

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Settings.config_reset_requested.connect(_on_config_reset_requested)
	Settings.config_value_changed.connect(_on_config_value_changed)
	Settings.config_loaded.connect(_on_config_loaded)
	
	if Settings.load_config() != OK:
		Settings.reset()
		Settings.save_config()
	
	var cm : CrawlMap = CrawlMap.new()
	
	cm.add_resource(&"tileA")
	cm.add_resource(&"tileB")
	
	#cm.dig_room(Vector3i(0,1,0), Vector3i(1,1,1), 1,1,0)
	cm.dig_room(Vector3i(-3, 1, -3), Vector3i(6, 1, 6), 1, 1, 0)
	cm.dig_room(Vector3i(4, 1, -3), Vector3i(1, 1, 6), 1, 1, 0)
	cm.set_focus_cell(Vector3i(0,1,0))
	
	
	cmv.map = cm
	cmm.map = cm
	cmm.origin = Vector3i(0,1,0)
	player.map = cm


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateEnvironment(sec_key : String, value : bool) -> void:
	if wenv == null: return
	
	var env = wenv.environment
	if env == null: return
	
	match sec_key:
		"Graphics:SSAO":
			env.ssao_enabled = value
		"Graphics:SSIL":
			env.ssil_enabled = value
		"Graphics:Fog":
			env.fog_enabled = value
		"Graphics:VFog":
			env.volumetric_fog_enabled = value

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_config_reset_requested() -> void:
	Settings.set_value("Graphics", "SSAO", true)
	Settings.set_value("Graphics", "SSIL", true)
	Settings.set_value("Graphics", "Fog", true)
	Settings.set_value("Graphics", "VFog", true)

func _on_config_loaded() -> void:
	_UpdateEnvironment("Graphics:SSAO", Settings.get_value("Graphics", "SSAO", true))
	_UpdateEnvironment("Graphics:SSIL", Settings.get_value("Graphics", "SSIL", true))
	_UpdateEnvironment("Graphics:FOG", Settings.get_value("Graphics", "FOG", true))
	_UpdateEnvironment("Graphics:VFog", Settings.get_value("Graphics", "VFog", true))

func _on_config_value_changed(section : String, key : String, value : Variant) -> void:
	if typeof(value) != TYPE_BOOL: return
	var sec_key = "%s:%s"%[section, key]
	_UpdateEnvironment(sec_key, value)
