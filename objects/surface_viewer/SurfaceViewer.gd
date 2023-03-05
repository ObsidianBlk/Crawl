extends SubViewportContainer


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var resource_name : StringName = &"":		set = set_resource_name


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _surface : MeshInstance3D = $SubViewport/Surface

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_resource_name(rn : StringName) -> void:
	if rn != resource_name:
		resource_name = rn
		_UpdateSurface()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateSurface()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateSurface() -> void:
	if _surface == null: return
	
	if resource_name == &"":
		_surface.mesh.material = null
	else:
		var mat : Material = RLT.load(resource_name)
		if mat == null: return
		_surface.mesh.material = mat

