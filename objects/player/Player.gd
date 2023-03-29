extends CrawlEntityNode3D



# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const VIEW_LERP_RATE_DEFAULT : float = 0.25
const VIEW_LERP_RATE_STAIRS : float = 0.75

const CONFIG_SECTION_GAMEPLAY : String = "Gameplay"
const CONFIG_KEY_LOOK_TOWARDS_STAIRS : String = "look_toward_stairs"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_range(0.0, 180.0) var max_yaw : float = 60.0
@export_range(0.0, 180.0) var rest_yaw : float = 30.0
@export_range(0.0, 180.0) var max_pitch : float = 30.0
@export_range(0.0, 180.0) var rest_pitch : float = 15.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map_position : Vector3i = Vector3i.ZERO
var _freelook_enabled : bool = false

var _force_pitch : bool = false
var _forced_pitch_angle : float = 0.0
var _view_lerp_rate : float = VIEW_LERP_RATE_DEFAULT

# ------------------------------------------------------------------------------
# Override Variables
# ------------------------------------------------------------------------------
@onready var _gimble_yaw_node : Node3D = $Facing/Gimble_Yaw
@onready var _gimble_pitch_node : Node3D = $Facing/Gimble_Yaw/Gimble_Pitch
@onready var _camera : Camera3D = $Facing/Gimble_Yaw/Gimble_Pitch/Camera3D

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	editor_mode_changed.connect(_on_editor_mode_changed)
	_on_editor_mode_changed(_editor_mode)

func _process(delta : float) -> void:
	_SettleLookAngle(delta)

func _unhandled_input(event : InputEvent) -> void:
	if _freelook_enabled:
		if is_instance_of(event, InputEventMouseMotion):
			var ppd : float = 400.0 # TODO: Make this a const or an export.
			_gimble_yaw_node.rotation_degrees.y = clamp(
				_gimble_yaw_node.rotation_degrees.y + (-event.velocity.x / ppd),
				-max_yaw, max_yaw
			)
			_gimble_pitch_node.rotation_degrees.x = clamp(
				_gimble_pitch_node.rotation_degrees.x + (event.velocity.y / ppd),
				-max_pitch, max_pitch
			)
		else:
			if event.is_action("freelook_up") or event.is_action("freelook_down"):
				var strength : float = event.get_action_strength("freelook_up") - event.get_action_strength("freelook_down")
				_gimble_pitch_node.rotation_degrees.x = strength * rest_pitch
			elif event.is_action("freelook_left") or event.is_action("freelook_right"):
				var strength : float = event.get_action_strength("freelook_left") - event.get_action_strength("freelook_right")
				_gimble_yaw_node.rotation_degrees.y = strength * rest_yaw
	
	if event.is_action("free_look"):
		_freelook_enabled = event.is_pressed()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _freelook_enabled else Input.MOUSE_MODE_VISIBLE
	if entity != null:
		if event.is_action_pressed("move_foreward"):
			move(&"foreward")
		if event.is_action_pressed("move_backward"):
			move(&"backward")
		if event.is_action_pressed("move_left"):
			move(&"left")
		if event.is_action_pressed("move_right"):
			move(&"right")
		if event.is_action_pressed("climb_up"):
			move(&"up")
		if event.is_action_pressed("climb_down"):
			move(&"down")
		if event.is_action_pressed("turn_left"):
			turn(COUNTERCLOCKWISE)
		if event.is_action_pressed("turn_right"):
			turn(CLOCKWISE)
		if event.is_action_pressed("interact"):
			_Interact()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _LerpLookAngle(deg : float, rest_deg : float) -> float:
	var target : float = rest_deg if _freelook_enabled else 0.0
	if abs(deg) > target:
		var sn : float = sign(deg)
		deg = lerp(deg, sn * target, VIEW_LERP_RATE_DEFAULT)
		if abs(deg) <= target + 0.01:
			return sn * target
	return deg

func _LerpLookAtAngle(deg : float, target : float) -> float:
	if abs(target - deg) <= 0.01: return deg
	return lerp(deg, target, VIEW_LERP_RATE_STAIRS)

func _SettleLookAngle(delta : float) -> void:
	_gimble_yaw_node.rotation_degrees.y = _LerpLookAngle(
		_gimble_yaw_node.rotation_degrees.y, rest_yaw
	)
	if _force_pitch:
		_gimble_pitch_node.rotation_degrees.x = _LerpLookAtAngle(
			_gimble_pitch_node.rotation_degrees.x, _forced_pitch_angle
		)
	_gimble_pitch_node.rotation_degrees.x = _LerpLookAngle(
		_gimble_pitch_node.rotation_degrees.x, rest_pitch
	)

func _Interact() -> void:
	if entity == null: return
	var options : Dictionary = {&"primary_type":&"Door"}
	var doors : Array = entity.get_local_entities(options)
	doors.append_array(entity.get_adjacent_entities(options))
	var adj_facing : CrawlGlobals.SURFACE = CrawlGlobals.Get_Adjacent_Surface(entity.facing)
	for door in doors:
		if door.position == entity.position and door.facing == entity.facing:
			door.interact(entity)
			return
		if door.position != entity.position and door.facing == adj_facing:
			door.interact(entity)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_editor_mode_changed(enabled : bool) -> void:
	var ref : MeshInstance3D = get_node_or_null("Reference")
	if ref != null:
		ref.visible = enabled
	if _camera != null:
		_camera.current = not enabled
	use_entity_direct_update(enabled)
	set_process_unhandled_input(not enabled)
	set_process(not enabled)
	if enabled:
		if transition_started.is_connected(_on_transition_started):
			transition_started.disconnect(_on_transition_started)
		if transition_complete.is_connected(_on_transition_completed):
			transition_complete.disconnect(_on_transition_completed)
	else:
		if not transition_started.is_connected(_on_transition_started):
			transition_started.connect(_on_transition_started)
		if not transition_complete.is_connected(_on_transition_completed):
			transition_complete.connect(_on_transition_completed)

func _on_transition_started(direction : StringName) -> void:
	match direction:
		&"up":
			_force_pitch = CrawlGlobals.Get_Config_Value(CONFIG_SECTION_GAMEPLAY, CONFIG_KEY_LOOK_TOWARDS_STAIRS)
			_view_lerp_rate = VIEW_LERP_RATE_STAIRS
			_forced_pitch_angle = -max_pitch
		&"down":
			_force_pitch = CrawlGlobals.Get_Config_Value(CONFIG_SECTION_GAMEPLAY, CONFIG_KEY_LOOK_TOWARDS_STAIRS)
			_view_lerp_rate = VIEW_LERP_RATE_STAIRS
			_forced_pitch_angle = max_pitch

func _on_transition_completed() -> void:
	_force_pitch = false
	if entity == null: return
	if _entity_direct_update: return
	if entity.can_move(&"down"):
		# TODO: Technically I should check for a ladder, but not ready for that yet!
		#   So we'll just fall!
		clear_movement_queue()
		move(&"down")
