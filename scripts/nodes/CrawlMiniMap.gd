@tool
extends Control
class_name CrawlMiniMap


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal cell_pressed(cell_position)

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
@export var selection_color : Color = Color.WHITE:				set = set_selection_color
@export var focus_icon : Texture = null:						set = set_focus_icon
@export var ignore_focus : bool = true:							set = set_ignore_focus


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _mouse_entered : bool = false
var _last_mouse_position : Vector2 = Vector2.ZERO

var _area_start : Vector3i = Vector3i.ZERO
var _area_enabled : bool = false

var _selectors_visible : bool = false

var _cursor_sprite : TextureRect = null

var _label : Label = null

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
		_UpdateCursor()
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

func set_selection_color(c : Color) -> void:
	if selection_color != c:
		selection_color = c
		queue_redraw()

func set_focus_icon(ico : Texture) -> void:
	if focus_icon != ico:
		focus_icon = ico
		_UpdateCursor()

func set_ignore_focus(i : bool) -> void:
	if ignore_focus != i:
		ignore_focus = i
		if _mouse_entered == ignore_focus:
			_mouse_entered = false
			queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_cursor_sprite = TextureRect.new()
	_cursor_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_cursor_sprite)
	_UpdateCursor()
	
	_on_selection_blink()

func _draw() -> void:
	var canvas_size : Vector2 = get_size()
	var canvas_region : Rect2 = Rect2(Vector2.ZERO, canvas_size)
	
	# Area region. May not be needed :)
	var area_region : Rect2i = _CalcSelectionRegion(
		Vector2i(_area_start.x, _area_start.z), 
		Vector2i(origin.x, origin.z)
	)
	
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
	
	# The mouse's map position. May not be needed :)
	var mouse_position : Vector2i = Vector2i(_last_mouse_position / cell_size) - cell_range
	
	for cy in range(-(cell_range.y + 1), cell_range.y):
		for cx in range(-(cell_range.x + 1), cell_range.x):
			var map_position : Vector3i = origin + Vector3i(cx, 0, cy)
			var screen_position : Vector2 = Vector2(ox - (cx * cell_size), oy - (cy * cell_size))
			
			# Drawing area selector one cell at a time.
			if _selectors_visible and _area_enabled and area_region.has_point(Vector2i(origin.x, origin.z) + Vector2i(cx, cy)):
				if canvas_region.encloses(Rect2(screen_position, Vector2(cell_size, cell_size))):
					draw_rect(Rect2(screen_position, Vector2(cell_size, cell_size)), selection_color)
				
			# Otherwise draw the cell as normal
			elif map.has_cell(map_position):
				if canvas_region.encloses(Rect2(screen_position, Vector2(cell_size, cell_size))):
					_DrawCell(map_position, screen_position)
			
			# Draw mouse cursor if mouse in the scene...
			if _selectors_visible and _mouse_entered and mouse_position == Vector2i(-cx, -cy):
				draw_rect(Rect2(screen_position, Vector2(cell_size, cell_size)), selection_color, false, 1.0)
	
	#draw_circle(Vector2(ox, oy) + (Vector2(0.5, 0.5) * cell_size), cell_size * 0.5, Color.TOMATO)

func _gui_input(event : InputEvent) -> void:
	if _mouse_entered:
		if is_instance_of(event, InputEventMouseMotion):
			_last_mouse_position = get_local_mouse_position()
			queue_redraw()

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_mouse_entered = not ignore_focus
		NOTIFICATION_MOUSE_EXIT:
			_mouse_entered = false
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
	if map.is_cell_surface_blocking(map_position, CrawlGlobals.SURFACE.North):
		draw_line(
			screen_position,
			screen_position + Vector2(cell_size, 0),
			wall_color, 1.0, true
		)
	if map.is_cell_surface_blocking(map_position, CrawlGlobals.SURFACE.South):
		draw_line(
			screen_position + Vector2(0, cell_size),
			screen_position + Vector2(cell_size, cell_size),
			wall_color, 1.0, true
		)
	if map.is_cell_surface_blocking(map_position, CrawlGlobals.SURFACE.East):
		draw_line(
			screen_position + Vector2(cell_size, 0),
			screen_position + Vector2(cell_size, cell_size),
			wall_color, 1.0, true
		)
	if map.is_cell_surface_blocking(map_position, CrawlGlobals.SURFACE.West):
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

func _UpdateCursor() -> void:
	if _cursor_sprite != null:
		_cursor_sprite.position = (get_size() * 0.5) - (Vector2(0.5, 0.5) * cell_size)
		if _cursor_sprite.texture != focus_icon:
			_cursor_sprite.texture = focus_icon
		if _cursor_sprite.texture != null:
			_cursor_sprite.scale = Vector2(cell_size, cell_size) / _cursor_sprite.texture.get_size()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func start_selection(position : Vector3i) -> void:
	_area_start = position
	_area_enabled = true

func end_selection() -> void:
	_area_enabled = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_selection_blink() -> void:
	_selectors_visible = not _selectors_visible
	var timer : SceneTreeTimer = get_tree().create_timer(SELECTION_BLINK_INTERVAL)
	timer.timeout.connect(_on_selection_blink)
	queue_redraw()
