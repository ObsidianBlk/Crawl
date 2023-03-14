extends Resource
class_name CrawlEntity

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal position_changed(from, to)
signal facing_changed(from, to)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var uuid : StringName = &""
@export var type : StringName = &""
@export var position : Vector3i = Vector3i.ZERO:						set = set_position
@export var facing : CrawlGlobals.SURFACE = CrawlGlobals.SURFACE.North:	set = set_facing
@export var blocking : int = 0x3F
@export var meta : Dictionary = {}


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map : CrawlMap = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_uuid(id : StringName) -> void:
	if uuid == &"" and id != &"":
		uuid = id

func set_type(t : StringName) -> void:
	if type == &"" and t != &"":
		type = t

func set_position(pos : Vector3i) -> void:
	if pos != position:
		var from : Vector3i = position
		position = pos
		position_changed.emit(from, position)

func set_facing(f : CrawlGlobals.SURFACE) -> void:
	if f != facing:
		var old : CrawlGlobals.SURFACE = facing
		facing = f
		facing_changed.emit(old, facing)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DirectionNameToFacing(dir : StringName) -> CrawlGlobals.SURFACE:
	var d_facing : CrawlGlobals.SURFACE = CrawlGlobals.SURFACE.Ground
	match dir:
		&"foreward":
			d_facing = facing
		&"backward":
			d_facing = CrawlGlobals.Get_Adjacent_Surface(facing)
		&"left":
			d_facing = CrawlGlobals.Get_Surface_90Deg(facing, 1)
		&"right":
			d_facing = CrawlGlobals.Get_Surface_90Deg(facing, -1)
	return d_facing

func _CanMove(dir : CrawlGlobals.SURFACE) -> bool:
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(dir)
	if _map == null : return false
	if _map.is_cell_surface_blocking(position, dir): return false
	var entities : Array = _map.get_entities({&"position": neighbor_position})
	if entities.size() > 0:
		var adj_dir : CrawlGlobals.SURFACE = CrawlGlobals.Get_Adjacent_Surface(dir)
		for entity in entities:
			if entity.is_blocking(adj_dir):
				return false
	return true

func _Move(dir : CrawlGlobals.SURFACE, ignore_map : bool) -> int:
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(dir)
	if _map != null and not ignore_map:
		if not _CanMove(dir):
			return ERR_UNAVAILABLE
	
	position = neighbor_position
	position_changed.emit()
	
	return OK

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_map() -> CrawlMap:
	return _map

func set_blocking(surface : CrawlGlobals.SURFACE, enable : bool) -> void:
	var i : int = CrawlGlobals.SURFACE.values().find(surface)
	if enable:
		blocking = blocking | (1 << i)
	else:
		blocking = blocking & (~(1 << i))

func is_blocking(surface : CrawlGlobals.SURFACE) -> bool:
	var i : int = CrawlGlobals.SURFACE.values().find(surface)
	return (blocking & (1 << i)) != 0

func can_move(dir : StringName) -> bool:
	var d_facing : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	return false if d_facing == CrawlGlobals.SURFACE.Ground else _CanMove(d_facing)

func move(dir : StringName, ignore_map : bool = false) -> void:
	var d_facing : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	if d_facing == CrawlGlobals.SURFACE.Ground: return
	_Move(d_facing, ignore_map)

func turn_left() -> void:
	facing = CrawlGlobals.Get_Surface_90Deg(facing, 1)
	facing_changed.emit()

func turn_right() -> void:
	facing = CrawlGlobals.Get_Surface_90Deg(facing, -1)
	facing_changed.emit()
