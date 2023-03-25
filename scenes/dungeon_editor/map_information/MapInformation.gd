extends Window


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal map_information_updated(map_name, author)


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _on_ready_func : Callable = func(): pass

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ledit_map_name : LineEdit = %LEdit_MapName
@onready var _ledit_author : LineEdit = %LEdit_Author

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_on_ready_func.call()
	_on_ready_func = func(): pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Popup(map_name : String, author : String) -> void:
	if _ledit_author == null or _ledit_map_name == null: return
	_ledit_map_name.text = map_name
	_ledit_author.text = author
	popup_centered()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func popup_map_info(map_name : String, author : String) -> void:
	if _ledit_author == null or _ledit_map_name == null:
		_on_ready_func = _Popup.bind(map_name, author)
		return
	_Popup(map_name, author)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_btn_update_pressed():
	if _ledit_author == null or _ledit_map_name == null: return
	map_information_updated.emit(_ledit_map_name.text, _ledit_author.text)
