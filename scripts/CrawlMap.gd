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
enum EDGE {North=0, East=1, South=2, West=3}

const RESOURCE_GROUND_DEFAULT : int = 0
const RESOURCE_CEILING_DEFAULT : int = 0
const RESOURCE_EDGE_DEFAULT : int = 0

const EDGE_SCHEMA : Dictionary = {
	&"blocking":{&"req":true, &"type":TYPE_BOOL},
	&"rid":{&"req":true, &"type":TYPE_INT, &"min":0}
}

const CELL_SCHEMA : Dictionary = {
	&"ground_rid":{&"req":true, &"type":TYPE_INT, &"min":0},
	&"ceiling_rid":{&"req":true, &"type":TYPE_INT, &"min":0},
	EDGE.North:{&"req":true, &"type":TYPE_DICTIONARY, &"def":EDGE_SCHEMA},
	EDGE.South:{&"req":true, &"type":TYPE_DICTIONARY, &"def":EDGE_SCHEMA},
	EDGE.East:{&"req":true, &"type":TYPE_DICTIONARY, &"def":EDGE_SCHEMA},
	EDGE.West:{&"req":true, &"type":TYPE_DICTIONARY, &"def":EDGE_SCHEMA},
}

const GRID_SCHEMA : Dictionary = {
#	&"!REFS": {
#		&"edge":{&"type":TYPE_DICTIONARY, &"def":EDGE_SCHEMA},
#		&"cell":{&"type":TYPE_DICTIONARY, &"def":{
#			&"ground_rid":{&"req":true, &"type":TYPE_INT, &"min":0},
#			&"ceiling_rid":{&"req":true, &"type":TYPE_INT, &"min":0},
#			EDGE.North:{&"req":true, &"ref":&"edge"},
#			EDGE.South:{&"req":true, &"ref":&"edge"},
#			EDGE.East:{&"req":true, &"ref":&"edge"},
#			EDGE.West:{&"req":true, &"ref":&"edge"},
#		}}
#	},
	&"!KEY_OF_TYPE_V2I":{&"type":TYPE_VECTOR2I, &"def":CELL_SCHEMA}#&"ref":&"cell"}
}

# ------------------------------------------------------------------------------
# Sub Class(es)
# ------------------------------------------------------------------------------
class Cell:
	# --- Private Variables
	var _parent : CrawlMap = null
	var _position : Vector2i = Vector2i.ZERO
	var _data : Dictionary = {}
	
	# --- Constructor
	func _init(position : Vector2i = Vector2i.ZERO, parent : CrawlMap = null) -> void:
		if parent != null:
			if parent.has_cell(position):
				_data = parent._grid[position]
				_parent = parent
				_position = position
		if _data.is_empty():
			_data = {
				&"ground_rid": RESOURCE_GROUND_DEFAULT,
				&"ceiling_rid": RESOURCE_CEILING_DEFAULT,
				EDGE.North:{
					&"blocking": false,
					&"rid": RESOURCE_EDGE_DEFAULT
				},
				EDGE.South:{
					&"blocking": false,
					&"rid": RESOURCE_EDGE_DEFAULT
				},
				EDGE.East:{
					&"blocking": false,
					&"rid": RESOURCE_EDGE_DEFAULT
				},
				EDGE.West:{
					&"blocking": false,
					&"rid": RESOURCE_EDGE_DEFAULT
				}
			}
	
	# --- Private Methods
	
	# --- Public Methods
	func remove() -> void:
		if _parent == null:
			printerr("CrawlMap Cell not associated with a CrawlMap resource.")
			return
		_parent.remove_cell(_position)
		if _parent.has_cell(_position):
			printerr("Failed to remove cell from CrawlMap resource.")
		
		_parent = null
		_position = Vector2i.ZERO
	
	func copy_to(position : Vector2i) -> CrawlMap.Cell:
		if _parent == null:
			printerr("CrawlMap Cell not associated with a CrawlMap resource.")
			return null
		
		if _parent.copy_cell(_position, position) != OK:
			printerr("Failed to copy cell to position ", position)
			return null
		
		return _parent.get_cell(position)
	


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
		&"ground_rid": RESOURCE_GROUND_DEFAULT,
		&"ceiling_rid": RESOURCE_CEILING_DEFAULT,
		EDGE.North:{
			&"blocking": false,
			&"rid": RESOURCE_EDGE_DEFAULT
		},
		EDGE.South:{
			&"blocking": false,
			&"rid": RESOURCE_EDGE_DEFAULT
		},
		EDGE.East:{
			&"blocking": false,
			&"rid": RESOURCE_EDGE_DEFAULT
		},
		EDGE.West:{
			&"blocking": false,
			&"rid": RESOURCE_EDGE_DEFAULT
		}
	}

func _CloneEdge(edge : Dictionary) -> Dictionary:
	return {
		&"blocking": edge[&"blocking"],
		&"rid": edge[&"rid"]
	}

func _CloneCell(cell : Dictionary, ncell : Dictionary = {}) -> Dictionary:
	ncell[&"ground_rid"] = cell[&"ground_rid"]
	ncell[&"ceiling_rid"] = cell[&"ceiling_rid"]
	ncell[EDGE.North] = _CloneEdge(cell[EDGE.North])
	ncell[EDGE.South] = _CloneEdge(cell[EDGE.South])
	ncell[EDGE.East] = _CloneEdge(cell[EDGE.East])
	ncell[EDGE.West] = _CloneEdge(cell[EDGE.West])
	
	return ncell

func _CloneGrid() -> Dictionary:
	var ngrid : Dictionary = {}
	for key in _grid:
		ngrid[key] = _CloneCell(_grid[key])
	return ngrid

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clone() -> CrawlMap:
	var cm : CrawlMap = CrawlMap.new()
	cm.start_cell = _start_cell
	cm.grid = _CloneGrid()
	return cm

func add_cell(position : Vector2i) -> int:
	if position in _grid:
		return ERR_ALREADY_EXISTS
	_grid[position] = _CreateDefaultCell()
	cell_added.emit(position)
	cell_changed.emit(position)
	return OK

func has_cell(position : Vector2i) -> bool:
	return position in _grid

func get_cell(position : Vector2i) -> CrawlMap.Cell:
	if position in _grid:
		return CrawlMap.Cell.new(position, self)
	return null

func copy_cell(from_position : Vector2i, to_position : Vector2i) -> int:
	if not from_position in _grid:
		return ERR_DOES_NOT_EXIST
	if to_position in _grid:
		_CloneCell(_grid[from_position], _grid[to_position])
	else:
		_grid[to_position] = _CloneCell(_grid[from_position])
		cell_added.emit(to_position)
	cell_changed.emit(to_position)
	return OK

func remove_cell(position : Vector2i) -> void:
	if not position in _grid: return
	_grid.erase(position)
	cell_removed.emit(position)

func set_cell_surfaces(position : Vector2i, ground_resource_id : int, ceiling_resource_id : int) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	_grid[position][&"ground_rid"] = ground_resource_id
	_grid[position][&"ceiling_rid"] = ceiling_resource_id

func set_cell_edge(position : Vector2i, edge : EDGE, blocking : bool, resource_id : int) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	_grid[position][edge][&"blocking"] = blocking
	_grid[position][edge][&"rid"] = resource_id

func set_cell_edge_blocking(position : Vector2i, edge : EDGE, blocking : bool) -> void:
	if not position in _grid:
		printerr("CrawlMap Error: No cell at position ", position)
		return
	_grid[position][edge][&"blocking"] = blocking

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

