extends Node3D


@onready var cmv : Node3D = $CrawlMapView
@onready var cmm : CrawlMiniMap = $CanvasLayer/CrawlMiniMap
@onready var player : Node3D = $Player

func _ready() -> void:
	var cm : CrawlMap = CrawlMap.new()
	
	cm.fill_room(Vector3i(-3, 1, -3), Vector3i(6, 1, 6), 0, 0, 0)
	cm.fill_room(Vector3i(4, 1, -3), Vector3i(1, 1, 6), 0, 0, 0)
	cm.set_focus_cell(Vector3i(0,1,0))
	
	#print(cm.get_used_cells())
	#print(cm._grid)
	
	cmv.map = cm
	cmm.map = cm
	cmm.origin = Vector3i(0,1,0)
	player.map = cm
	
	#cmm.start_selection(Vector3i(-3,1,-3))
