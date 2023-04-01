extends Node3D


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active_map : CrawlMap = null
var _active_map_path : String = ""
var _entity_nodes : Dictionary = {}


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _map_view : Node3D = %CrawlMapView
@onready var _mini_map : CrawlMiniMap = %CrawlMiniMap
@onready var _entity_container : Node3D = %EntityContainer
@onready var _world_environment : WorldEnvironment = %WorldEnvironment

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	CrawlGlobals.Set_Editor_Mode(false)
	CrawlGlobals.crawl_config_value_changed.connect(_on_config_value_changed)
	CrawlGlobals.crawl_config_loaded.connect(_on_config_loaded)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ClearEntities() -> void:
	if _entity_container == null: return
	for child in _entity_container.get_children():
		_entity_container.remove_child(child)
		child.queue_free()

func _RemoveMap() -> void:
	if _active_map == null: return
	_ClearEntities()
	if _active_map.entity_added.is_connected(_on_entity_added):
		_active_map.entity_added.disconnect(_on_entity_added)
	if _active_map.entity_removed.is_connected(_on_entity_removed):
		_active_map.entity_removed.disconnect(_on_entity_removed)
	_active_map = null
	_active_map_path = ""

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

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear_dungeon() -> void:
	if _active_map == null: return
	_RemoveMap()
	_map_view.map = null
	_mini_map.map = null

func load_dungeon(path : String) -> int:
	var map = ResourceLoader.load(path)
	if not is_instance_of(map, CrawlMap):
		printerr("DUNGEON ERROR: Failed to obtain map from path ", path)
		return ERR_CANT_ACQUIRE_RESOURCE
	
	# As resources are cached, it is possible we load in an already cached map.
	# as such, I want to clear it's current focus entity for consistency sake.
	map.clear_focus_entity()
	
	if _active_map != null:
		_RemoveMap()
	
	_active_map_path = path
	_active_map = map
	_active_map.entity_added.connect(_on_entity_added)
	_active_map.entity_removed.connect(_on_entity_removed)
	
	_SetWorldEnvironment()
	
	_map_view.map = _active_map
	_mini_map.map = _active_map
	
	_AddMapEntities()
	
	return OK

func create_default() -> void:
	if _active_map != null:
		_RemoveMap()
	
	_active_map = CrawlMap.new()
	_active_map.entity_added.connect(_on_entity_added)
	_active_map.entity_removed.connect(_on_entity_removed)
	
	_active_map.set_default_surface_resource(CrawlGlobals.SURFACE.Ground, &"tileB")
	_active_map.set_default_surface_resource(CrawlGlobals.SURFACE.Ceiling, &"tileB")
	_active_map.set_default_surface_resource(CrawlGlobals.SURFACE.North, &"tileA")
	_active_map.set_default_surface_resource(CrawlGlobals.SURFACE.South, &"tileA")
	_active_map.set_default_surface_resource(CrawlGlobals.SURFACE.East, &"tileA")
	_active_map.set_default_surface_resource(CrawlGlobals.SURFACE.West, &"tileA")
	
	_active_map.add_cell(Vector3i.ZERO)
	
	_SetWorldEnvironment()
	
	var player_entity : CrawlEntity = CrawlEntity.new()
	player_entity.uuid = UUID.v7()
	player_entity.type = &"Player"
	player_entity.position = Vector3i(0,0,0)

	_active_map.add_entity(player_entity)
	_active_map.set_entity_as_focus(player_entity)
	
	_map_view.map = _active_map
	_mini_map.map = _active_map


func get_active_map_path() -> String:
	return _active_map_path


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
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

func _on_entity_added(entity : CrawlEntity) -> void:
	if _entity_container == null: return
	if entity.uuid in _entity_nodes: return
	if entity.type == &"Editor":
		var remove_editor : Callable = func(): _active_map.remove_entity(entity)
		remove_editor.call_deferred()
		return
	
	if entity.type == &"Player":
		_active_map.set_entity_as_focus(entity)
	
	var node = RLT.instantiate_resource(&"entity", entity.type)
	if node == null: return
	
	node.entity = entity
	_entity_nodes[entity.uuid] = node
	_entity_container.add_child(node)


func _on_entity_removed(entity : CrawlEntity) -> void:
	if not entity.uuid in _entity_nodes: return
	
	var node : Node3D = _entity_nodes[entity.uuid]
	_entity_nodes.erase(entity.uuid)
	
	if _entity_container == null: return
	
	_entity_container.remove_child(node)
	node.queue_free()

