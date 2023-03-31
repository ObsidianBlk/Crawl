extends CrawlTriggerNode3D

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const META_KEY_CONNECTIONS : String = "connections"
const META_KEY_VIZ_IN_PLAY : String = "visible_in_play"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _connection_uuid : StringName = &""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var omni_light_3d : OmniLight3D = $OmniLight3D

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	initialize_trigger()
	use_entity_direct_update(true)
	entity_changing.connect(_on_light_entity_changing)
	entity_changed.connect(_on_light_entity_changed)
	CrawlTriggerRelay.trigger_state_changed.connect(_on_trigger_state_changed)
	if entity != null:
		_on_light_entity_changed()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateConnection() -> void:
	var clist : Array = entity.get_meta_value(META_KEY_CONNECTIONS, [])
	if clist.size() > 0:
		_connection_uuid = clist[0]
		var active : bool = CrawlTriggerRelay.is_trigger_active(_connection_uuid)
		_on_trigger_state_changed(_connection_uuid, active)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func is_active() -> bool:
	if entity == null: return false
	return entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_trigger_state_changed(uuid : StringName, connection_state : bool) -> void:
	if entity == null: return
	if uuid == _connection_uuid:
		var old_state : bool = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)
		if old_state != connection_state:
			omni_light_3d.visible = connection_state
			entity.set_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, connection_state)

func _on_light_entity_meta_value_changed(key : String) -> void:
	if entity == null: return
	match key:
		META_KEY_CONNECTIONS:
			_UpdateConnection()
		META_KEY_VIZ_IN_PLAY:
			if not _editor_mode:
				visible = entity.get_meta_value(key)

func _on_light_entity_changing() -> void:
	if entity == null: return
	if entity.meta_value_changed.is_connected(_on_light_entity_meta_value_changed):
		entity.meta_value_changed.disconnect(_on_light_entity_meta_value_changed)

func _on_light_entity_changed() -> void:
	if entity == null: return
	entity.set_block_all(false)
	if not entity.has_meta_key(META_KEY_CONNECTIONS):
		entity.set_meta_value(META_KEY_CONNECTIONS, [])
	if not entity.meta_value_changed.is_connected(_on_light_entity_meta_value_changed):
		entity.meta_value_changed.connect(_on_light_entity_meta_value_changed)
	if not entity.has_meta_key(META_KEY_VIZ_IN_PLAY):
		entity.set_meta_value.call_deferred(META_KEY_VIZ_IN_PLAY, true)
	_UpdateConnection()
