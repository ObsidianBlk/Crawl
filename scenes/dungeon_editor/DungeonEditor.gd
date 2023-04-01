extends Node3D

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ARROW_NORTH : Texture = preload("res://assets/icons/arrow_up.svg")
const ARROW_EAST : Texture = preload("res://assets/icons/arrow_right.svg")
const ARROW_SOUTH : Texture = preload("res://assets/icons/arrow_down.svg")
const ARROW_WEST : Texture = preload("res://assets/icons/arrow_left.svg")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active_map : CrawlMap = null
var _viewer : Node3D = null

var _entity_nodes : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _entity_selector : Window = $UI/EntitySelector
@onready var _map_information : Window = $UI/MapInformation
@onready var _editor_options : PopupPanel = $UI/EditorOptions

@onready var _map_view : Node3D = %CrawlMapView
@onready var _mini_map : CrawlMiniMap = %CrawlMiniMap
@onready var _entity_container : Node3D = $"EntityContainer"
@onready var _world_environment : WorldEnvironment = %WorldEnvironment

@onready var _default_cell_editor : Control = %DefaultCellEditor
@onready var _active_cell_editor : Control = %ActiveCellEditor
@onready var _active_cell_entities : Control = %Entities

@onready var _label_mapname : Label = %MapName

@onready var _label_localcoord : Label = %Label_LocalCoord
@onready var _texture_facing : TextureRect = %Texture_Facing


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	CrawlGlobals.Set_Editor_Mode(true)
	CrawlGlobals.crawl_config_value_changed.connect(_on_config_value_changed)
	CrawlGlobals.crawl_config_loaded.connect(_on_config_loaded)
	
	_default_cell_editor.ceiling_resource = &"basic"
	_default_cell_editor.ground_resource = &"basic"
	_default_cell_editor.north_resource = &"basic"
	_default_cell_editor.south_resource = &"basic"
	_default_cell_editor.east_resource = &"basic"
	_default_cell_editor.west_resource = &"basic"
	_default_cell_editor.resource_changed.connect(_on_resource_changed)
	
	_mini_map.selection_finished.connect(_on_selection_finished)
	_active_cell_editor.focus_type = &"Editor"
	_entity_selector.entity_created.connect(_on_entity_created)
	_map_information.map_information_updated.connect(_on_map_information_updated)
	
	_active_cell_entities.entity_selection_requested.connect(_on_entity_pressed)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearEntities() -> void:
	if _entity_container == null: return
	for child in _entity_container.get_children():
		_entity_container.remove_child(child)
		child.queue_free()
	_entity_nodes.clear()
	_viewer = null

func _RemoveMap() -> void:
	if _active_map == null: return
	_ClearEntities()
	if _active_map.entity_added.is_connected(_on_entity_added):
		_active_map.entity_added.disconnect(_on_entity_added)
	if _active_map.entity_removed.is_connected(_on_entity_removed):
		_active_map.entity_removed.disconnect(_on_entity_removed)
	_active_map = null
	_map_view.map = null
	_mini_map.map = null
	_active_cell_editor.map = null
	_active_cell_entities.map = null

func _AddMapEntities() -> void:
	if _active_map == null: return
	var elist : Array = _active_map.get_entities({})
	for entity in elist:
		_on_entity_added(entity)

func _UpdateEnvironment(env : Environment, sec_key : String, value : bool) -> void:
	match sec_key:
		"Graphics:SSAO":
			env.ssao_enabled = value
		"Graphics:SSIL":
			env.ssil_enabled = value
		"Graphics:Fog":
			env.fog_enabled = value
		"Graphics:VFog":
			env.volumetric_fog_enabled = value

func _SetWorldEnvironment() -> void:
	if _active_map == null: return
	var wer : StringName = _active_map.get_world_environment()
	var env : Environment = RLT.instantiate_environment(wer)
	if env == null:
		env = RLT.instantiate_environment(&"default")
		if env == null: return
	
	# With a valid world environment object, enable/disable those values
	# set in the game Settings file!
	_UpdateEnvironment(env, "Graphics:SSAO", CrawlGlobals.Get_Config_Value("Graphics", "SSAO", true))
	_UpdateEnvironment(env, "Graphics:SSIL", CrawlGlobals.Get_Config_Value("Graphics", "SSIL", true))
	_UpdateEnvironment(env, "Graphics:FOG", CrawlGlobals.Get_Config_Value("Graphics", "FOG", true))
	_UpdateEnvironment(env, "Graphics:VFog", CrawlGlobals.Get_Config_Value("Graphics", "VFog", true))
	
	_world_environment.environment = env

