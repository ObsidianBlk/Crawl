extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEG90 : float = 1.570796
const CLOCKWISE : float = -1.0
const COUNTERCLOCKWISE : float = 1.0

const CELL_SIZE : float = 3.0

const MAX_MOVE_QUEUE_SIZE : int = 4

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map_position : Vector3i = Vector3i.ZERO

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

func _unhandled_input(event : InputEvent) -> void:
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


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
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
	print("Position: ", position / CELL_SIZE)
	
	if _move_queue.size() > 0:
		var move : Callable = _move_queue.pop_front()
		move.call()

