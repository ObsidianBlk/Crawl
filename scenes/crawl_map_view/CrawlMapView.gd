extends Node3D


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const CRAWLCELL : PackedScene = preload("res://scenes/crawl_map_view/crawl_cell/CrawlCell.tscn")
const CELL_SIZE : float = 5.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null :				set = set_map
@export var focus_type : StringName = &""
@export var unit_radius : int = 4 :				set = set_unit_radius

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _cells : Dictionary = {}
var _map_changed : bool = false
var _cell_update_requested : bool = false

var _focus_entity : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var cell_container : Node3D = $CellContainer

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(cmap : CrawlMap) -> void:
	if cmap != map:
#		if _focus_entity.get_ref() != null:
#			var entity : CrawlEntity = _focus_entity.get_ref()
#			if entity.position_change.is_connected(_on_focus_position_changed):
#				entity.position_changed.disconnect(_on_focus_position_changed)
#			if entity.facing_change.is_connected(_on_focus_facing_changed):
#				entity.facing_changed.disconnect(_on_focus_facing_changed)
#			_focus_entity = weakref(null)
		
		map = cmap
		_UpdateFocusEntity()
#		if map != null:
#			if not map.focus_changed.is_connected(_UpdateCells):
#				map.focus_changed.connect(_UpdateCells)
		_map_changed = true
		_cell_update_requested = true

func set_focus_type(t : StringName) -> void:
	if t != &"" and t != focus_type:
		focus_type = t
		_UpdateFocusEntity()

func set_unit_radius(ur : int) -> void:
	if ur > 0 and ur != unit_radius:
		unit_radius = ur
		_cell_update_requested = true

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

func _process(_delta : float) -> void:
	if cell_container != null and _cell_update_requested:
		_cell_update_requested = false
		_UpdateCells(map.get_focus_cell())

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFocusEntity() -> void:
	var entity : CrawlEntity = _focus_entity.get_ref()
	if entity != null:
		if map != null and entity.get_map() == map and entity.type == focus_type:
			return
		# TODO: Disconnect all Signals!!!
		_focus_entity = weakref(null)
	if map == null: return

	var elist : Array = map.get_entities({&"type":focus_type})
	if elist.size() > 0:
		# TODO: Connect all signals!!!
		_focus_entity = weakref(elist[0])

func _UpdateCells(origin : Vector3i) -> void:
	if cell_container == null: return
	
	var rad : Vector3 = Vector3(unit_radius, unit_radius, unit_radius)
	var bounds : AABB = AABB(Vector3(origin) - rad, rad*2)
	var stored_pos : Array = []
	var available_cells : Array = []
	
	for child in cell_container.get_children():
		if not is_instance_of(child, CrawlCell): continue
		if not bounds.has_point(Vector3(child.map_position)):
			available_cells.append(child)
			continue
		if _map_changed:
			child.map = map
		stored_pos.append(child.map_position)
	_map_changed = false
	
	for x in range(origin.x - unit_radius, (origin.x + unit_radius) + 1):
		for y in range(origin.y - unit_radius, (origin.y + unit_radius) + 1):
			for z in range(origin.z - unit_radius, (origin.z + unit_radius) + 1):
				var pos : Vector3i = Vector3i(x,y,z)
				if not stored_pos.has(pos):
					if available_cells.size() > 0:
						var cell : CrawlCell = available_cells.pop_back()
						cell.map_position = pos
						cell.position = pos * CELL_SIZE
					else:
						var cell : CrawlCell = CRAWLCELL.instantiate()
						cell.map = map
						cell.map_position = pos
						cell_container.add_child(cell)
						#print("Position : ", pos * CELL_SIZE)
						cell.position = pos * CELL_SIZE


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_focus_position_changed(from : Vector3i, to : Vector3i) -> void:
	pass

func _on_focus_facing_changed(from : CrawlGlobals.SURFACE, to : CrawlGlobals.SURFACE) -> void:
	pass

func _on_focus_changed(focus_position : Vector3i) -> void:
	_cell_update_requested = true

