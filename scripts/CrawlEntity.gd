extends Resource
class_name CrawlEntity

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal name_changed(new_name)
signal position_changed(from, to)
signal facing_changed(from, to)

signal meta_value_changed(key)
signal meta_value_removed(key)

signal interaction(entity)
signal attacked(dmg, type)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var uuid : StringName = &"":									set = set_uuid
@export var entity_name : String = "":									set = set_entity_name
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

func set_entity_name(n : String) -> void:
	if n != entity_name:
		entity_name = n
		name_changed.emit(entity_name)

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

func _EntitiesBlockingAt(pos : Vector3i, surface : CrawlGlobals.SURFACE) -> bool:
	if _mapref.get_ref() == null: return false
	var map : CrawlMap = _mapref.get_ref()
	var entities : Array = map.get_entities({&"position": pos})
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
	var pold : Vector3i = position
	
	if _mapref.get_ref() == null or ignore_map:
		position = neighbor_position
		position_changed.emit(pold, position)
		return OK
	
	var move_allowed : bool = _CanMove(dir)
	var stairs_ahead : StringName = _StairsAhead(dir)
	if not move_allowed:
		if stairs_ahead == &"up":
			position = neighbor_position + CrawlGlobals.Get_Direction_From_Surface(CrawlGlobals.SURFACE.Ceiling)
			position_changed.emit(pold, position)
			return OK
		return ERR_UNAVAILABLE
	
	if stairs_ahead == &"down":
		position = neighbor_position + CrawlGlobals.Get_Direction_From_Surface(CrawlGlobals.SURFACE.Ground)
	else:
		position = neighbor_position
	position_changed.emit(pold, position)
	return OK

func _StairsAhead(surface : CrawlGlobals.SURFACE) -> StringName:
	if _mapref.get_ref() == null: return &""
	var map : CrawlMap = _mapref.get_ref()
	
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(surface)
	
	if _CanMove(surface):
		# If the neighbor's ground is blocking, there are no stairs.
		if map.is_cell_surface_blocking(neighbor_position, CrawlGlobals.SURFACE.Ground): return &""
		
		# Get the diagnal down position.
		var diag_down_position = neighbor_position + CrawlGlobals.Get_Direction_From_Surface(CrawlGlobals.SURFACE.Ground)
		# Is there a cell
		if not map.has_cell(diag_down_position): return &""
		# Does that cell have stairs
		if not map.is_cell_stairs(diag_down_position): return &""
		return &"down"

	# If there a traversable space above...
	if not _CanMove(CrawlGlobals.SURFACE.Ceiling): return &""
	
	# Get cell position diagnally up from current position.
	var diag_up_position = neighbor_position + CrawlGlobals.Get_Direction_From_Surface(CrawlGlobals.SURFACE.Ceiling)
	# If there a cell at the diagnal-up position
	if not map.has_cell(diag_up_position): return &"" # If not, can't move
	# We also can't move if we're not already ON stairs for upward transitions.
	if not map.is_cell_stairs(position): return &""
	return &"up"

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

func set_meta_value(key : String, value : Variant) -> void:
	if key.is_empty(): return
	meta[key] = value
	meta_value_changed.emit(key)

func get_meta_value(key : String, default : Variant = null) -> Variant:
	if key in meta:
		return meta[key]
	return default

func has_meta_key(key : String) -> bool:
	return key in meta

func get_meta_keys() -> PackedStringArray:
	return PackedStringArray(meta.keys())

func erase_meta_key(key : String) -> void:
	if not key in meta: return
	meta.erase(key)
	meta_value_removed.emit(key)

func set_blocking(surface : CrawlGlobals.SURFACE, enable : bool) -> void:
	var i : int = CrawlGlobals.SURFACE.values().find(surface)
	if enable:
		blocking = blocking | (1 << i)
	else:
		blocking = blocking & (~(1 << i))

func set_block_all(enable : bool) -> void:
	blocking = CrawlGlobals.ALL_SURFACES if enable else 0

func is_blocking(surface : CrawlGlobals.SURFACE) -> bool:
	var i : int = CrawlGlobals.SURFACE.values().find(surface)
	return (blocking & (1 << i)) != 0

func stairs_ahead(dir : StringName) -> StringName:
	var direction_surface : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	return _StairsAhead(direction_surface)

func on_stairs() -> bool:
	if _mapref.get_ref() == null: return false
	return _mapref.get_ref().is_cell_stairs(position)

func get_basetype() -> String:
	if type == &"": return ""
	return type.split(":")[0]

func is_basetype(base_type : StringName) -> bool:
	if type.begins_with(&"%s:"%[base_type]): return true
	if type == base_type: return true
	return false

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

func move(dir : StringName, ignore_map : bool = false) -> int:
	var d_facing : CrawlGlobals.SURFACE = _DirectionNameToFacing(dir)
	return _Move(d_facing, ignore_map)

func turn_left() -> void:
	var ofacing : CrawlGlobals.SURFACE = facing
	facing = CrawlGlobals.Get_Surface_90Deg(facing, 1)
	facing_changed.emit(ofacing, facing)

func turn_right() -> void:
	var ofacing : CrawlGlobals.SURFACE = facing
	facing = CrawlGlobals.Get_Surface_90Deg(facing, -1)
	facing_changed.emit(ofacing, facing)

func get_entities(options : Dictionary = {}) -> Array:
	if _mapref.get_ref() == null: return []
	return _mapref.get_ref().get_entities(options)

func get_local_entities(options : Dictionary = {}) -> Array:
	options[&"position"] = position
	return get_entities(options)

func get_adjacent_entities(options : Dictionary = {}) -> Array:
	var neighbor_position : Vector3i = position + CrawlGlobals.Get_Direction_From_Surface(facing)
	options[&"position"] = neighbor_position
	return get_entities(options)

func interact(entity : CrawlEntity) -> void:
	interaction.emit(entity)

func attack(dmg : float, att_type : CrawlGlobals.ATTACK_TYPE) -> void:
	attacked.emit(dmg, att_type)
