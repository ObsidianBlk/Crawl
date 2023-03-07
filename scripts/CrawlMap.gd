@tool
extends Resource
class_name CrawlMap


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal cell_added(position)
signal cell_removed(position)
signal cell_changed(position)

signal focus_changed(focus_position)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------

const RESOURCE_GROUND_DEFAULT : int = 0
const RESOURCE_CEILING_DEFAULT : int = 0
const RESOURCE_WALL_DEFAULT : int = 0


const CELL_SCHEMA : Dictionary = {
	&"blocking":{&"req":true, &"type":TYPE_INT, &"min":0, &"max":0x3F},
	&"rid":{&"req":true, &"type":TYPE_ARRAY, &"item":{&"type":TYPE_INT, &"min":0}},
	&"visited":{&"req":true, &"type":TYPE_BOOL}
}

const GRID_SCHEMA : Dictionary = {
	&"!KEY_OF_TYPE_V3I":{&"type":TYPE_VECTOR3I, &"def":CELL_SCHEMA}
}

const RESOURCES_SCHEMA : Dictionary = {
	&"!KEY_OF_TYPE_sn":{&"type":TYPE_STRING_NAME, &"def":{&"type":TYPE_INT, &"min":-1}}
}


# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _resources : Dictionary = {}
var _grid : Dictionary = {}
var _start_cell : Vector3i = Vector3i.ZERO

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _next_rid : int = 0
var _focus_cell : Vector3i = Vector3i.ZERO

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _get(property : StringName) -> Variant:
	match property:
		&"grid":
			return _grid
		&"resources":
			return _resources
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
		&"resources":
			if typeof(value) == TYPE_DICTIONARY:
				if DSV.verify(value, RESOURCES_SCHEMA) == OK:
					_resources = value
					_next_rid = 0
					for key in _resources.keys():
						if _resources[key] > _next_rid:
							_next_rid = _resources[key] + 1
					success = true
		&"start_cell":
			if typeof(value) == TYPE_VECTOR3I:
				if not value in _grid:
					printerr("CrawlMap Warning: Assigned start cell, ", value, ", is not currently defined in the grid.")
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
			name = "resources",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "start_cell",
			type = TYPE_VECTOR3I,
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
		&"visited":false,
		&"rid": [
			RESOURCE_WALL_DEFAULT,
			RESOURCE_WALL_DEFAULT,
			RESOURCE_WALL_DEFAULT,
			RESOURCE_WALL_DEFAULT,
			RESOURCE_GROUND_DEFAULT,
			RESOURCE_CEILING_DEFAULT,
		]
	}


func _CalcNeighborFrom(position : Vector3i, surface : CrawlGlobals.SURFACE) -> Vector3i:
	return position + CrawlGlobals.Get_Direction_From_Surface(surface)


func _CloneCell(cell : Dictionary, ncell : Dictionary = {}) -> Dictionary:
	ncell[&"blocking"] = cell[&"blocking"]
	ncell[&"visited"] = cell[&"visited"]
	ncell[&"rid"] = []
	for rid in cell[&"rid"]:
		ncell[&"rid"] = rid
	return ncell

func _CloneGrid() -> Dictionary:
	var ngrid : Dictionary = {}
	for key in _grid:
		ngrid[key] = _CloneCell(_grid[key])
	return ngrid

func _CalcBlocking(block_val : int, surface : CrawlGlobals.SURFACE, block : bool) -> int:
	if block:
		return (block_val | surface) & 0x3F
	return (block_val & (~surface)) & 0x3F

func _SetCellSurface(position : Vector3i, surface : CrawlGlobals.SURFACE, data : Dictionary, bi_directional : bool) -> void:
	var changed : bool = false
	if &"blocking" in data:
		_grid[position][&"blocking"] = _CalcBlocking(_grid[position][&"blocking"], surface, data[&"blocking"])
		changed = true
	if &"resource_id" in data:
		var idx : int = CrawlGlobals.SURFACE.values().find(surface)
		if idx >= 0:
			_grid[position][&"rid"][idx] = data[&"resource_id"]
		changed = true
	
	if changed:
		cell_changed.emit(position)
	
	if bi_directional:
		var pos : Vector3i = _CalcNeighborFrom(position, surface)
		var surf : CrawlGlobals.SURFACE = CrawlGlobals.Get_Adjacent_Surface(surface)
		_SetCellSurface(pos, surf, data, false)


