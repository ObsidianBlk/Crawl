extends CrawlTriggerNode3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const META_KEY_CONNECTIONS : String = "connections"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _cstates : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	initialize_trigger()
	entity_changing.connect(_on_gate_entity_changing)
	entity_changed.connect(_on_gate_entity_changed)
	CrawlTriggerRelay.trigger_state_changed.connect(_on_trigger_state_changed)
	if entity != null:
		_on_gate_entity_changed()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateActiveState() -> void:
	if entity == null: return
	var init_state = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY)
	var new_state : bool = false
	for uuid in _cstates:
		if _cstates[uuid] == false:
			new_state = true
	if init_state != new_state:
		entity.set_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, new_state)

func _UpdateConnections() -> void:
	if entity == null: return
	var changed : bool = false
	
	var connections : Array = entity.get_meta_value(META_KEY_CONNECTIONS, [])
	for uuid in _cstates:
		if connections.find(uuid) >= 0: continue
		_cstates.erase(uuid)
		changed = true
	
	for uuid in connections:
		if uuid in _cstates: continue
		_cstates[uuid] = CrawlTriggerRelay.is_trigger_active(uuid)
		changed = true
	
	if changed:
		_UpdateActiveState()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func is_active() -> bool:
	if entity == null: return false
	return entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_trigger_state_changed(uuid : StringName, active : bool) -> void:
	if uuid in _cstates:
		_cstates[uuid] = active
		_UpdateActiveState()

func _on_gate_entity_meta_value_changed(key : String) -> void:
	if key == META_KEY_CONNECTIONS:
		_UpdateConnections()

func _on_gate_entity_changing() -> void:
	if entity == null: return
	if entity.meta_value_changed.is_connected(_on_gate_entity_meta_value_changed):
		entity.meta_value_changed.disconnect(_on_gate_entity_meta_value_changed)

func _on_gate_entity_changed() -> void:
	if entity == null: return
	entity.set_block_all(false)
	if not entity.has_meta_key(META_KEY_CONNECTIONS):
		entity.set_meta_value(META_KEY_CONNECTIONS, [])
	if not entity.meta_value_changed.is_connected(_on_gate_entity_meta_value_changed):
		entity.meta_value_changed.connect(_on_gate_entity_meta_value_changed)
	_UpdateConnections()


