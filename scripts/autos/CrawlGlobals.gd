extends Node

enum ATTACK_TYPE {Physical=0, Fire=100, Water=101, Earth=102, Air=103}

enum SURFACE {North=0x01, East=0x02, South=0x04, West=0x08, Ground=0x10, Ceiling=0x20}

func Get_Surface_Index(surface : SURFACE) -> int:
	return SURFACE.values().find(surface)

func Get_Adjacent_Surface(surface : SURFACE) -> SURFACE:
	match surface:
		SURFACE.North:
			return SURFACE.South
		SURFACE.East:
			return SURFACE.West
		SURFACE.South:
			return SURFACE.North
		SURFACE.West:
			return SURFACE.East
		SURFACE.Ground:
			return SURFACE.Ceiling
		SURFACE.Ceiling:
			return SURFACE.Ground
	return surface

func Get_Direction_From_Surface(surface : SURFACE) -> Vector3i:
	match surface:
		SURFACE.North:
			return Vector3i(0,0,1)
		SURFACE.East:
			return Vector3i(-1,0,0)
		SURFACE.South:
			return Vector3i(0,0,-1)
		SURFACE.West:
			return Vector3i(1,0,0)
		SURFACE.Ground:
			return Vector3i(0,-1,0)
		SURFACE.Ceiling:
			return Vector3i(0,1,0)
	return Vector3i.ZERO

func Get_Surface_From_Direction(dir : Vector3) -> SURFACE:
	dir = dir.normalized()
	var deg45 : float = deg_to_rad(45.0)
	if dir.angle_to(Vector3(0,0,1)) < deg45:
		return SURFACE.North
	if dir.angle_to(Vector3(-1,0,0)) < deg45:
		return SURFACE.East
	if dir.angle_to(Vector3(0,0,-1)) < deg45:
		return SURFACE.South
	if dir.angle_to(Vector3(1,0,0)) < deg45:
		return SURFACE.West
	if dir.angle_to(Vector3(0,1,0)) < deg45:
		return SURFACE.Ceiling
	return SURFACE.Ground

func Get_Surface_90Deg(surface : SURFACE, amount : int) -> SURFACE:
	if surface & 0x0F == 0: return surface # Only North, South, East, and West will work
	
	var dir : Vector3 = Vector3(Get_Direction_From_Surface(surface))
	dir = dir.rotated(Vector3.UP, deg_to_rad(90.0 * float(amount)))
	return Get_Surface_From_Direction(dir)

func Get_Angle_From_Surface_To_Surface(from : SURFACE, to : SURFACE) -> float:
	if from == to: return 0.0
	var deg90 : float = deg_to_rad(90)
	match from:
		SURFACE.North:
			match to:
				SURFACE.East, SURFACE.West:
					return deg90 if to == SURFACE.West else -deg90
				SURFACE.South:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.East:
			match to:
				SURFACE.South, SURFACE.North:
					return deg90 if to == SURFACE.North else -deg90
				SURFACE.West:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.South:
			match to:
				SURFACE.East, SURFACE.West:
					return deg90 if to == SURFACE.East else -deg90
				SURFACE.North:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.West:
			match to:
				SURFACE.South, SURFACE.North:
					return deg90 if to == SURFACE.South else -deg90
				SURFACE.East:
					return deg90 * 2
				SURFACE.Ground, SURFACE.Ceiling:
					return deg90 if to == SURFACE.Ceiling else -deg90
		SURFACE.Ground:
			return deg90 * 2 if to == SURFACE.Ceiling else deg90
		SURFACE.Ceiling:
			return deg90 * 2 if to == SURFACE.Ground else deg90
	return 0.0
