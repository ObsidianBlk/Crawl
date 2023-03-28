extends GridContainer

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const arrow_north : Texture = preload("res://assets/icons/arrow_up.svg")
const arrow_south : Texture = preload("res://assets/icons/arrow_down.svg")
const arrow_east : Texture = preload("res://assets/icons/arrow_right.svg")
const arrow_west : Texture = preload("res://assets/icons/arrow_left.svg")

const icon_no_stairs : Texture = preload("res://assets/icons/add_stairs.svg")
const icon_has_stairs : Texture = preload("res://assets/icons/remove_stairs.svg")

const icon_blocking : Texture = preload("res://assets/icons/wall_blocking.svg")
const icon_unblocked : Texture = preload("res://assets/icons/wall_unblocked.svg")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null:				set = set_map
@export var focus_type : StringName = &"":		set = set_focus_type


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _focus_entity : WeakRef = weakref(null)
var _map_position : Vector3i = Vector3i.ZERO

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
#@onready var _facing_rect : TextureRect = %Facing
@onready var _btn_stairs : Button = %BTN_Stairs

@onready var _ceiling_view : Control = %ceiling_view
@onready var _ceiling_blocking : Button = %ceiling_blocking

@onready var _ground_view : Control = %ground_view
@onready var _ground_blocking : Button = %ground_blocking

@onready var _north_view : Control = %north_view
@onready var _north_blocking : Button = %north_blocking

@onready var _south_view : Control = %south_view
@onready var _south_blocking : Button = %south_blocking

@onready var _east_view : Control = %east_view
@onready var _east_blocking : Button = %east_blocking

@onready var _west_view : Control = %west_view
@onready var _west_blocking : Button = %west_blocking

@onready var _resource_items : PopupMenu = $ResourceItems

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(m : CrawlMap) -> void:
	if m != map:
		if map != null:
			if map.cell_changed.is_connected(_on_cell_changed):
				map.cell_changed.disconnect(_on_cell_changed)
			if map.entity_added.is_connected(_on_entity_added):
				map.entity_added.disconnect(_on_entity_added)
			if map.entity_removed.is_connected(_on_entity_removed):
				map.entity_removed.disconnect(_on_entity_removed)
		map = m
		if map != null:
			if not map.cell_changed.is_connected(_on_cell_changed):
				map.cell_changed.connect(_on_cell_changed)
			if not map.entity_added.is_connected(_on_entity_added):
				map.entity_added.connect(_on_entity_added)
			if not map.entity_removed.is_connected(_on_entity_removed):
				map.entity_removed.connect(_on_entity_removed)
		_UpdateFocusEntity()
		_UpdateResourceViews()

func set_focus_type(t : StringName) -> void:
	if t != focus_type:
		focus_type = t
		_UpdateFocusEntity()
		_UpdateResourceViews()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_resource_items.index_pressed.connect(_on_resource_item_index_selected)
	_ground_view.pressed.connect(_on_surface_pressed.bind(&"ground", CrawlGlobals.SURFACE.Ground))
	_ceiling_view.pressed.connect(_on_surface_pressed.bind(&"ceiling", CrawlGlobals.SURFACE.Ceiling))
	_north_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.North))
	_south_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.South))
	_east_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.East))
	_west_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.West))

	_ground_blocking.pressed.connect(
		_on_block_btn_pressed.bind(_ground_blocking, CrawlGlobals.SURFACE.Ground)
	)
	_ceiling_blocking.pressed.connect(
		_on_block_btn_pressed.bind(_ceiling_blocking, CrawlGlobals.SURFACE.Ceiling)
	)
	_north_blocking.pressed.connect(
		_on_block_btn_pressed.bind(_north_blocking, CrawlGlobals.SURFACE.North)
	)
	_south_blocking.pressed.connect(
		_on_block_btn_pressed.bind(_south_blocking, CrawlGlobals.SURFACE.South)
	)
	_east_blocking.pressed.connect(
		_on_block_btn_pressed.bind(_east_blocking, CrawlGlobals.SURFACE.East)
	)
	_west_blocking.pressed.connect(
		_on_block_btn_pressed.bind(_west_blocking, CrawlGlobals.SURFACE.West)
	)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFocusEntityTo(entity : CrawlEntity) -> void:
	if _focus_entity.get_ref() != null and _focus_entity.get_ref() != entity:
		var old_entity : CrawlEntity = _focus_entity.get_ref()
		if old_entity.position_changed.is_connected(_on_focus_position_changed):
			old_entity.position_changed.disconnect(_on_focus_position_changed)
		_focus_entity = weakref(null)
	if entity == null: return
	
	if not entity.position_changed.is_connected(_on_focus_position_changed):
		entity.position_changed.connect(_on_focus_position_changed)
	_focus_entity = weakref(entity)
	_map_position = entity.position

