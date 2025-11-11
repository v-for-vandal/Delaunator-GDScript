extends Node2D

const Delaunator := preload("res://addons/Delaunator-GDScript/Delaunator.gd")
const MapRegionScene := preload("res://addons/Delaunator-GDScript/MapRegion.tscn")
const Voronoinator := preload("res://addons/Delaunator-GDScript/Voronoinator.gd")

var _voronoi: Voronoinator
var _cells: Array[PackedVector2Array]

var _cell_to_node: Dictionary[int, MapRegion] = { }
var _highlighted: Array[int]
var _highlight_target: int = -1

var _colorings: Dictionary[StringName, PackedColorArray]

@export var highlight_color: = Color.RED
@export var highlight_neighbour_color := Color(0.5, 0.1, 0.3)


func _ready() -> void:
	# User can call set_voronoi before node is ready, in this case it will
	# not construct shapes
	if _voronoi != null:
		_construct()


func set_voronoi(voronoi: Voronoinator):
	clear()

	_voronoi = voronoi
	_cells = voronoi.voronoi_cells

	if is_node_ready():
		# construction only works if node is ready. If node is not ready,
		# construct() will be called first time in _ready()
		_construct()


func add_coloring(key: StringName, colors: PackedColorArray) -> void:
	assert(colors.size() == _cells.size())
	_colorings[key] = colors


## Creates coloring scheme where color of every polygon is random
## You can set some components of color to fixed values by providing them explicitly
func add_random_coloring(key: StringName, color_mask: Vector3 = Vector3(-1.0, -1.0, -1.0)) -> void:
	var colors := PackedColorArray()
	colors.resize(_cells.size())
	for i in range(_cells.size()):
		var c := Color(randf(), randf(), randf())
		for j in range(3):
			if color_mask[j] > 0:
				c[j] = color_mask[j]
		colors[i] = c

	_colorings[key] = colors


func select_coloring(key: StringName) -> void:
	if key not in _colorings:
		push_error("Coloring %s is not found" % key)
		return

	for i in range(_cells.size()):
		_cell_to_node[i].color = _colorings[key][i]


func clear():
	for child in get_children():
		if child is MapRegion:
			child.queue_free()
	_cells = []
	_voronoi = null
	_cell_to_node.clear()
	_highlighted.clear()
	_colorings.clear()


func _construct():
	for i in range(_cells.size()):
		var map_region: MapRegion = MapRegionScene.instantiate()
		_cell_to_node[i] = map_region
		add_child(map_region)
		map_region.shape = _cells[i]
		map_region.region_selected.connect(_on_MapRegion_selected.bind(i))


func _on_MapRegion_selected(id: int):
	if id == _highlight_target:
		_clear_highlight()
		_highlight_target = -1
	else:
		_clear_highlight()
		_highlight(id)


func _clear_highlight() -> void:
	# Clear previous highlight
	for idx in _highlighted:
		_cell_to_node[idx].set_highlight(false)

	_highlighted.clear()


func _highlight(id: int) -> void:
	_cell_to_node[id].set_highlight(true, highlight_color)
	for neighbour in _voronoi.neighboring_cells(id):
		_cell_to_node[neighbour].set_highlight(true, highlight_neighbour_color)
		_highlighted.append(neighbour)
	_highlighted.append(id)
	_highlight_target = id
