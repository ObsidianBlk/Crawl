extends Node3D
class_name CrawlCell


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var _map : CrawlMap = null :					set = set_map
@export var _map_position : Vector3i = Vector3i.ZERO:	set = set_map_position
@export var _update_build : bool = false:				set = set_update_build


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _body_nodes : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(map : CrawlMap) -> void:
	if map != _map:
		_map = map
		if _update_build:
			_BuildCell()

func set_map_position(map_pos : Vector3i) -> void:
	if map_pos != _map_position:
		_map_position = map_pos
		if _update_build:
			_BuildCell()

func set_update_build(update : bool) -> void:
	if update != _update_build:
		_update_build = update
		if _update_build:
			_BuildCell()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateMeshFromResourceID() -> void:
	pass

func _ClearCell() -> void:
	for child in get_children():
		child.queue_free()

func _BuildCell() -> void:
	if _map == null:
		_ClearCell()
	if not _map.has_cell(_map_position):
		_ClearCell()

