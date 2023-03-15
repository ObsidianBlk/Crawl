extends Node3D


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
	var cm : CrawlMap = CrawlMap.new()
	cm.add_resource(&"tileA")
	cm.add_resource(&"tileB")
	
	cm.add_cell(Vector3.ZERO)
	
	var editor_entity : CrawlEntity = CrawlEntity.new()
	editor_entity.uuid = UUID.v7()
	editor_entity.type = &"Player"
	editor_entity.position = Vector3i.ZERO
	
	cm.add_entity(editor_entity)
	
	_map_view.map = cm
	_mini_map.map = cm
	
	_viewer.entity = editor_entity

