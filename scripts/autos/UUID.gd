@tool
extends Node


const LOW_BYTE : int = 0xFF

func _rng() -> int:
	randomize()
	return randi() & LOW_BYTE

func _get_int_part(v : float) -> int:
	var DECIMAL_PLACES : int = 9 
	return int(v / 10 ** DECIMAL_PLACES)

func _get_remainder_part(v : float) -> float:
	var DECIMAL_PLACES : int = 9 
	var divisor : float = 10 ** DECIMAL_PLACES
	return snappedf(fmod(v, divisor) / divisor, 1/divisor)

# ----------------------
# UUID v4

func bin4() -> PackedByteArray:
	return PackedByteArray([
		_rng(), _rng(), _rng(), _rng(),
		_rng(), _rng(),
		(_rng() & 0x0F) | 0x4F, _rng(),
		_rng(), _rng(),
		_rng(), _rng(), _rng(), _rng(), _rng(), _rng()
	])

func v4() -> StringName:
	var bin : PackedByteArray = bin4()
	return StringName("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x"%[
		bin[0], bin[1], bin[2], bin[3],
		bin[4], bin[5],
		bin[6], bin[7],
		bin[8], bin[9],
		bin[10], bin[11], bin[12], bin[13], bin[14], bin[15]
	])


# ----------------------
# UUID v7

# v7 Calculations adapted from...
# https://gist.github.com/fabiolimace/6db9747f83b02e62db55afed8461ee5b
#
# Additional Reading...
# https://blog.devgenius.io/analyzing-new-unique-identifier-formats-uuidv6-uuidv7-and-uuidv8-d6cc5cd7391a

func bin7(ts = null):
	if typeof(ts) != TYPE_FLOAT:
		ts = Time.get_unix_time_from_system()
	var i : int = _get_int_part(ts)
	var f : float = _get_remainder_part(ts)
	# TODO: Finish me!
	pass

func v7(ts = null) -> StringName:
	return &""
