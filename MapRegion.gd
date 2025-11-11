extends Area2D

class_name MapRegion

signal region_selected

var shape: PackedVector2Array:
	set = set_shape
var color: Color:
	get:
		return _color
	set(value):
		_color = value
		_color.a = 0.6 # always set to 0.6, it allows for highlighting
		_poly.color = _color

@onready var _poly := $Polygon2D
@onready var _coll := $CollisionPolygon2D
@onready var _highlight_poly := $HighlightPolygon

var _color := Color(randf() / 2.0, randf() / 2.0, 1.0, 0.6)


func set_shape(new_shape: PackedVector2Array):
	_poly.set_polygon(new_shape)
	_poly.color = _color

	_highlight_poly.set_polygon(new_shape)
	_highlight_poly.visible = false

	_coll.set_polygon(new_shape)
	shape = new_shape


func set_highlight(state: bool, color: Color = Color.RED) -> void:
	if state:
		_highlight_poly.modulate = color
		_highlight_poly.visible = true
	else:
		_highlight_poly.visible = false


func _on_MapRegion_mouse_entered():
	_poly.color.a = 1


func _on_MapRegion_mouse_exited():
	# restore color back
	_poly.color.a = _color.a


func _on_MapRegion_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		region_selected.emit()
