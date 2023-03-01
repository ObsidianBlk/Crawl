extends Node3D
class_name CrawlCell


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null :						set = set_map
@export var map_position : Vector3i = Vector3i.ZERO:	set = set_map_position


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _requested_rebuild : bool = false
var _is_ready : bool = false

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
		if map != null:
			if map.cell_added.is_connected(_on_map_cell_changed):
				map.cell_added.disconnect(_on_map_cell_changed)
			if map.cell_changed.is_connected(_on_map_cell_changed):
				map.cell_changed.disconnect(_on_map_cell_changed)
			if map.cell_removed.is_connected(_on_map_cell_changed):
				map.cell_removed.disconnect(_on_map_cell_changed)
		
		map = nmap
		
		if map != null:
			if not map.cell_added.is_connected(_on_map_cell_changed):
				map.cell_added.connect(_on_map_cell_changed)
			if not map.cell_changed.is_connected(_on_map_cell_changed):
				map.cell_changed.connect(_on_map_cell_changed)
			if not map.cell_removed.is_connected(_on_map_cell_changed):
				map.cell_removed.connect(_on_map_cell_changed)
		_requested_rebuild = true


func set_map_position(mpos : Vector3i) -> void:
	if mpos != map_position:
		map_position = mpos
		_requested_rebuild = true

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_is_ready = true

func _process(_delta : float) -> void:
	if _is_ready and _requested_rebuild:
		_requested_rebuild = false
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
	if map == null or not map.has_cell(map_position):
		_ClearCell()
		return
	
	var rids : Array = map.get_cell_surface_resource_ids(map_position)
	mesh_ground.visible = rids[CrawlMap.SURFACE_INDEX.Ground] >= 0
	mesh_ceiling.visible = rids[CrawlMap.SURFACE_INDEX.Ceiling] >= 0
	mesh_wall_north.visible = rids[CrawlMap.SURFACE_INDEX.North] >= 0
	mesh_wall_south.visible = rids[CrawlMap.SURFACE_INDEX.South] >= 0
	mesh_wall_east.visible = rids[CrawlMap.SURFACE_INDEX.East] >= 0
	mesh_wall_west.visible = rids[CrawlMap.SURFACE_INDEX.West] >= 0
	

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_map_cell_changed(position : Vector3i) -> void:
	if position == map_position:
		_requested_rebuild = true


