extends CrawlTriggerNode3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const META_KEY_CONNECTIONS : String = "connections"
const META_KEY_INTERVAL : String = "timer_interval"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _connection_uuid : StringName = &""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _timer : Timer = $Timer

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_timer.timeout.connect(_on_timer_timeout)
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
	if CrawlGlobals.In_Editor_Mode(): return
	
	var activate_timer : bool = true
	
	if _connection_uuid != &"":
		activate_timer = not CrawlTriggerRelay.is_trigger_active(_connection_uuid)
	
	if activate_timer:
		var interval : float = entity.get_meta_value(META_KEY_INTERVAL)
		_timer.paused = false
		if _timer.wait_time != interval:
			_timer.wait_time = interval
		if _timer.is_stopped():
			_timer.start(interval)
	else:
		_timer.paused = true


func _UpdateConnections() -> void:
	if entity == null: return
	
	var connections : Array = entity.get_meta_value(META_KEY_CONNECTIONS, [])
	if connections.size() <= 0:
		_connection_uuid = &""
	else:
		_connection_uuid = connections[0]
	
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
	if uuid == _connection_uuid:
		_UpdateActiveState()

func _on_gate_entity_meta_value_changed(key : String) -> void:
	if key == META_KEY_CONNECTIONS:
		_UpdateConnections()

func _on_gate_entity_changing() -> void:
	if entity == null: return
	if entity.meta_value_changed.is_connected(_on_gate_entity_meta_value_changed):
		entity.meta_value_changed.disconnect(_on_gate_entity_meta_value_changed)
	if _timer != null:
		_timer.stop()

func _on_gate_entity_changed() -> void:
	if entity == null: return
	entity.set_block_all(false)
	if not entity.has_meta_key(META_KEY_CONNECTIONS):
		entity.set_meta_value(META_KEY_CONNECTIONS, [])
	if not entity.has_meta_key(META_KEY_INTERVAL):
		entity.set_meta_value(META_KEY_INTERVAL, 1.0)
	if not entity.meta_value_changed.is_connected(_on_gate_entity_meta_value_changed):
		entity.meta_value_changed.connect(_on_gate_entity_meta_value_changed)
	_UpdateConnections()

func _on_timer_timeout() -> void:
	if entity == null: return
	var active : bool = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY)
	_timer.start()
	entity.set_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, not active)
