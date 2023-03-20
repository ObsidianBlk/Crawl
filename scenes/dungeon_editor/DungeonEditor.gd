extends Node3D


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active_map : CrawlMap = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _map_view : Node3D = %CrawlMapView
@onready var _mini_map : CrawlMiniMap = %CrawlMiniMap
@onready var _viewer : Node3D = $Viewer

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

	_viewer.dig.connect(_on_dig)
	_viewer.fill.connect(_on_fill)
	
	_mini_map.selection_finished.connect(_on_selection_finished)
	_active_cell_editor.focus_type = &"Editor"


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

func _on_new_map_pressed():
	_active_map = CrawlMap.new()
	_on_resource_changed()
	_active_map.add_cell(Vector3.ZERO)
	
	var editor_entity : CrawlEntity = CrawlEntity.new()
	editor_entity.uuid = UUID.v7()
	editor_entity.type = &"Editor"
	editor_entity.position = Vector3i.ZERO
	
	_active_map.add_entity(editor_entity)
	
	_map_view.map = _active_map
	_mini_map.map = _active_map
	
	_viewer.entity = editor_entity
	_active_cell_editor.map = _active_map


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
	var elist : Array = map.get_entities({&"type":&"Editor"})
	if elist.size() <= 0:
		print("Failed to find Editor entity.")
		return
	_active_map = map
	
	_map_view.map = _active_map
	_mini_map.map = _active_map
	
	_viewer.entity = elist[0]
	_active_cell_editor.map = _active_map
	
