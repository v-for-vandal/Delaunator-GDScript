extends Area2D
class_name MapRegion

signal region_selected

var shape : PackedVector2Array: set = set_shape

@onready var _poly := $Polygon2D
@onready var _coll := $CollisionPolygon2D
var _color = Color(randf() / 2.0, randf() / 2.0, 1.0, 0.6)

func set_shape(new_shape: PackedVector2Array):
	_poly.set_polygon(new_shape)
	_poly.color = _color
	_coll.set_polygon(new_shape)
	shape = new_shape
	
func set_highlight(state: bool) -> void:
	if state:
		_poly.color = Color.RED
	else:
		_poly.modulate = _color
	

func _on_MapRegion_mouse_entered():
	_poly.color.a = 1

func _on_MapRegion_mouse_exited():
	_poly.color.a = 0.6

func _on_MapRegion_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		region_selected.emit()