func _UpdateFocusEntity() -> void:
	if map == null or focus_type == &"":
		_UpdateFocusEntityTo(null)
		return	
	var elist : Array = map.get_entities({&"type":focus_type})
	if elist.size() <= 0: return
	_UpdateFocusEntityTo(elist[0])


func _ClearResourceViews() -> void:
	if _ground_view != null:
		_ground_view.clear()
		_ground_blocking.icon = icon_blocking
	
	if _ceiling_view != null:
		_ceiling_view.clear()
		_ceiling_blocking.icon = icon_blocking
	
	if _north_view != null:
		_north_view.clear()
		_north_blocking.icon = icon_blocking
	
	if _south_view != null:
		_south_view.clear()
		_south_blocking.icon = icon_blocking
	
	if _east_view != null:
		_east_view.clear()
		_east_blocking.icon = icon_blocking
	
	if _west_view != null:
		_west_view.clear()
		_west_blocking.icon = icon_blocking

func _UpdateResourceViews() -> void:
	if map == null or _focus_entity.get_ref() == null:
		_ClearResourceViews()
		return
	if not map.has_cell(_map_position):
		_btn_stairs.icon = icon_no_stairs
		_ClearResourceViews()
		return
	
	_btn_stairs.icon = icon_has_stairs if map.is_cell_stairs(_map_position) else icon_no_stairs
	
	var resource_name : StringName = map.get_cell_surface_resource(_map_position, CrawlGlobals.SURFACE.Ground)
	if resource_name != &"":
		_ground_view.set_resource(&"ground", resource_name)
	else:
		_ground_view.clear()
	var blocking : bool = map.is_cell_surface_blocking(_map_position, CrawlGlobals.SURFACE.Ground)
	_ground_blocking.icon = icon_blocking if blocking else icon_unblocked
	
	resource_name = map.get_cell_surface_resource(_map_position, CrawlGlobals.SURFACE.Ceiling)
	if resource_name != &"":
		_ceiling_view.set_resource(&"ceiling", resource_name)
	else:
		_ceiling_view.clear()
	blocking = map.is_cell_surface_blocking(_map_position, CrawlGlobals.SURFACE.Ceiling)
	_ceiling_blocking.icon = icon_blocking if blocking else icon_unblocked

	resource_name = map.get_cell_surface_resource(_map_position, CrawlGlobals.SURFACE.North)
	if resource_name != &"":
		_north_view.set_resource(&"wall", resource_name)
	else:
		_north_view.clear()
	blocking = map.is_cell_surface_blocking(_map_position, CrawlGlobals.SURFACE.North)
	_north_blocking.icon = icon_blocking if blocking else icon_unblocked

	resource_name = map.get_cell_surface_resource(_map_position, CrawlGlobals.SURFACE.South)
	if resource_name != &"":
		_south_view.set_resource(&"wall", resource_name)
	else:
		_south_view.clear()
	blocking = map.is_cell_surface_blocking(_map_position, CrawlGlobals.SURFACE.South)
	_south_blocking.icon = icon_blocking if blocking else icon_unblocked

	resource_name = map.get_cell_surface_resource(_map_position, CrawlGlobals.SURFACE.East)
	if resource_name != &"":
		_east_view.set_resource(&"wall", resource_name)
	else:
		_east_view.clear()
	blocking = map.is_cell_surface_blocking(_map_position, CrawlGlobals.SURFACE.East)
	_east_blocking.icon = icon_blocking if blocking else icon_unblocked

	resource_name = map.get_cell_surface_resource(_map_position, CrawlGlobals.SURFACE.West)
	if resource_name != &"":
		_west_view.set_resource(&"wall", resource_name)
	else:
		_west_view.clear()
	blocking = map.is_cell_surface_blocking(_map_position, CrawlGlobals.SURFACE.West)
	_west_blocking.icon = icon_blocking if blocking else icon_unblocked

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_cell_changed(cell_position : Vector3i) -> void:
	if cell_position == _map_position:
		_UpdateResourceViews()

