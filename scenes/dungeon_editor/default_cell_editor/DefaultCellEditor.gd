extends Control

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal resource_changed()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var ceiling_resource : StringName = &"":		set = set_ceiling_resource
@export var ground_resource : StringName = &"":			set = set_ground_resource
@export var north_resource : StringName = &"":			set = set_north_resource
@export var south_resource : StringName = &"":			set = set_south_resource
@export var east_resource : StringName = &"":			set = set_east_resource
@export var west_resource : StringName = &"":			set = set_west_resource

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ceiling_view : Control = %CeilingView
@onready var _ground_view : Control = %GroundView
@onready var _north_view : Control = %NorthView
@onready var _south_view : Control = %SouthView
@onready var _east_view : Control = %EastView
@onready var _west_view : Control = %WestView
@onready var _resource_options : PopupMenu = $ResourceOptions

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_ceiling_resource(r : StringName) -> void:
	if r != ceiling_resource:
		ceiling_resource = r
		_UpdateResourceViews()

func set_ground_resource(r : StringName) -> void:
	if r != ground_resource:
		ground_resource = r
		_UpdateResourceViews()

func set_north_resource(r : StringName) -> void:
	if r != north_resource:
		north_resource = r
		_UpdateResourceViews()

func set_south_resource(r : StringName) -> void:
	if r != south_resource:
		south_resource = r
		_UpdateResourceViews()

func set_east_resource(r : StringName) -> void:
	if r != east_resource:
		east_resource = r
		_UpdateResourceViews()

func set_west_resource(r : StringName) -> void:
	if r != west_resource:
		west_resource = r
		_UpdateResourceViews()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ceiling_view.pressed.connect(_on_surface_pressed.bind(&"ceiling", CrawlGlobals.SURFACE.Ceiling))
	_ground_view.pressed.connect(_on_surface_pressed.bind(&"ground", CrawlGlobals.SURFACE.Ground))
	_north_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.North))
	_south_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.South))
	_east_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.East))
	_west_view.pressed.connect(_on_surface_pressed.bind(&"wall", CrawlGlobals.SURFACE.West))
	
	_resource_options.index_pressed.connect(_on_resource_item_index_selected)
	_UpdateResourceViews()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateResourceViews() -> void:
	var set_res : Callable = func(view : Control, type : StringName, res : StringName):
		if not RLT.has_resource(type, res): return
		if view == null: return
		if not view.is_resource(type, res):
			view.set_resource(type, res)
			resource_changed.emit()
	
	set_res.call(_ceiling_view, &"ceiling", ceiling_resource)
	set_res.call(_ground_view, &"ground", ground_resource)
	
	set_res.call(_north_view, &"wall", north_resource)
	set_res.call(_south_view, &"wall", south_resource)
	set_res.call(_east_view, &"wall", east_resource)
	set_res.call(_west_view, &"wall", west_resource)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_surface_pressed(section_name : StringName, surface : CrawlGlobals.SURFACE) -> void:
	if not RLT.has_section(section_name): return
	_resource_options.clear()
#	_resource_options.add_item("Empty")
#	_resource_options.set_item_metadata(0, {
#		&"section":&"",
#		&"resource_name":&"",
#		&"surface":surface
#	})
	for item in RLT.get_resource_list(section_name):
		var idx : int = _resource_options.item_count
		_resource_options.add_item(item[&"description"])
		_resource_options.set_item_metadata(idx, {
			&"section":section_name,
			&"resource_name":item[&"name"],
			&"surface":surface
		})
	_resource_options.popup_centered()

func _on_resource_item_index_selected(idx : int) -> void:
	var meta = _resource_options.get_item_metadata(idx)
	if meta == null: return
	if typeof(meta) != TYPE_DICTIONARY: return
	match meta[&"surface"]:
		CrawlGlobals.SURFACE.Ceiling:
			ceiling_resource = meta[&"resource_name"]
		CrawlGlobals.SURFACE.Ground:
			ground_resource = meta[&"resource_name"]
		CrawlGlobals.SURFACE.North:
			north_resource = meta[&"resource_name"]
		CrawlGlobals.SURFACE.South:
			south_resource = meta[&"resource_name"]
		CrawlGlobals.SURFACE.East:
			east_resource = meta[&"resource_name"]
		CrawlGlobals.SURFACE.West:
			west_resource = meta[&"resource_name"]

