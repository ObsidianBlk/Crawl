extends Node3D


@onready var cmv : Node3D = $CrawlMapView
@onready var player : Node3D = $Player

func _ready() -> void:
	var cm : CrawlMap = CrawlMap.new()
	
	cm.fill_room(Vector3i(-3, 1, -3), Vector3i(6, 1, 6), 0, 0, 0)
	cm.set_focus_cell(Vector3i(0,1,0))
	
	#print(cm._grid)
	
	cmv.map = cm
	player.map = cm
