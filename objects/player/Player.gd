extends Node3D



# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal map_position_changed(map_position)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEG90 : float = 1.570796
const CLOCKWISE : float = -1.0
const COUNTERCLOCKWISE : float = 1.0

const CELL_SIZE : float = 5.0

const MAX_MOVE_QUEUE_SIZE : int = 4

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null
@export var digging_enabled : bool = false
@export_range(0.0, 180.0) var max_yaw : float = 60.0
@export_range(0.0, 180.0) var rest_yaw : float = 30.0
@export_range(0.0, 180.0) var max_pitch : float = 30.0
@export_range(0.0, 180.0) var rest_pitch : float = 15.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map_position : Vector3i = Vector3i.ZERO

var _freelook_enabled : bool = false

var _move_queue : Array = []
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Override Variables
# ------------------------------------------------------------------------------
@onready var _facing_node : Node3D = $Facing
@onready var _gimble_yaw_node : Node3D = $Facing/Gimble_Yaw
@onready var _gimble_pitch_node : Node3D = $Facing/Gimble_Yaw/Gimble_Pitch

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
#				_gimble_pitch_node.rotation_degrees.x = clamp(
#					_gimble_pitch_node.rotation_degrees.x + (strength * 10.0),
#					-max_pitch, max_pitch
#				)
			elif event.is_action("freelook_left") or event.is_action("freelook_right"):
				var strength : float = event.get_action_strength("freelook_left") - event.get_action_strength("freelook_right")
				_gimble_yaw_node.rotation_degrees.y = strength * rest_yaw
#				_gimble_yaw_node.rotation_degrees.y = clamp(
#					_gimble_yaw_node.rotation_degrees.y + (strength * 10.0),
#					-max_yaw, max_yaw
#				)
	
	if event.is_action("free_look"):
		_freelook_enabled = event.is_pressed()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _freelook_enabled else Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("move_foreward"):
		_MoveHorz(Vector3(0,0,1))
	if event.is_action_pressed("move_backward"):
		_MoveHorz(Vector3(0,0,-1))
	if event.is_action_pressed("move_left"):
		_MoveHorz(Vector3(1,0,0))
	if event.is_action_pressed("move_right"):
		_MoveHorz(Vector3(-1,0,0))
	if event.is_action_pressed("turn_left"):
		_Turn(COUNTERCLOCKWISE)
	if event.is_action_pressed("turn_right"):
		_Turn(CLOCKWISE)
	if event.is_action_pressed("dig") and digging_enabled:
		_Dig(Vector3(0,0,1))


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

func _AddToMoveQueue(callback : Callable) -> void:
	if _move_queue.size() < MAX_MOVE_QUEUE_SIZE:
		_move_queue.append(callback)

func _MoveHorz(dir : Vector3) -> void:
	if _tween != null:
		_AddToMoveQueue(_MoveHorz.bind(dir))
		return
	
	dir = dir.rotated(Vector3.UP, _facing_node.rotation.y)
	
	var can_move : bool = false
	var surf : CrawlMap.SURFACE = map.get_surface_from_direction(dir)
	if surf != CrawlMap.SURFACE.Ground and surf != CrawlMap.SURFACE.Ceiling:
		can_move = not map.is_cell_surface_blocking(Vector3i(position / CELL_SIZE), surf)
	#print("Facing:")
	if not can_move: return
	
	var target : Vector3 = dir * CELL_SIZE

	_tween = create_tween()
	_tween.tween_property(self, "position", position + target, 0.4)
	_tween.finished.connect(_on_movement_tween_finished)

func _Dig(dir : Vector3) -> void:
	dir = dir.rotated(Vector3.UP, _facing_node.rotation.y)
	var surf : CrawlMap.SURFACE = map.get_surface_from_direction(dir)
	map.dig(Vector3i(position / CELL_SIZE), surf)

func _Turn(dir : float) -> void:
	if _tween != null:
		_AddToMoveQueue(_Turn.bind(dir))
		return
	
	if dir == CLOCKWISE or dir == COUNTERCLOCKWISE:
		var target : float = _facing_node.rotation.y + (DEG90 * dir)
		_tween = create_tween()
		_tween.tween_property(_facing_node, "rotation:y", target, 0.2)
		_tween.finished.connect(_on_movement_tween_finished)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_movement_tween_finished() -> void:
	_tween = null
	if _facing_node.rotation.y >= 2*PI:
		_facing_node.rotation.y -= 2*PI
	if _facing_node.rotation.y < 0.0:
		_facing_node.rotation.y += 2*PI
	
	# This is to fix a rounding error... Not sure if the error is in the
	# rotation of the direction in the _MoveHorz() method or if it
	# occures during the tween of the _facing_node.rotation.y value.
	position = floor(position + Vector3(0.5, 0.5, 0.5))
	map_position_changed.emit(Vector3i(position / CELL_SIZE))
	if map != null:
		map.set_focus_cell(Vector3i(position / CELL_SIZE))
	#print(position / CELL_SIZE)
	
	if _move_queue.size() > 0:
		var move : Callable = _move_queue.pop_front()
		move.call()

