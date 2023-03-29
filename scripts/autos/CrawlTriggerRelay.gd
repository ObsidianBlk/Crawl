extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal trigger_state_changed(uuid, active)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TRIGGER_ACTIVE_KEY : String = "trigger_active"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _trigger_entities : Dictionary = {}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func register_trigger_entity(entity : CrawlEntity) -> void:
	if entity == null: return
	if not entity.has_meta_key(TRIGGER_ACTIVE_KEY): return
	if entity.uuid in _trigger_entities: return
	_trigger_entities[entity.uuid] = weakref(entity)
	
	if not entity.meta_value_changed.is_connected(_on_entity_meta_value_changed.bind(entity)):
		entity.meta_value_changed.connect(_on_entity_meta_value_changed.bind(entity))
	if not entity.meta_value_removed.is_connected(_on_entity_meta_value_removed.bind(entity)):
		entity.meta_value_removed.connect(_on_entity_meta_value_removed.bind(entity))
	
	var active = entity.get_meta_value(TRIGGER_ACTIVE_KEY)
	if typeof(active) == TYPE_BOOL:
		trigger_state_changed.emit(entity.uuid, active)

func unregister_trigger_entity(entity : CrawlEntity) -> void:
	if entity == null: return
	if not entity.uuid in _trigger_entities: return
	
	_trigger_entities.erase(entity.uuid)
	if entity.meta_value_changed.is_connected(_on_entity_meta_value_changed.bind(entity)):
		entity.meta_value_changed.disconnect(_on_entity_meta_value_changed.bind(entity))
	if entity.meta_value_removed.is_connected(_on_entity_meta_value_removed.bind(entity)):
		entity.meta_value_removed.disconnect(_on_entity_meta_value_removed.bind(entity))
	
	trigger_state_changed.emit(entity.uuid, false)


func is_trigger_active(uuid : StringName) -> bool:
	if not uuid in _trigger_entities: return false
	if _trigger_entities[uuid].get_ref() == null: return false
	return _trigger_entities[uuid].get_ref().get_meta_value(TRIGGER_ACTIVE_KEY)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_entity_meta_value_changed(key : String, entity : CrawlEntity) -> void:
	if key != TRIGGER_ACTIVE_KEY: return
	var active = entity.get_meta_value(TRIGGER_ACTIVE_KEY)
	if typeof(active) == TYPE_BOOL:
		trigger_state_changed.emit(entity.uuid, active)

func _on_entity_meta_value_removed(key : String, entity : CrawlEntity) -> void:
	if key != TRIGGER_ACTIVE_KEY: return
	unregister_trigger_entity.call_deferred(entity)
