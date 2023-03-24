extends Node3D


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _dungeon : Node3D = $Dungeon

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Settings.config_reset_requested.connect(_on_config_reset_requested)
	
	if Settings.load_config() != OK:
		Settings.reset()
		Settings.save_config()
	
	_dungeon.load_dungeon("user://map.tres")
#	var cm : CrawlMap = CrawlMap.new()
#	var player_entity : CrawlEntity = CrawlEntity.new()
#	player_entity.uuid = UUID.v7()
#	player_entity.type = &"Player"
#	player_entity.position = Vector3i(0,1,0)
#
#	cm.add_entity(player_entity)
#	cm.set_entity_as_focus(player_entity)
#
#	cm.set_default_surface_resource(CrawlGlobals.SURFACE.Ground, &"tileB")
#	cm.set_default_surface_resource(CrawlGlobals.SURFACE.Ceiling, &"tileB")
#	cm.set_default_surface_resource(CrawlGlobals.SURFACE.North, &"tileA")
#	cm.set_default_surface_resource(CrawlGlobals.SURFACE.South, &"tileA")
#	cm.set_default_surface_resource(CrawlGlobals.SURFACE.East, &"tileA")
#	cm.set_default_surface_resource(CrawlGlobals.SURFACE.West, &"tileA")
#
#	#cm.dig_room(Vector3i(0,1,0), Vector3i(1,1,1), 1,1,0)
#	cm.dig_room(Vector3i(-3, 1, -3), Vector3i(6, 1, 6))
#	cm.dig_room(Vector3i(4, 1, -3), Vector3i(1, 1, 6))
#	#cm.set_focus_cell(Vector3i(0,1,0))
#
#
#	cmv.map = cm
#	cmm.map = cm
#	#cmm.origin = Vector3i(0,1,0)
#	player.entity = player_entity


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_config_reset_requested() -> void:
	Settings.set_value("Graphics", "SSAO", true)
	Settings.set_value("Graphics", "SSIL", true)
	Settings.set_value("Graphics", "Fog", true)
	Settings.set_value("Graphics", "VFog", true)
