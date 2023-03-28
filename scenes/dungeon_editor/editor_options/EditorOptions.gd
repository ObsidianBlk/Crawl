extends MenuButton


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CONFIG_SECTION : String = "Dungeon_Editor"


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	CrawlGlobals.crawl_config_loaded.connect(_on_config_changed)
	CrawlGlobals.crawl_config_reset.connect(_on_config_changed)
	CrawlGlobals.crawl_config_loaded.connect(_on_config_changed)
	CrawlGlobals.crawl_config_value_changed.connect(_on_config_value_changed)
	_ResetPopupMenu()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ResetPopupMenu() -> void:
	if not CrawlGlobals.Has_Config_Section(CONFIG_SECTION): return
	
	var pop : PopupMenu = get_popup()
	pop.clear()
	
	var keys : PackedStringArray = CrawlGlobals.Get_Config_Section_Keys(CONFIG_SECTION)
	for key in keys:
		var idx : int = pop.item_count
		pop.add_check_item(key)
		pop.set_item_metadata(idx, {"key":key})
		pop.set_item_checked(idx, CrawlGlobals.Get_Config_Value(CONFIG_SECTION, key))

	if not pop.index_pressed.is_connected(_on_popup_index_pressed):
		pop.index_pressed.connect(_on_popup_index_pressed)

# ------------------------------------------------------------------------------
# Handler methods
# ------------------------------------------------------------------------------
func _on_popup_index_pressed(idx : int) -> void:
	pass

func _on_config_changed(_section : String = "") -> void:
	_ResetPopupMenu()

func _on_config_value_changed(section : String, key : String, value : Variant) -> void:
	pass
