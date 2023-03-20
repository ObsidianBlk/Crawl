extends Node3D



# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal fill_mode_enabled(enable)
signal dig(from_position, surface)
signal fill(from_position, surface)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEG90 : float = 1.570796
const CLOCKWISE : float = -1.0
const COUNTERCLOCKWISE : float = 1.0

const CELL_SIZE : float = 5.0

#const MAX_MOVE_QUEUE_SIZE : int = 4

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null:					set = set_entity
@export var ignore_map : bool = false:						set = set_ignore_map
@export_range(0.0, 180.0) var max_yaw : float = 60.0
@export_range(0.0, 180.0) var rest_yaw : float = 30.0
@export_range(0.0, 180.0) var max_pitch : float = 30.0
@export_range(0.0, 180.0) var rest_pitch : float = 15.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
#var _map_position : Vector3i = Vector3i.ZERO

var _freelook_enabled : bool = false

var _fill_enabled : bool = false

var _move_queue : Array = []
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Override Variables
# ------------------------------------------------------------------------------
@onready var _facing_node : Node3D = $Facing
@onready var _gimble_yaw_node : Node3D = $Facing/Gimble_Yaw
@onready var _gimble_pitch_node : Node3D = $Facing/Gimble_Yaw/Gimble_Pitch


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_entity(ent : CrawlEntity) -> void:
	if ent != entity:
		entity = ent
		if entity != null:
			position = Vector3(entity.position) * CELL_SIZE

func set_ignore_map(i : bool) -> void:
	# NOTE: This method is more for passing signals to.
	ignore_map = i

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	var ref : MeshInstance3D = get_node_or_null("Reference")
	if ref != null:
		ref.queue_free() # This only exists to be able to see the player in the editor.

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
			_Move(&"foreward")
		if event.is_action_pressed("move_backward"):
			_Move(&"backward")
		if event.is_action_pressed("move_left"):
			_Move(&"left")
		if event.is_action_pressed("move_right"):
			_Move(&"right")
		if event.is_action_pressed("climb_up"):
			_Move(&"up")
		if event.is_action_pressed("climb_down"):
			_Move(&"down")
		if event.is_action_pressed("turn_left"):
			_Turn(COUNTERCLOCKWISE)
		if event.is_action_pressed("turn_right"):
			_Turn(CLOCKWISE)
		
		if event.is_action_pressed("fill_mode"):
			_fill_enabled = not _fill_enabled
			fill_mode_enabled.emit(_fill_enabled)
		if event.is_action_pressed("dig"):
			_Dig()
		if event.is_action_pressed("dig_up"):
			_Dig(true, CrawlGlobals.SURFACE.Ceiling)
		if event.is_action_pressed("dig_down"):
			_Dig(true, CrawlGlobals.SURFACE.Ground)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _LerpLookAngle(deg : float, rest_deg : float, _delta : float) -> float:
	var target : float = rest_deg if _freelook_enabled else 0.0
	if abs(deg) > target:
		var sn : float = sign(deg)
		deg = lerp(deg, sn * target, 0.25)
		if abs(deg) <= target + 0.01:
			return sn * target
	return deg

func _SettleLookAngle(delta : float) -> void:
	_gimble_yaw_node.rotation_degrees.y = _LerpLookAngle(
		_gimble_yaw_node.rotation_degrees.y, rest_yaw, delta
	)
	_gimble_pitch_node.rotation_degrees.x = _LerpLookAngle(
		_gimble_pitch_node.rotation_degrees.x, rest_pitch, delta
	)

func _Move(dir : StringName) -> void:
	if not ignore_map and not entity.can_move(dir): return
	entity.move(dir, ignore_map)
	position = Vector3(entity.position) * CELL_SIZE

func _Dig(use_z : bool = false, z_surface : CrawlGlobals.SURFACE = CrawlGlobals.SURFACE.Ceiling) -> void:
	if entity == null: return
	var map : CrawlMap = entity.get_map()
	var facing : CrawlGlobals.SURFACE = entity.facing if not use_z else z_surface
	if _fill_enabled:
		fill.emit(entity.position, entity.facing)
	else:
		dig.emit(entity.position, entity.facing)

func _Turn(dir : float) -> void:
	match dir:
		COUNTERCLOCKWISE:
			entity.turn_left()
		CLOCKWISE:
			entity.turn_right()
	
	_facing_node.rotation.y += (DEG90 * dir)
	if _facing_node.rotation.y >= 2*PI:
		_facing_node.rotation.y -= 2*PI
	if _facing_node.rotation.y < 0.0:
		_facing_node.rotation.y += 2*PI


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

