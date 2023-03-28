extends PopupPanel


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CONFIG_SECTION : String = "Dungeon_Editor"
const CONFIG_KEY_IGNORE_COLLISION : String = "ignore_collisions"
const CONFIG_KEY_IGNORE_TRANSITIONS : String = "ignore_transitions"


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _check_collisions : CheckButton = %Check_Collisions
@onready var _check_transitions : CheckButton = %Check_Transitions

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	CrawlGlobals.crawl_config_loaded.connect(_on_config_changed)
	CrawlGlobals.crawl_config_reset.connect(_on_config_changed)
	CrawlGlobals.crawl_config_value_changed.connect(_on_config_value_changed)
	_on_config_changed()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_visibility_changed() -> void:
	if visible:
		_on_config_changed()

func _on_config_changed(_section : String = "") -> void:
	_check_collisions.button_pressed = CrawlGlobals.Get_Config_Value(
		CONFIG_SECTION, CONFIG_KEY_IGNORE_COLLISION, true
	)
	_check_transitions.button_pressed = CrawlGlobals.Get_Config_Value(
		CONFIG_SECTION, CONFIG_KEY_IGNORE_TRANSITIONS, false
	)

func _on_config_value_changed(section : String, key : String, value : Variant) -> void:
	if section != CONFIG_SECTION: return
	match key:
		CONFIG_KEY_IGNORE_COLLISION:
			if typeof(value) != TYPE_BOOL: return
			_check_collisions.button_pressed = value
		CONFIG_KEY_IGNORE_TRANSITIONS:
			if typeof(value) != TYPE_BOOL: return
			_check_transitions.button_pressed = value

func _on_save_settings_pressed() -> void:
	CrawlGlobals.Save_Config()

func _on_done_pressed() -> void:
	visible = false

func _on_check_collisions_toggled(button_pressed : bool) -> void:
	CrawlGlobals.Set_Config_Value(CONFIG_SECTION, CONFIG_KEY_IGNORE_COLLISION, button_pressed)

func _on_check_transitions_toggled(button_pressed : bool) -> void:
	CrawlGlobals.Set_Config_Value(CONFIG_SECTION, CONFIG_KEY_IGNORE_TRANSITIONS, button_pressed)
