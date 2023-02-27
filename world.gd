extends Node3D


@onready var cmv : Node3D = $CrawlMapView

func _ready() -> void:
	var cm : CrawlMap = CrawlMap.new()
	
	cm.fill_room(Vector3i(-5, 1, -5), Vector3i(10, 1, 10), 0, 0, 0)
	cm.set_focus_cell(Vector3i(0,1,0))
	
	#print(cm._grid)
	
	cmv.map = cm