func _UpdateMapName() -> void:
	if _active_map == null: return
	if _active_map.name.is_empty():
		_label_mapname.text = "Unnamed Map"
	else:
		_label_mapname.text = _active_map.name
	if _active_map.author.is_empty():
		_label_mapname.tooltip_text = "Unknown Author"
	else:
		_label_mapname.tooltip_text = "Authored By: %s"%[_active_map.author]

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_config_reset_requested() -> void:
	pass

func _on_config_loaded() -> void:
	if _world_environment == null: return
	var env : Environment = _world_environment.environment
	if env == null: return
	_UpdateEnvironment(env, "Graphics:SSAO", CrawlGlobals.Get_Config_Value("Graphics", "SSAO", true))
	_UpdateEnvironment(env, "Graphics:SSIL", CrawlGlobals.Get_Config_Value("Graphics", "SSIL", true))
	_UpdateEnvironment(env, "Graphics:FOG", CrawlGlobals.Get_Config_Value("Graphics", "FOG", true))
	_UpdateEnvironment(env, "Graphics:VFog", CrawlGlobals.Get_Config_Value("Graphics", "VFog", true))

func _on_config_value_changed(section : String, key : String, value : Variant) -> void:
	if typeof(value) != TYPE_BOOL: return
	if _world_environment == null: return
	var env : Environment = _world_environment.environment
	if env == null: return
	var sec_key = "%s:%s"%[section, key]
	_UpdateEnvironment(env, sec_key, value)

func _on_resource_changed() -> void:
	if _active_map == null: return
	_active_map.set_default_surface_resource(
		CrawlGlobals.SURFACE.Ground,
		_default_cell_editor.ground_resource
	)
	_active_map.set_default_surface_resource(
		CrawlGlobals.SURFACE.Ceiling,
		_default_cell_editor.ceiling_resource
	)
	_active_map.set_default_surface_resource(
		CrawlGlobals.SURFACE.North,
		_default_cell_editor.north_resource
	)
	_active_map.set_default_surface_resource(
		CrawlGlobals.SURFACE.South,
		_default_cell_editor.south_resource
	)
	_active_map.set_default_surface_resource(
		CrawlGlobals.SURFACE.East,
		_default_cell_editor.east_resource
	)
	_active_map.set_default_surface_resource(
		CrawlGlobals.SURFACE.West,
		_default_cell_editor.west_resource
	)


func _on_selection_finished(sel_position : Vector3i, sel_size : Vector3i) -> void:
	if _active_map == null: return
	_active_map.dig_room(sel_position, sel_size)

func _on_dig(from_position : Vector3i, surface : CrawlGlobals.SURFACE) -> void:
	if _active_map == null: return
	_active_map.dig(from_position, surface)

func _on_fill(from_position : Vector3i, surface : CrawlGlobals.SURFACE) -> void:
	if _active_map == null: return
	_active_map.fill(from_position, surface)

func _on_entity_added(entity : CrawlEntity) -> void:
	if _entity_container == null: return
	if entity.uuid in _entity_nodes: return
	
	var node = RLT.instantiate_resource(&"entity", entity.type)
	if node == null: return
	if is_instance_of(node, CrawlEntityNode3D):
		node.set_editor_mode(true)
	
	node.entity = entity
	_entity_nodes[entity.uuid] = node
	_entity_container.add_child(node)
	
	if entity.type == &"Editor":
		_active_map.set_entity_as_focus(entity)
		if node.has_signal("dig"):
			node.dig.connect(_on_dig)
		if node.has_signal("fill"):
			node.fill.connect(_on_fill)

func _on_entity_removed(entity : CrawlEntity) -> void:
	if not entity.uuid in _entity_nodes: return
	
	var node : Node3D = _entity_nodes[entity.uuid]
	_entity_nodes.erase(entity.uuid)
	
	if _entity_container == null: return
	
	_entity_container.remove_child(node)
	node.queue_free()

func _on_focus_position_changed(focus_position : Vector3i) -> void:
	_label_localcoord.text = "%d, %d, %d"%[focus_position.x, focus_position.y, focus_position.z]

