extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CELL_SIZE : float = 3.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map_position : Vector3i = Vector3i.ZERO


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("move_foreward"):
		pass
	if event.is_action_pressed("move_backward"):
		pass
	if event.is_action_pressed("move_left"):
		pass
	if event.is_action_pressed("move_right"):
		pass
	if event.is_action_pressed("turn_left"):
		pass
	if event.is_action_pressed("turn_right"):
		pass

