extends Resource
class_name CrawlMap


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal cell_added(position)
signal cell_removed(position)
signal cell_changed(position)


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum SURFACE {North=0x01, East=0x02, South=0x04, West=0x08, Ground=0x10, Ceiling=0x20}
enum SURFACE_INDEX {North=0, East=1, South=2, West=3, Ground=4, Ceiling=5}

const RESOURCE_GROUND_DEFAULT : int = 0
const RESOURCE_CEILING_DEFAULT : int = 0
const RESOURCE_WALL_DEFAULT : int = 0


const CELL_SCHEMA : Dictionary = {
	&"blocking":{&"req":true, &"type":TYPE_INT, &"min":0, &"max":0x3F},
	&"rid":{&"req":true, &"type":TYPE_ARRAY, &"item":{&"type":TYPE_INT, &"min":0}}
}

const GRID_SCHEMA : Dictionary = {
	&"!KEY_OF_TYPE_V3I":{&"type":TYPE_VECTOR3I, &"def":CELL_SCHEMA}
}


# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _grid : Dictionary = {}
var _start_cell : Vector2i = Vector2i.ZERO


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _get(property : StringName) -> Variant:
	match property:
		&"grid":
			return _grid
		&"start_cell":
			return _start_cell
	return null

func _set(property : StringName, value : Variant) -> bool:
	var success : bool = false
	match property:
		&"grid":
			if typeof(value) == TYPE_DICTIONARY:
				if DSV.verify(value, GRID_SCHEMA) == OK:
					_grid = value
					success = true
		&"start_cell":
			if typeof(value) == TYPE_VECTOR2I:
				_start_cell = value
				success = true
	
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name = "Crawl Map",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "grid",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "start_cell",
			type = TYPE_VECTOR2I,
			usage = PROPERTY_USAGE_DEFAULT
		},
	]
	
	return arr

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

func _CreateDefaultCell() -> Dictionary:
	return {
		&"blocking": 0x3F,
		&"rid": [
			RESOURCE_WALL_DEFAULT,
			RESOURCE_WALL_DEFAULT,
			RESOURCE_WALL_DEFAULT,
			RESOURCE_WALL_DEFAULT,
			RESOURCE_GROUND_DEFAULT,
			RESOURCE_CEILING_DEFAULT,
		]
	}

func _CalcNeighborFrom(position : Vector3i, surface : SURFACE) -> Vector3i:
	match surface:
		SURFACE.North:
			return position + Vector3i.FORWARD
		SURFACE.East:
			return position + Vector3i.RIGHT
		SURFACE.South:
			return position + Vector3i.BACK
		SURFACE.West:
			return position + Vector3i.LEFT
		SURFACE.Ground:
			return position + Vector3i.DOWN
		SURFACE.Ceiling:
			return position + Vector3i.UP
	return position

func _CalcAdjacentSurface(surface : SURFACE) -> SURFACE:
	match surface:
		SURFACE.North:
			return SURFACE.South
		SURFACE.East:
			return SURFACE.West
		SURFACE.South:
			return SURFACE.North
		SURFACE.West:
			return SURFACE.East
		SURFACE.Ground:
			return SURFACE.Ceiling
		SURFACE.Ceiling:
			return SURFACE.Ground
	return surface


func _CloneCell(cell : Dictionary, ncell : Dictionary = {}) -> Dictionary:
	ncell[&"blocking"] = cell[&"blocking"]
	ncell[&"rid"] = []
	for rid in cell[&"rid"]:
		ncell[&"rid"] = rid
	return ncell

func _CloneGrid() -> Dictionary:
	var ngrid : Dictionary = {}
	for key in _grid:
		ngrid[key] = _CloneCell(_grid[key])
	return ngrid

func _CalcBlocking(block_val : int, surface : SURFACE, block : bool) -> int:
	if block:
		return (block_val | surface) & 0x3F
	return (block_val & (~surface)) & 0x3F

func _SetCellSurface(position : Vector3i, surface : SURFACE, data : Dictionary) -> void:
	var changed : bool = false
	if &"blocking" in data:
		_grid[position][&"blocking"] = _CalcBlocking(_grid[position][&"blocking"], surface, data[&"blocking"])
		changed = true
	if &"resource_id" in data:
		var idx : int = SURFACE.values().find(surface)
		if idx >= 0:
			_grid[position][&"rid"][idx] = data[&"resource_id"]
		changed = true
	
	if changed:
		cell_changed.emit(position)


func _GetCellSurface(position : Vector3i, surface : SURFACE) -> Dictionary:
	var idx : int = SURFACE.values().find(surface)
	if idx >= 0:
		return {
			&"blocking": _grid[position][&"blocking"] & surface != 0,
			&"resource_id": _grid[position][&"rid"][idx]
		}
	return {}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clone() -> CrawlMap:
	var cm : CrawlMap = CrawlMap.new()
	cm.start_cell = _start_cell
	cm.grid = _CloneGrid()
	return cm

func add_cell(position : Vector3i) -> int:
	if position in _grid:
		return ERR_ALREADY_EXISTS
	_grid[position] = _CreateDefaultCell()
	cell_added.emit(position)
	cell_changed.emit(position)
	return OK

func has_cell(position : Vector3i) -> bool:
	return position in _grid


func copy_cell(from_position : Vector3i, to_position : Vector3i) -> int:
	if from_position != to_position: # Nothing to do if from and to are the same.
		if not from_position in _grid:
			return ERR_DOES_NOT_EXIST
		if to_position in _grid:
			_CloneCell(_grid[from_position], _grid[to_position])
		else:
			_grid[to_position] = _CloneCell(_grid[from_position])
			cell_added.emit(to_position)
		cell_changed.emit(to_position)
	return OK

func remove_cell(position : Vector3i) -> void:
	if not position in _grid: return
	_grid.erase(position)
	cell_removed.emit(position)

func set_cell_surface(position : Vector3i, surface : SURFACE, blocking : bool, resource_id : int) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	if resource_id < 0:
		printerr("CrawlMap Error: Given resource ID out of range.")
		return
	_SetCellSurface(position, surface, {&"blocking":blocking, &"resource_id":resource_id})

func set_cell_surface_blocking(position : Vector3i, surface : SURFACE, blocking : bool) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	_SetCellSurface(position, surface, {&"blocking":blocking})

func set_cell_surface_resource_id(position : Vector3i, surface : SURFACE, resource_id) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	if resource_id < 0:
		printerr("CrawlMap Error: Given resource ID out of range.")
		return
	
	_SetCellSurface(position, surface, {&"resource_id":resource_id})

func get_cell(position : Vector3i, surface : SURFACE) -> Dictionary:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return {}
	return _GetCellSurface(position, surface)

func get_cell_surface_resource_id(position : Vector3i, surface : SURFACE) -> int:
	if position in _grid:
		var info : Dictionary = _GetCellSurface(position, surface)
		if not info.is_empty():
			return info[&"resource_id"]
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return -1

func get_cell_surface_resource_ids(position : Vector3i) -> Array:
	if position in _grid:
		var rids : Array = []
		for rid in _grid[position][&"rids"]:
			rids.append(rid)
		return rids
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return []

func is_cell_surface_blocking(position : Vector3i, surface : SURFACE) -> bool:
	if position in _grid:
		var info : Dictionary = _GetCellSurface(position, surface)
		if not info.is_empty():
			return info[&"blocking"]
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return true

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

