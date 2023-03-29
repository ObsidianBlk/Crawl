extends CrawlEntityNode3D
class_name CrawlTriggerNode3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal trigger_state_changed(active)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TRIGGER_GROUP : StringName = &"Trigger"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _trigger_ready : bool = false
var _calculated_this_cycle : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	initialize_trigger()

func _physics_process(_delta : float) -> void:
	_calculated_this_cycle = false

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetIncomingSignals() -> Array:
	if entity == null: return []
	var connections : Array = entity.get_meta_value("connections", [])
	var results : Array = []
	for uuid in connections:
		var nlist = get_tree().get_nodes_in_group(uuid)
		if nlist.size() > 0:
			if is_instance_of(nlist[0], CrawlTriggerNode3D):
				results.append(nlist[0].is_active())
				continue
		results.append(false) # The trigger node couldn't be found or recieved a non-trigger node.
	return results

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
	_calculated_this_cycle = true
	if entity == null: return false
	return entity.get_meta_value("active", false)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_editor_mode_changed(enabled : bool) -> void:
	if entity != null:
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
		entity.set_meta_value("active", false)
