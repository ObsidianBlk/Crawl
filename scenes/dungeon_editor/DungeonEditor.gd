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

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_active_map = CrawlMap.new()
	_active_map.add_resource(&"tileA")
	_active_map.add_resource(&"tileB")
	
	_active_map.add_cell(Vector3.ZERO)
	
	var editor_entity : CrawlEntity = CrawlEntity.new()
	editor_entity.uuid = UUID.v7()
	editor_entity.type = &"Player"
	editor_entity.position = Vector3i.ZERO
	
	_active_map.add_entity(editor_entity)
	
	_map_view.map = _active_map
	_mini_map.map = _active_map
	
	_viewer.entity = editor_entity
	
	_mini_map.selection_finished.connect(_on_selection_finished)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_selection_finished(sel_position : Vector3i, sel_size : Vector3i) -> void:
	if _active_map == null: return
	_active_map.dig_room(sel_position, sel_size, 0,0,0)


