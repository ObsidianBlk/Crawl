extends Window


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var entity : CrawlEntity = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _ctrl : Control = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _line_edit_type : LineEdit = %LineEdit_Type
@onready var _line_edit_name : LineEdit = %LineEdit_Name
@onready var _layout : Control = %Layout
@onready var _seperator : HSeparator = $Body/Layout/Seperator


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_entity(e : CrawlEntity) -> void:
	if e != entity:
		entity = e
		_UpdateControls()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_UpdateAttachedControl(true)
	_UpdateControls()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateControls() -> void:
	if _line_edit_name == null or _line_edit_type == null: return
	
	if entity == null:
		_line_edit_name.text = ""
		_line_edit_type.editable = true
		_line_edit_type.text = ""
		_line_edit_type.editable = false
	else:
		_line_edit_name.text = entity.entity_name
		_line_edit_type.editable = true
		_line_edit_type.text = String(entity.type)
		_line_edit_type.editable = false
	
	if _ctrl != null:
		if _ctrl.entity != entity:
			_ctrl.entity = entity

func _UpdateAttachedControl(attach : bool) -> void:
	if _ctrl == null or _layout == null: return
	if attach:
		_seperator.visible = true
		_layout.add_child(_ctrl)
	else:
		_seperator.visible = false
		_layout.remove_child(_ctrl)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_attached_control() -> bool:
	return _ctrl != null

func attach_control(ctrl : Control) -> void:
	if ctrl == null: return
	
	_ctrl = ctrl
	if entity != null:
		_ctrl.entity = entity
	_UpdateAttachedControl(true)

func clear_attached_control() -> void:
	if _ctrl == null: return
	_UpdateAttachedControl(false)
	_ctrl.queue_free()
	_ctrl = null

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_visibility_changed() -> void:
	if _layout == null: return
	if visible == false:
		entity = null
		clear_attached_control()
	else:
		_UpdateControls()

func _on_line_edit_name_text_submitted(new_text : String) -> void:
	if entity == null: return
	entity.entity_name = new_text