func _on_entity_added(entity : CrawlEntity) -> void:
	if _focus_entity.get_ref() != null: return
	if focus_type == &"": return
	if not entity.type == focus_type: return
	_UpdateFocusEntityTo(entity)

func _on_entity_removed(entity : CrawlEntity) -> void:
	if entity != _focus_entity.get_ref(): return
	_UpdateFocusEntity()

func _on_focus_position_changed(from : Vector3i, to : Vector3i) -> void:
	if _map_position != to:
		_map_position = to
		_UpdateResourceViews()

#func _on_focus_facing_changed(from : CrawlGlobals.SURFACE, to : CrawlGlobals.SURFACE) -> void:
#	if _facing_rect == null: return
#	match to:
#		CrawlGlobals.SURFACE.North:
#			_facing_rect.texture = arrow_north
#		CrawlGlobals.SURFACE.South:
#			_facing_rect.texture = arrow_south
#		CrawlGlobals.SURFACE.East:
#			_facing_rect.texture = arrow_east
#		CrawlGlobals.SURFACE.West:
#			_facing_rect.texture = arrow_west

func _on_block_btn_pressed(btn : Button, surface : CrawlGlobals.SURFACE) -> void:
	if map == null or _focus_entity.get_ref() == null: return
	if btn.icon == icon_blocking:
		btn.icon = icon_unblocked
		map.set_cell_surface_blocking(_map_position, surface, false, true)
	elif btn.icon == icon_unblocked:
		btn.icon = icon_blocking
		map.set_cell_surface_blocking(_map_position, surface, true, true)

func _on_surface_pressed(section_name : StringName, surface : CrawlGlobals.SURFACE) -> void:
	if map == null or _resource_items.visible: return
	if not RLT.has_section(section_name): return
	_resource_items.clear()
	_resource_items.add_item("Empty")
	_resource_items.set_item_metadata(0, {
		&"section":&"",
		&"resource_name":&"",
		&"surface":surface
	})
	for item in RLT.get_resource_list(section_name):
		var idx : int = _resource_items.item_count
		_resource_items.add_item(item[&"description"])
		_resource_items.set_item_metadata(idx, {
			&"section":section_name,
			&"resource_name":item[&"name"],
			&"surface":surface
		})
	_resource_items.popup_centered()

func _on_resource_item_index_selected(idx : int) -> void:
	if map == null: return
	var meta = _resource_items.get_item_metadata(idx)
	if meta == null: return
	if typeof(meta) != TYPE_DICTIONARY: return
	map.set_cell_surface_resource(
		_map_position,
		meta[&"surface"],
		meta[&"resource_name"]
	)

func _on_set_to_defaults_pressed() -> void:
	if map == null: return
	map.set_cell_surfaces_to_defaults(_map_position)


func _on_btn_stairs_pressed() -> void:
	if map == null: return
	if not map.has_cell(_map_position): return
	if map.is_cell_stairs(_map_position):
		map.set_cell_stairs(_map_position, false)
		_btn_stairs.icon = icon_no_stairs
	else:
		map.set_cell_stairs(_map_position, true)
		_btn_stairs.icon = icon_has_stairs
