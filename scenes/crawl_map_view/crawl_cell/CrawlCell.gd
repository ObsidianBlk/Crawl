extends Node3D
class_name CrawlCell


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null :					set = set_map
@export var map_offset : Vector3i = Vector3i.ZERO:		set = set_map_offset


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map_position : Vector3i
var _request_cell_update : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var mesh_ground : MeshInstance3D = $Ground
@onready var mesh_ceiling : MeshInstance3D = $Ceiling
@onready var mesh_wall_north : MeshInstance3D = $Wall_North
@onready var mesh_wall_south : MeshInstance3D = $Wall_South
@onready var mesh_wall_east : MeshInstance3D = $Wall_East
@onready var mesh_wall_west : MeshInstance3D = $Wall_West

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(nmap : CrawlMap) -> void:
	if nmap != map:
		map = nmap

func set_map_offset(offset : Vector3i) -> void:
	if offset != map_offset:
		map_offset = offset

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

func _process(_delta : float) -> void:
	if _request_cell_update:
		_request_cell_update = false
		_BuildCell()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearCell() -> void:
	mesh_ground.visible = false
	mesh_ceiling.visible = false
	mesh_wall_north.visible = false
	mesh_wall_south.visible = false
	mesh_wall_east.visible = false
	mesh_wall_west.visible = false

func _BuildCell() -> void:
	if map == null or not map.has_cell(_map_position):
		_ClearCell()
		return
	
	var rids : Array = map.get_cell_surface_resource_ids(_map_position)
	mesh_ground.visible = rids[CrawlMap.SURFACE_INDEX.Ground] >= 0
	mesh_ceiling.visible = rids[CrawlMap.SURFACE_INDEX.Ceiling] >= 0
	mesh_wall_north.visible = rids[CrawlMap.SURFACE_INDEX.North] >= 0
	mesh_wall_south.visible = rids[CrawlMap.SURFACE_INDEX.South] >= 0
	mesh_wall_east.visible = rids[CrawlMap.SURFACE_INDEX.East] >= 0
	mesh_wall_west.visible = rids[CrawlMap.SURFACE_INDEX.West] >= 0
	

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------

func set_map_origin(origin : Vector3i) -> void:
	_map_position = origin + map_offset
	_request_cell_update = true


