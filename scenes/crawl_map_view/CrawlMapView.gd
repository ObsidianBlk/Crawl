extends Node3D


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const CRAWLCELL : PackedScene = preload("res://scenes/crawl_map_view/crawl_cell/CrawlCell.tscn")
const CELL_SIZE : float = 3.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null :				set = set_map
@export var unit_radius : int = 4 :				set = set_unit_radius

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _cells : Dictionary = {}
var _map_changed : bool = false
var _cell_update_requested : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var cell_container : Node3D = $CellContainer

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(cmap : CrawlMap) -> void:
	if cmap != map:
		if map != null:
			if map.focus_changed.is_connected(_UpdateCells):
				map.focus_changed.disconnect(_UpdateCells)
		map = cmap
		if map != null:
			if not map.focus_changed.is_connected(_UpdateCells):
				map.focus_changed.connect(_UpdateCells)
		_map_changed = true
		_cell_update_requested = true

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
func _UpdateCells(origin : Vector3i) -> void:
	if cell_container == null: return
	
	var min_pos : Array = [NAN, NAN, NAN]
	var max_pos : Array = [NAN, NAN, NAN]
	
	# --------------
	# Helper lambdas
	var _position_in_bounds : Callable = func(position : Vector3i) -> bool:
		if position.x < origin.x - unit_radius or position.x > origin.x + unit_radius:
			return false
		if position.y < origin.y - unit_radius or position.y > origin.y + unit_radius:
			return false
		if position.z < origin.z - unit_radius or position.z > origin.z + unit_radius:
			return false
		return true
	
	var _store_min_max : Callable = func(position : Vector3i) -> void:
		if is_nan(min_pos[0]) or min_pos[0] > position.x:
			min_pos[0] = position.x
		if is_nan(min_pos[1]) or min_pos[1] > position.y:
			min_pos[1] = position.y
		if is_nan(min_pos[2]) or min_pos[2] > position.z:
			min_pos[2] = position.z
		
		if is_nan(max_pos[0]) or max_pos[0] < position.x:
			max_pos[0] = position.x
		if is_nan(max_pos[1]) or max_pos[1] < position.y:
			max_pos[1] = position.y
		if is_nan(max_pos[2]) or max_pos[2] < position.z:
			max_pos[2] = position.z
	
	var _position_handled : Callable = func(position : Vector3i) -> bool:
		if not (position.x >= min_pos[0] and position.x <= max_pos[0]):
			return false
		if not (position.y >= min_pos[1] and position.y <= max_pos[1]):
			return false
		if not (position.z >= min_pos[2] and position.x <= max_pos[2]):
			return false
		return true

	# -------
	# Actual work!
	for child in cell_container.get_children():
		if not is_instance_of(child, CrawlCell): continue
		if not _position_in_bounds.call(child.map_position):
			child.queue_free()
			continue
		elif _map_changed:
			child.map = map
		_store_min_max.call(child.map_position)
	_map_changed = false

	for x in range(origin.x - unit_radius, (origin.x + unit_radius) + 1):
		for y in range(origin.y - unit_radius, (origin.y + unit_radius) + 1):
			for z in range(origin.z - unit_radius, (origin.z + unit_radius) + 1):
				var pos : Vector3i = Vector3i(x,y,z)
				if not _position_handled.call(pos):
					var cell : CrawlCell = CRAWLCELL.instantiate()
					cell.map = map
					cell.map_position = pos
					cell_container.add_child(cell)
					#print("Position : ", pos * CELL_SIZE)
					cell.position = pos * CELL_SIZE

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_focus_changed(focus_position : Vector3i) -> void:
	_cell_update_requested = true