func _GetCellSurface(position : Vector3i, surface : CrawlGlobals.SURFACE) -> Dictionary:
	var idx : int = CrawlGlobals.SURFACE.values().find(surface)
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

func add_resource(resource : StringName) -> int:
	if resource in _resources:
		return ERR_ALREADY_IN_USE
	_resources[resource] = _next_rid
	_next_rid += 1
	return OK

func has_resource(resource : StringName) -> bool:
	return resource in _resources

func get_resource_id(resource : StringName) -> int:
	if resource in _resources:
		return _resources[resource]
	return -1

func get_resource_name_from_id(resource_id) -> StringName:
	var key = _resources.find_key(resource_id)
	return key if key != null else &""

func get_resources() -> Array:
	return _resources.keys()

func clear_unused_resources() -> void:
	var nr : Dictionary = {}
	var highest_rid : int = 0
	for cell in _grid.keys():
		for rid in _grid[cell][&"rid"]:
			if rid < 0:
				continue
			var key = _resources.find_key(rid)
			if key == null:
				continue
			if key in nr:
				continue
			nr[key] = _resources[key]
			if rid > highest_rid:
				highest_rid = rid + 1
	_resources = nr
	_next_rid = highest_rid

func add_cell(position : Vector3i, open_to_adjacent : bool = false) -> int:
	if position in _grid:
		return ERR_ALREADY_EXISTS
	_grid[position] = _CreateDefaultCell()
	cell_added.emit(position)
	if open_to_adjacent:
		for surface in CrawlGlobals.SURFACE.values():
			var neighbor_position : Vector3i = _CalcNeighborFrom(position, surface)
			if neighbor_position in _grid:
				dig(position, surface)
	else:
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

func set_cell_surface(position : Vector3i, surface : CrawlGlobals.SURFACE, blocking : bool, resource_id : Variant, bi_directional : bool = false) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	
	var data : Dictionary = {
		&"blocking": blocking
	}
	if typeof(resource_id) == TYPE_INT:
		if resource_id < 0 or _resources.find_key(resource_id) != null:
			data[&"resource_id"] = resource_id
	elif typeof(resource_id) == TYPE_STRING_NAME or typeof(resource_id) == TYPE_STRING:
		if resource_id in _resources:
			data[&"resource_id"] = _resources[resource_id]
		else:
			var rid : int = _next_rid
			_resources[StringName(resource_id)] = rid
			_next_rid += 1
			data[&"resource_id"] = rid
	
	_SetCellSurface(position, surface, data, bi_directional)

func set_cell_surface_blocking(position : Vector3i, surface : CrawlGlobals.SURFACE, blocking : bool, bi_directional : bool = false) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	_SetCellSurface(position, surface, {&"blocking":blocking}, bi_directional)


func set_cell_surface_resource(position : Vector3i, surface : CrawlGlobals.SURFACE, resource_id : Variant, bi_directional : bool = false) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return

	var data : Dictionary = {}
	if typeof(resource_id) == TYPE_INT:
		if resource_id < 0 or _resources.find_key(resource_id) != null:
			data[&"resource_id"] = resource_id
	elif typeof(resource_id) == TYPE_STRING_NAME or typeof(resource_id) == TYPE_STRING:
		if resource_id in _resources:
			data[&"resource_id"] = _resources[resource_id]
		else:
			var rid : int = _next_rid
			_resources[StringName(resource_id)] = rid
			_next_rid += 1
			data[&"resource_id"] = rid
	
	if not data.is_empty():
		_SetCellSurface(position, surface, data, bi_directional)


func get_cell(position : Vector3i, surface : CrawlGlobals.SURFACE) -> Dictionary:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return {}
	return _GetCellSurface(position, surface)

func get_cell_surface_resource_id(position : Vector3i, surface : CrawlGlobals.SURFACE) -> int:
	if position in _grid:
		var info : Dictionary = _GetCellSurface(position, surface)
		if not info.is_empty():
			return info[&"resource_id"]
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return -1

func get_cell_surface_resource(position : Vector3i, surface : CrawlGlobals.SURFACE) -> StringName:
	if position in _grid:
		var info : Dictionary = _GetCellSurface(position, surface)
		if not info.is_empty():
			var key = _resources.find_key(info[&"resource_id"])
			if key != null:
				return key
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return &""

func get_cell_surface_resource_ids(position : Vector3i) -> Array:
	if position in _grid:
		var rids : Array = []
		for rid in _grid[position][&"rid"]:
			rids.append(rid)
		return rids
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return []

