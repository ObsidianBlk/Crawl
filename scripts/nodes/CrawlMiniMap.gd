@tool
extends Control
class_name CrawlMiniMap


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SELECTION_BLINK_INTERVAL : float = 0.08

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var map : CrawlMap = null:								set = set_map
@export var origin : Vector3i = Vector3i.ZERO:					set = set_origin
@export var cell_size : float = 16.0:							set = set_cell_size
@export var background_color : Color = Color.DARK_GOLDENROD:	set = set_background_color
@export var background_texture : Texture = null:				set = set_background_texture
@export var wall_color : Color = Color.DARK_OLIVE_GREEN:		set = set_wall_color
@export var cell_color : Color = Color.DARK_SALMON:				set = set_cell_color
@export var selection_color : Color = Color.WHITE


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _sel_start : Vector3i = Vector3i.ZERO
var _sel_enabled : bool = false
var _sel_visible : bool = false

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_map(m : CrawlMap) -> void:
	if m != map:
		# TODO: Possible signal disconnections
		map = m
		# TODO: Possible signal connections
		queue_redraw()

func set_origin(o : Vector3i) -> void:
	if origin != o:
		origin = o
		queue_redraw()

func set_cell_size(s : float) -> void:
	if s > 0 and s != cell_size:
		cell_size = s
		queue_redraw()

func set_background_color(c : Color) -> void:
	if background_color != c:
		background_color = c
		queue_redraw()

func set_background_texture(t : Texture) -> void:
	if background_texture != t:
		background_texture = t
		queue_redraw()

func set_wall_color(c : Color) -> void:
	if wall_color != c:
		wall_color = c
		queue_redraw()

func set_cell_color(c : Color) -> void:
	if cell_color != c:
		cell_color = c
		queue_redraw()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var canvas_size : Vector2 = get_size()
	var canvas_region : Rect2 = Rect2(Vector2.ZERO, canvas_size)
	
	var selection_region : Rect2i = _CalcSelectionRegion(
		Vector2i(_sel_start.x, _sel_start.z), 
		Vector2i(origin.x, origin.z)
	)
	print("Sel Region: ", selection_region)
	
	if background_texture != null:
		draw_texture_rect(background_texture, Rect2(Vector2.ZERO, canvas_size), true)
	else:
		draw_rect(Rect2(Vector2.ZERO, canvas_size), background_color)
	
	var cell_count : Vector2 = Vector2(
		floor(canvas_size.x / cell_size),
		floor(canvas_size.y / cell_size)
	)
	if map == null or cell_count.x <= 0 or cell_count.y <= 0:
		return # Well... there's nothing more to draw! Go figure! :)
	
	if int(cell_count.x) % 2 == 0: # We don't want an even count of cells.
		cell_count.x += 1
	if int(cell_count.y) % 2 == 0:
		cell_count.y += 1
	
	var ox = (canvas_size.x * 0.5) - (cell_size * 0.5)
	var oy = (canvas_size.y * 0.5) - (cell_size * 0.5)
	
	var cell_range : Vector2i = Vector2i(floor(cell_count.x * 0.5), floor(cell_count.y * 0.5))
	
	for cy in range(-(cell_range.y + 1), cell_range.y):
		for cx in range(-(cell_range.x + 1), cell_range.x):
			var screen_position : Vector2 = Vector2(ox - (cx * cell_size), oy - (cy * cell_size))
			if _sel_enabled and _sel_visible and selection_region.has_point(Vector2i(cx, cy)):
				draw_rect(Rect2(screen_position, Vector2(cell_size, cell_size)), selection_color)
				continue
			
			var map_position : Vector3i = origin + Vector3i(cx, 0, cy)
			if map.has_cell(map_position):
				#var screen_position : Vector2 = Vector2(ox - (cx * cell_size), oy - (cy * cell_size))
				if canvas_region.encloses(Rect2(screen_position, Vector2(cell_size, cell_size))):
					_DrawCell(map_position, screen_position)
	
	# Drawing Selection, if it's enabled and visible...
	if _sel_enabled && _sel_visible:
		pass
	
	draw_circle(Vector2(ox, oy) + (Vector2(0.5, 0.5) * cell_size), cell_size * 0.5, Color.TOMATO)
	

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			pass
		NOTIFICATION_MOUSE_EXIT:
			pass
		NOTIFICATION_FOCUS_ENTER:
			pass
		NOTIFICATION_FOCUS_EXIT:
			pass
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				queue_redraw()
		NOTIFICATION_RESIZED:
			queue_redraw()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DrawCell(map_position : Vector3i, screen_position : Vector2) -> void:
	draw_rect(Rect2(screen_position, Vector2(cell_size * 0.9, cell_size * 0.9)), cell_color)
	if map.is_cell_surface_blocking(map_position, CrawlMap.SURFACE.North):
		draw_line(
			screen_position,
			screen_position + Vector2(cell_size, 0),
			wall_color, 1.0, true
		)
	if map.is_cell_surface_blocking(map_position, CrawlMap.SURFACE.South):
		draw_line(
			screen_position + Vector2(0, cell_size),
			screen_position + Vector2(cell_size, cell_size),
			wall_color, 1.0, true
		)
	if map.is_cell_surface_blocking(map_position, CrawlMap.SURFACE.East):
		draw_line(
			screen_position + Vector2(cell_size, 0),
			screen_position + Vector2(cell_size, cell_size),
			wall_color, 1.0, true
		)
	if map.is_cell_surface_blocking(map_position, CrawlMap.SURFACE.West):
		draw_line(
			screen_position,
			screen_position + Vector2(0, cell_size),
			wall_color, 1.0, true
		)

func _CalcSelectionRegion(from : Vector2i, to : Vector2i) -> Rect2i:
	var fx : int = min(from.x, to.x)
	var tx : int= max(from.x, to.x)
	var fy : int = min(from.y, to.y)
	var ty : int = max(from.y, to.y)
	var sx : int = tx - fx
	var sy : int = ty - fy
	return Rect2i(fx, fy, sx, sy)


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func start_selection(position : Vector3i) -> void:
	_sel_start = position
	_sel_enabled = true
	_on_selection_blink()

func end_selection() -> void:
	_sel_enabled = false
	_sel_visible = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_selection_blink() -> void:
	if _sel_enabled:
		_sel_visible = not _sel_visible
		var timer : SceneTreeTimer = get_tree().create_timer(SELECTION_BLINK_INTERVAL)
		timer.timeout.connect(_on_selection_blink)
	queue_redraw()
