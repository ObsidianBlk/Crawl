extends Resource
class_name CrawlEntity

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal position_changed(from, to)
signal facing_changed(from, to)

signal interaction(entity)
signal attacked(dmg, type)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var uuid : StringName = &"":									set = set_uuid
@export var type : StringName = &"":									set = set_type
@export var position : Vector3i = Vector3i.ZERO:						set = set_position
@export var facing : CrawlGlobals.SURFACE = CrawlGlobals.SURFACE.North:	set = set_facing
@export var blocking : int = 0x3F
@export var meta : Dictionary = {}


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _mapref : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_uuid(id : StringName) -> void:
	if uuid == &"" and id != &"":
		uuid = id

func set_type(t : StringName) -> void:
	if type == &"" and t != &"":
		var parts : PackedStringArray = t.split(":")
		var count : int = parts.size()
		if not (count >= 1 and count <= 2): return
		if count == 2 and parts[1].is_empty(): return
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
func _SetMap(map : CrawlMap) -> void:
	if _mapref.get_ref() == map: return
	_mapref = weakref(map)

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
		&"up":
			d_facing = CrawlGlobals.SURFACE.Ceiling
		&"down":
			d_facing = CrawlGlobals.SURFACE.Ground
	return d_facing

func _EntitiesBlockingAt(position : Vector3i, surface : CrawlGlobals.SURFACE) -> bool:
	if _mapref.get_ref() == null: return false
	var map : CrawlMap = _mapref.get_ref()
	var entities : Array = map.get_entities({&"position": position})
	if entities.size() > 0:
		for entity in entities:
			if entity == self: continue # We can't block ourselves!
			if entity.is_blocking(surface):
				return true
	return false

func _CanMove(dir : CrawlGlobals.SURFACE) -> bool:
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(dir)
	if _mapref.get_ref() == null: return false
	var map : CrawlMap = _mapref.get_ref()
	if map.is_cell_surface_blocking(position, dir): return false
	if _EntitiesBlockingAt(position, dir): return false
	var adj_dir : CrawlGlobals.SURFACE = CrawlGlobals.Get_Adjacent_Surface(dir)
	if _EntitiesBlockingAt(neighbor_position, adj_dir): return false
	return true

func _Move(dir : CrawlGlobals.SURFACE, ignore_map : bool) -> int:
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(dir)
	if _mapref.get_ref() != null and not ignore_map:
		if not _CanMove(dir):
			return ERR_UNAVAILABLE
	
	var pold : Vector3i = position
	position = neighbor_position
	position_changed.emit(pold, position)
	
	return OK

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clone() -> CrawlEntity:
	var ent = CrawlEntity.new()
	ent.uuid = UUID.v7()
	ent.type = type
	ent.position = position
	ent.facing = facing
	ent.blocking = blocking
	return ent


func get_map() -> CrawlMap:
	return _mapref.get_ref()

func set_blocking(surface : CrawlGlobals.SURFACE, enable : bool) -> void:
	var i : int = CrawlGlobals.SURFACE.values().find(surface)
	if enable:
		blocking = blocking | (1 << i)
	else:
		blocking = blocking & (~(1 << i))

func is_blocking(surface : CrawlGlobals.SURFACE) -> bool:
	var i : int = CrawlGlobals.SURFACE.values().find(surface)
	return (blocking & (1 << i)) != 0

# WARNING: This doesn't actually return the direction of the stairs.
#  If there are stairs at the same Z level ahead, &"up" is returned
#  If there are stairs ahead and below (with no ground ahead), &"down" is returned.
# It's up to the entity doing the check to determine if directionality of the stairs is
# important
func stairs_ahead(dir : StringName) -> StringName:
	# TODO: Not sure this is wholly accurate now.
	if _mapref.get_ref() == null: return &""
	var map : CrawlMap = _mapref.get_ref()
	var is_on_stairs: bool = _mapref.get_ref().is_cell_stairs(position)
	var direction_surface : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(direction_surface)
	if not map.has_cell(neighbor_position): return &""
	if map.is_cell_stairs(neighbor_position) == false:
		# This doesn't mean there's stairs, We could be walking into a cell just ABOVE stairs
		# If the neighbor's ground IS blocking, then there are no stairs.
		if map.is_cell_surface_blocking(neighbor_position, CrawlGlobals.SURFACE.Ground): return &""
		# Otherwise, let's get the neighbors ground neighbor :)
		var gn_position : Vector3i = neighbor_position + CrawlGlobals.Get_Direction_From_Surface(CrawlGlobals.SURFACE.Ground)
		if map.has_cell(gn_position) and map.is_cell_stairs(gn_position) == false: return &""
		return &"down"
	return &"up"

func on_stairs() -> bool:
	if _mapref.get_ref() == null: return false
	return _mapref.get_ref().is_cell_stairs(position)

func get_basetype() -> String:
	if type == &"": return ""
	return type.split(":")[0]

func is_basetype(base_type : StringName) -> bool:
	if not type.begins_with(base_type): return false
	if type != base_type: return false
	return true

func get_subtype() -> String:
	if type == &"": return ""
	var parts : PackedStringArray = type.split(":")
	if parts.size() != 2:
		return ""
	return parts[1]

func is_subtype(sub_type : StringName) -> bool:
	return type.ends_with(":%s"%[sub_type])

func can_move(dir : StringName) -> bool:
	var d_facing : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	return _CanMove(d_facing)

func move(dir : StringName, ignore_map : bool = false) -> void:
	var d_facing : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	_Move(d_facing, ignore_map)

func turn_left() -> void:
	var ofacing : CrawlGlobals.SURFACE = facing
	facing = CrawlGlobals.Get_Surface_90Deg(facing, 1)
	facing_changed.emit(ofacing, facing)

func turn_right() -> void:
	var ofacing : CrawlGlobals.SURFACE = facing
	facing = CrawlGlobals.Get_Surface_90Deg(facing, -1)
	facing_changed.emit(ofacing, facing)

func get_entities() -> Array:
	if _mapref.get_ref() == null: return []
	return _mapref.get_ref().get_entities({&"position":position, &"type":&"item"})

func interact(entity : CrawlEntity) -> void:
	interaction.emit(entity)

func attack(dmg : float, att_type : CrawlGlobals.ATTACK_TYPE) -> void:
	attacked.emit(dmg, att_type)
