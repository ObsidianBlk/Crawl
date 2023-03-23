extends Node3D
class_name CrawlEntityNode3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_changing()
signal entity_changed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEG90 : float = 1.570796
const CLOCKWISE : int = -1
const COUNTERCLOCKWISE : int = 1

const CELL_SIZE : float = 5.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Crawl Entity Node 3D")
@export_range(0, 10, 1) var movement_queue_size : int = 0
@export var entity : CrawlEntity = null:						set = set_entity
@export var body_node_path : NodePath = "":						set = set_body_node_path


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _body_node : Node3D = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_entity(ent : CrawlEntity) -> void:
	if ent != entity:
		entity_changing.emit()
		entity = ent
		if entity != null:
			position = Vector3(entity.position) * CELL_SIZE
		entity_changed.emit()

func set_body_node_path(bnp : NodePath) -> void:
	if bnp != body_node_path:
		body_node_path = bnp
		_body_node = null

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetBodyNode() -> Node3D:
	if _body_node == null:
		var bnode = get_node_or_null(body_node_path)
		if not is_instance_of(bnode, Node3D) : return null
		_body_node = bnode
	return _body_node

func _SurfaceToAngle(surface : CrawlGlobals.SURFACE) -> float:
	match surface:
		CrawlGlobals.SURFACE.North:
			return 0
		CrawlGlobals.SURFACE.South:
			return DEG90 * 2
		CrawlGlobals.SURFACE.East:
			return -DEG90
		CrawlGlobals.SURFACE.West:
			return DEG90
	return 0.0

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func face(surface : CrawlGlobals.SURFACE) -> void:
	var body : Node3D = _GetBodyNode()
	if body == null: return
	body.rotation.y = _SurfaceToAngle(surface)
	
func turn(dir : int) -> void:
	if entity == null: return
	match dir:
		CLOCKWISE:
			entity.turn_right()
		COUNTERCLOCKWISE:
			entity.turn_left()

