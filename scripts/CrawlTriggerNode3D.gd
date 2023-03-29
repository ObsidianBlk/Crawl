extends CrawlEntityNode3D
class_name CrawlTriggerNode3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TRIGGER_GROUP : StringName = &"Trigger"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _trigger_ready : bool = false

var _connected_nodes : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	initialize_trigger()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func initialize_trigger() -> void:
	if _trigger_ready: return
	_trigger_ready = true
	editor_mode_changed.connect(_on_editor_mode_changed)
	entity_changing.connect(_on_entity_changing)
	entity_changed.connect(_on_entity_changed)
	if entity != null:
		_on_entity_changed()
	_on_editor_mode_changed(_editor_mode)


func is_active() -> bool:
	if entity == null: return false
	return entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_editor_mode_changed(enabled : bool) -> void:
	if not _editor_mode and entity != null:
		enabled = entity.get_meta_value("visible_in_play", false)
	visible = enabled

func _on_entity_changing() -> void:
	if entity != null:
		remove_from_group(entity.uuid)
		remove_from_group(TRIGGER_GROUP)

func _on_entity_changed() -> void:
	if entity != null:
		add_to_group(entity.uuid)
		add_to_group(TRIGGER_GROUP)
		if not entity.has_meta_key(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY):
			entity.set_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)
		CrawlTriggerRelay.register_trigger_entity(entity)
