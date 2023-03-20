extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal pressed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CELL_SIZE : float = 5.0
const ARC_ANGLE : float = deg_to_rad(20.0)
const ARC_TIME : float = 2.0


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var focus_color : Color = Color.WHEAT:		set = set_focus_color

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _section : StringName = &""
var _resource_name : StringName = &""
var _resource_node : Node3D = null

var _unfocus_color : Color = Color(Color.WHEAT, 0.0)
var _mouse_entered : bool = false

var _call_when_ready : Callable = func():pass

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _subview : SubViewport = $Main/SubViewContainer/SubViewport
@onready var _gimble : Node3D = $Main/SubViewContainer/SubViewport/Gimble
@onready var _camera_wall : Camera3D = $Main/SubViewContainer/SubViewport/Gimble/Camera_Wall
@onready var _camera_ground : Camera3D = $Main/SubViewContainer/SubViewport/Gimble/Camera_Ground
@onready var _camera_ceiling : Camera3D = $Main/SubViewContainer/SubViewport/Gimble/Camera_Ceiling
@onready var _crect : ColorRect = $ColorRect

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_focus_color(c : Color) -> void:
	focus_color = c
	_unfocus_color = Color(c, 0.0)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_unfocus_color = Color(focus_color, 0.0)
	_crect.color = _unfocus_color
	
	_call_when_ready.call()
	_on_tween_complete()

func _gui_input(event : InputEvent) -> void:
	if not _mouse_entered: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_mouse_entered = true
			_crect.color = focus_color
		NOTIFICATION_MOUSE_EXIT:
			_mouse_entered = false
			_crect.color = _unfocus_color
		NOTIFICATION_FOCUS_ENTER:
			pass
		NOTIFICATION_FOCUS_EXIT:
			pass
		NOTIFICATION_THEME_CHANGED:
			pass
		NOTIFICATION_VISIBILITY_CHANGED:
			pass
		NOTIFICATION_RESIZED:
			pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UnsetAllCameras() -> void:
	_camera_wall.current = false
	_camera_ground.current = false
	_camera_ceiling.current = false


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	if _resource_node != null:
		_subview.remove_child(_resource_node)
		_resource_node.queue_free()
		_resource_node = null
		_section = &""
		_resource_name = &""

func is_resource(section : StringName, resource_name : StringName) -> bool:
	return _section == section and _resource_name == resource_name

func set_resource(section : StringName, resource_name : StringName) -> void:
	if _gimble == null: # We're not ready...
		_call_when_ready = set_resource.bind(section, resource_name)
		return
	
	if section == &"" or resource_name == &"":
		clear()
		return
	if _resource_node != null and section == _section and resource_name == _resource_name: return
	
	var node : Node3D = RLT.instantiate_resource(section, resource_name)
	if node == null: return
	
	clear()
	_subview.add_child(node)
	_resource_node = node
	
	_section = section
	_resource_name = resource_name

	_UnsetAllCameras()
	match _section:
		&"ground":
			_camera_ground.current = true
		&"ceiling":
			node.position = Vector3(0, CELL_SIZE, 0)
			_camera_ceiling.current = true
		_: # For now, this will be for "everything else", including walls
			_camera_wall.current = true


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_tween_complete() -> void:
	var target : float = ARC_ANGLE
	var duration : float = ARC_TIME
	if abs(_gimble.rotation.y) > 0.01:
		target *= -sign(_gimble.rotation.y)
		duration *= 2
	
	var tween : Tween = create_tween()
	tween.tween_property(_gimble, "rotation:y", target, duration)
	tween.finished.connect(_on_tween_complete)
