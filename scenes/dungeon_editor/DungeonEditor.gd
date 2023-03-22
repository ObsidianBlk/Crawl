extends Node3D


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
@onready var _map_view : Node3D = %CrawlMapView
@onready var _mini_map : CrawlMiniMap = %CrawlMiniMap
@onready var _entity_container : Node3D = $"EntityContainer"
#@onready var _viewer : Node3D = $Viewer

@onready var _default_cell_editor : Control = %DefaultCellEditor
@onready var _active_cell_editor : Control = %ActiveCellEditor

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
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

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearEntities() -> void:
	if _entity_container == null: return
	for child in _entity_container.get_children():
		_entity_container.remove_child(child)
		child.queue_free()
	_viewer = null

func _RemoveMap() -> void:
	if _active_map == null: return
	_ClearEntities()
	if _active_map.entity_added.is_connected(_on_entity_added):
		_active_map.entity_added.disconnect(_on_entity_added)
	if _active_map.entity_removed.is_connected(_on_entity_removed):
		_active_map.entity_removed.connect(_on_entity_removed)
	_active_map = null

func _AddMapEntities() -> void:
	if _active_map == null: return
	var elist : Array = _active_map.get_entities({})
	for entity in elist:
		_on_entity_added(entity)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
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

func _on_new_map_pressed():
	_RemoveMap()
	
	_active_map = CrawlMap.new()
	_active_map.entity_added.connect(_on_entity_added)
	_active_map.entity_removed.connect(_on_entity_removed)
	_on_resource_changed()
	_active_map.add_cell(Vector3.ZERO)
	
	_map_view.map = _active_map
	_mini_map.map = _active_map
	
	#_viewer.entity = RLT.instantiate_resource(&"entity", editor_entity.type)#editor_entity
	_active_cell_editor.map = _active_map
	
	var editor_entity : CrawlEntity = CrawlEntity.new()
	editor_entity.uuid = UUID.v7()
	editor_entity.type = &"Editor"
	editor_entity.position = Vector3i.ZERO
	
	_active_map.add_entity(editor_entity)
	_active_map.set_entity_as_focus(editor_entity)


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
	
	if _active_map != null:
		_RemoveMap()
	
	var elist : Array = map.get_entities({&"type":&"Editor"})
	if elist.size() <= 0:
		print("Failed to find Editor entity.")
		return
	_active_map = map
	_active_map.entity_added.connect(_on_entity_added)
	_active_map.entity_removed.connect(_on_entity_removed)
	
	_map_view.map = _active_map
	_mini_map.map = _active_map

	#_viewer.entity = elist[0]
	_active_cell_editor.map = _active_map
	_AddMapEntities()

func _on_entity_pressed() -> void:
	if _entity_selector.visible == true : return
	if _active_map == null: return
	_entity_selector.popup_centered()

func _on_entity_created(entity : CrawlEntity) -> void:
	if _active_map == null: return
	if _active_map.has_entity(entity): return
	
	entity.position = _active_map.get_focus_position()
	_active_map.add_entity(entity)
