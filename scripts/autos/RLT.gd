# (R)esource (L)ookup (T)able
extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const LOOKUP : Dictionary = {
	&"tileA":"res://assets/materials/tileA.tres",
	&"tileB":"res://assets/materials/tileB.tres",
}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_resource(resource : StringName) -> bool:
	return resource in LOOKUP

func load(resource : StringName) -> Material:
	if resource in LOOKUP:
		return ResourceLoader.load(LOOKUP[resource])
	return null

