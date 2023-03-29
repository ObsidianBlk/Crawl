extends CrawlTriggerNode3D

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CElL_SIZE : float = 5.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _transitioning : bool = false
var _state_open : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _body : Node3D = %Body
@onready var _anim : AnimationPlayer = %Anim

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	initialize_trigger()
	_anim.animation_finished.connect(_on_animation_finished)
	use_entity_direct_update(true)
	entity_changing.connect(_on_door_entity_changing)
	entity_changed.connect(_on_door_entity_changed)
	_on_door_entity_changed()

# ------------------------------------------------------------------------------
# Private Methodsinitialize_trigger
# ------------------------------------------------------------------------------
func _UpdateViz() -> void:
	if entity == null: return
	if _body != null:
		_body.position.z = CELL_SIZE * 0.5

func _UpdateIdleState() -> void:
	if _anim == null or entity == null: return
	var open : bool = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)
	if open:
		_state_open = true
		_anim.play("idle_open")
	else:
		_state_open = false
		_anim.play("idle_closed")

func _ChangeBlocking() -> void:
	# NOTE: Primarily called from the AnimationPlayer :)
	if entity == null: return
	var active = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, false)
	entity.set_block_all(false)
	if not active:
		entity.set_blocking(entity.facing, true)

func _CheckAnimationToActiveState() -> void:
	if _transitioning: return # Don't do anything is already transitioning between states
	if entity == null: return
	if entity.has_meta_key(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY) == false : return
	var active : bool = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY)
	if active:
		if not _state_open:
			_transitioning = true
			_state_open = true
			_anim.play(&"opening")
		elif _anim.current_animation != &"idle_open":
			_anim.play(&"idle_open")
	else:
		if _state_open:
			_transitioning = true
			_state_open = false
			_anim.play(&"closing")
		elif _anim.current_animation != &"idle_closed":
			_anim.play(&"idle_closed")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_animation_finished(anim_name : StringName) -> void:
	match anim_name:
		&"opening", &"closing":
			_transitioning = false
			_CheckAnimationToActiveState()

func _on_door_meta_value_changed(key : String) -> void:
	if key != CrawlTriggerRelay.TRIGGER_ACTIVE_KEY: return
	_CheckAnimationToActiveState()

func _on_door_interaction(interacting_entity : CrawlEntity) -> void:
	var active : bool = entity.get_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY)
	entity.set_meta_value(CrawlTriggerRelay.TRIGGER_ACTIVE_KEY, not active)

func _on_door_entity_changing() -> void:
	if entity.interaction.is_connected(_on_door_interaction):
		entity.interaction.disconnect(_on_door_interaction)
	if entity.meta_value_changed.is_connected(_on_door_meta_value_changed):
		entity.meta_value_changed.disconnect(_on_door_meta_value_changed)

func _on_door_entity_changed() -> void:
	if entity == null: return
	entity.set_meta_value("visible_in_play", true)
	if not entity.interaction.is_connected(_on_door_interaction):
		entity.interaction.connect(_on_door_interaction)
	if not entity.meta_value_changed.is_connected(_on_door_meta_value_changed):
		entity.meta_value_changed.connect(_on_door_meta_value_changed)
	_UpdateViz()
	_ChangeBlocking()
	_UpdateIdleState()