func _on_focus_facing_changed(surface : CrawlGlobals.SURFACE) -> void:
	match surface:
		CrawlGlobals.SURFACE.North:
			_texture_facing.texture = ARROW_NORTH
		CrawlGlobals.SURFACE.East:
			_texture_facing.texture = ARROW_EAST
		CrawlGlobals.SURFACE.South:
			_texture_facing.texture = ARROW_SOUTH
		CrawlGlobals.SURFACE.West:
			_texture_facing.texture = ARROW_WEST

func _on_new_map_pressed():
	_RemoveMap()
	
	_active_map = CrawlMap.new()
	_active_map.entity_added.connect(_on_entity_added)
	_active_map.entity_removed.connect(_on_entity_removed)
	_active_map.focus_position_changed.connect(_on_focus_position_changed)
	_active_map.focus_facing_changed.connect(_on_focus_facing_changed)
	_on_resource_changed()
	_active_map.add_cell(Vector3.ZERO)
	
	_SetWorldEnvironment()
	_UpdateMapName()
	
	_map_view.map = _active_map
	_mini_map.map = _active_map
	
	#_viewer.entity = RLT.instantiate_resource(&"entity", editor_entity.type)#editor_entity
	_active_cell_editor.map = _active_map
	_active_cell_entities.map = _active_map
	
	var editor_entity : CrawlEntity = CrawlEntity.new()
	editor_entity.uuid = UUID.v7()
	editor_entity.type = &"Editor"
	editor_entity.position = Vector3i.ZERO
	
	_active_map.add_entity(editor_entity)
	#_active_map.set_entity_as_focus(editor_entity)


func _on_save_pressed():
	if _active_map == null: return
	var res : int = ResourceSaver.save(_active_map, "user://map.tres")
	if res == OK:
		print("Save Successful")

func _on_load_pressed():
	var map = ResourceLoader.load("user://map.tres")
	if not is_instance_of(map, CrawlMap):
		print("Failed to load map")
		return
	
	# As resources are cached, it is possible we load in an already cached map.
	# as such, I want to clear it's current focus entity for consistency sake.
	map.clear_focus_entity()
	
	if _active_map != null:
		_RemoveMap()
	
	var elist : Array = map.get_entities({&"type":&"Editor"})
	if elist.size() <= 0:
		print("Failed to find Editor entity.")
		return
	_active_map = map
	_active_map.entity_added.connect(_on_entity_added)
	_active_map.entity_removed.connect(_on_entity_removed)
	_active_map.focus_position_changed.connect(_on_focus_position_changed)
	_active_map.focus_facing_changed.connect(_on_focus_facing_changed)
	
	_SetWorldEnvironment()
	_UpdateMapName()
	
	_map_view.map = _active_map
	_mini_map.map = _active_map

	#_viewer.entity = elist[0]
	_active_cell_editor.map = _active_map
	_active_cell_entities.map = _active_map
	_AddMapEntities()

func _on_entity_pressed() -> void:
	if _entity_selector.visible == true : return
	if _active_map == null: return
	_entity_selector.popup_centered()

func _on_entity_created(entity : CrawlEntity) -> void:
	if _active_map == null: return
	if _active_map.has_entity(entity): return
	
	if entity.type == &"Player":
		var elist : Array = _active_map.get_entities({&"type":&"Player"})
		if elist.size() > 0:
			_active_map.remove_entity(elist[0])
	
	entity.position = _active_map.get_focus_position()
	entity.facing = _active_map.get_focus_facing()
	_active_map.add_entity(entity)

func _on_info_pressed():
	if _map_information.visible: return
	if _active_map == null: return
	_map_information.popup_map_info(_active_map.name, _active_map.author)

func _on_map_information_updated(map_name : String, author : String) -> void:
	if _active_map == null: return
	
	_map_information.visible = false
	
	_active_map.name = map_name
	_active_map.author = author
	
	if map_name.is_empty():
		_label_mapname.text = "Unnamed Map"
	else:
		_label_mapname.text = map_name
	if author.is_empty():
		_label_mapname.tooltip_text = "Unknown Author"
	else:
		_label_mapname.tooltip_text = "Authored By: %s"%[author]

func _on_open_editor_options_pressed() -> void:
	if _editor_options.visible : return
	_editor_options.popup_centered()
