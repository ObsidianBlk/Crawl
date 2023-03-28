extends Control

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
var ARROW_RIGHT : Texture = preload("res://assets/icons/arrow_right.svg")
var ARROW_DOWN : Texture = preload("res://assets/icons/arrow_down.svg")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _ops_visible : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _graphic_options : Control = %Graphics
@onready var _viz_toggle_btn : Button = %VizToggle
@onready var _gop_ssao : CheckButton = %GOP_SSAO
@onready var _gop_ssil : CheckButton = %GOP_SSIL
@onready var _gop_fog : CheckButton = %GOP_Fog
@onready var _gop_vfog : CheckButton = %GOP_VFog

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	CrawlGlobals.crawl_config_loaded.connect(_on_config_changed)
	CrawlGlobals.crawl_config_reset.connect(_on_config_changed)
	CrawlGlobals.crawl_config_value_changed.connect(_on_config_value_changed)
	
	_gop_ssao.toggled.connect(_on_gop_pressed.bind("Graphics", "SSAO"))
	_gop_ssil.toggled.connect(_on_gop_pressed.bind("Graphics", "SSIL"))
	_gop_fog.toggled.connect(_on_gop_pressed.bind("Graphics", "Fog"))
	_gop_vfog.toggled.connect(_on_gop_pressed.bind("Graphics", "VFog"))
	_UpdateVisible()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateVisible() -> void:
	_graphic_options.visible = _ops_visible
	_viz_toggle_btn.icon = ARROW_DOWN if _ops_visible else ARROW_RIGHT

func _SetFromSettings() -> void:
	_gop_ssao.button_pressed = CrawlGlobals.Get_Config_Value("Graphics", "SSAO", true)
	_gop_ssil.button_pressed = CrawlGlobals.Get_Config_Value("Graphics", "SSIL", true)
	_gop_fog.button_pressed = CrawlGlobals.Get_Config_Value("Graphics", "Fog", true)
	_gop_vfog.button_pressed = CrawlGlobals.Get_Config_Value("Graphics", "VFog", true)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_config_changed(section : String = "") -> void:
	_SetFromSettings.call_deferred()

func _on_config_value_changed(section : String, key : String, value : Variant) -> void:
	if typeof(value) != TYPE_BOOL: return
	
	match section:
		"Graphics":
			match key:
				"SSAO":
					_gop_ssao.button_pressed = value
				"SSIL":
					_gop_ssil.button_pressed = value
				"Fog":
					_gop_fog.button_pressed = value
				"VFog":
					_gop_vfog.button_pressed = value

func _on_viz_toggle_pressed():
	_ops_visible = not _ops_visible
	_UpdateVisible()

func _on_gop_pressed(button_pressed : bool, section : String, key : String) -> void:
	CrawlGlobals.Set_Config_Value(section, key, button_pressed)

func _on_save_settings_pressed():
	CrawlGlobals.Save_Config()