func get_cell_surface_resources(position : Vector3i) -> Array:
	if position in _grid:
		var resources : Array = []
		for rid in _grid[position][&"rid"]:
			var key = _resources.find_key(rid)
			if key != null:
				resources.append(key)
		return resources
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return []

func is_cell_surface_blocking(position : Vector3i, surface : CrawlGlobals.SURFACE) -> bool:
	if position in _grid:
		var info : Dictionary = _GetCellSurface(position, surface)
		if not info.is_empty():
			return info[&"blocking"]
	else:
		printerr("CrawlMap Error: No cell at position ", position)
	return true

func get_used_cells(visited_only : bool = false) -> Array:
	var list : Array = _grid.keys()
	if visited_only:
		list = list.filter(func(pos : Vector3i): return _grid[pos][&"visited"])
	return list

func get_used_cells_from(position : Vector3i, visited_only : bool = false, limit_to_layer : bool = false, cell_range : int = 0) -> Array:
	var cells : Array = []
	for cell in _grid.keys():
		if limit_to_layer and cell.y != position.y:
			continue
		if cell_range > 0 and Vector3(position).distance_to(Vector3(cell)) > float(cell_range):
			continue
		if visited_only and not _grid[cell][&"visited"]:
			continue
		cells.append(cell)
	return cells

func set_focus_cell(focus : Vector3i) -> void:
	var old_focus : Vector3i = _focus_cell
	if _grid.is_empty() or focus in _grid:
		_focus_cell = focus
	elif not _focus_cell in _grid:
		if _start_cell in _grid:
			_focus_cell = _start_cell
		else:
			_focus_cell = _grid.keys()[0]
	if _focus_cell != old_focus:
		focus_changed.emit(_focus_cell)

func get_focus_cell() -> Vector3i:
	if not _grid.is_empty() and not _focus_cell in _grid:
		return _grid.keys()[0]
	return _focus_cell

#func get_surface_from_direction(dir : Vector3) -> SURFACE:
#	dir = dir.normalized()
#	var deg45 : float = deg_to_rad(45.0)
#	if dir.angle_to(Vector3(0,0,1)) < deg45:
#		return SURFACE.North
#	if dir.angle_to(Vector3(-1,0,0)) < deg45:
#		return SURFACE.East
#	if dir.angle_to(Vector3(0,0,-1)) < deg45:
#		return SURFACE.South
#	if dir.angle_to(Vector3(1,0,0)) < deg45:
#		return SURFACE.West
#	if dir.angle_to(Vector3(0,1,0)) < deg45:
#		return SURFACE.Ceiling
#	return SURFACE.Ground

func dig(position : Vector3i, direction : CrawlGlobals.SURFACE) -> void:
	if not position in _grid:
		add_cell(position)
	var neighbor_position : Vector3i = _CalcNeighborFrom(position, direction)
	if not neighbor_position in _grid:
		add_cell(neighbor_position)
	set_cell_surface(position, direction, false, -1, true)

func dig_room(position : Vector3i, size : Vector3i, ground_rid : int, ceiling_rid : int, wall_rid : int) -> void:
	# Readjusting position for possible negative size values.
	position.x += size.x if size.x < 0 else 0
	position.y += size.y if size.y < 0 else 0
	position.z += size.z if size.z < 0 else 0
	
	size = abs(size)
	var target : Vector3i = position + size
	
	var _set_surface : Callable = func(pos : Vector3i, surf : CrawlGlobals.SURFACE, blocking : bool, rid : int) -> void:
		if not pos in _grid: return
		set_cell_surface(pos, surf, blocking, rid if blocking else -1)
	
	for k in range(position.z, target.z):
		for j in range(position.y, target.y):
			for i in range(position.x, target.x):
				var pos : Vector3i = Vector3i(i,j,k)
				if not pos in _grid:
					add_cell(pos)
					_set_surface.call(pos, CrawlGlobals.SURFACE.Ground, j == position.y, ground_rid)
					_set_surface.call(pos, CrawlGlobals.SURFACE.Ceiling, j + 1 == target.y, ceiling_rid)
					_set_surface.call(pos, CrawlGlobals.SURFACE.North, k + 1 == target.z, wall_rid)
					_set_surface.call(pos, CrawlGlobals.SURFACE.South, k == position.z, wall_rid)
					_set_surface.call(pos, CrawlGlobals.SURFACE.East, i == position.x, wall_rid)
					_set_surface.call(pos, CrawlGlobals.SURFACE.West, i + 1 == target.x, wall_rid)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

