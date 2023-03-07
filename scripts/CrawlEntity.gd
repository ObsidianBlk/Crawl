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
@export var position : Vector3i = Vector3i.ZERO:						set = set_position
@export var facing : CrawlGlobals.SURFACE = CrawlGlobals.SURFACE.North:	set = set_facing
@export var blocking : int = 0x3F


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _map : CrawlMap = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
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
# Private Methods
# ------------------------------------------------------------------------------

func _Move(dir : CrawlGlobals.SURFACE) -> int:
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(dir)
	if _map != null:
		if _map.is_cell_surface_blocking(position, dir):
			return ERR_UNAVAILABLE
		# TODO: Check if neighbor position is occupied by a blocking entity!
	
	return OK

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_map(map : CrawlMap) -> void:
	pass

func get_map() -> CrawlMap:
	return _map

func move(back : bool = false) -> void:
	var dir : CrawlGlobals.SURFACE = facing
	if back:
		dir = CrawlGlobals.Get_Adjacent_Surface(facing)
	_Move(dir)

func strafe_left() -> void:
	_Move(CrawlGlobals.Get_Surface_90Deg(facing, 1))

func strafe_right() -> void:
	_Move(CrawlGlobals.Get_Surface_90Deg(facing, 1))

func turn_left() -> void:
	facing = CrawlGlobals.Get_Surface_90Deg(facing, 1)

func turn_right() -> void:
	facing = CrawlGlobals.Get_Surface_90Deg(facing, -1)
