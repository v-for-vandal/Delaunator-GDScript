extends Node2D

const Delaunator := preload("res://addons/Delaunator-GDScript/Delaunator.gd")
const MapRegionScene := preload("res://addons/Delaunator-GDScript/MapRegion.tscn")
const Voronoinator := preload("res://addons/Delaunator-GDScript/Voronoinator.gd")

var points := PackedVector2Array([
	Vector2(0, 0), Vector2(1024, 0), Vector2(1024, 600), Vector2(0, 600), Vector2(29, 390), Vector2(859, 300), Vector2(65, 342), Vector2(86, 333), Vector2(962, 212), Vector2(211, 351), Vector2(3, 594), Vector2(421, 278), Vector2(608, 271), Vector2(230, 538), Vector2(870, 454), Vector2(850, 351), Vector2(583, 385), Vector2(907, 480), Vector2(749, 533), Vector2(877, 232), Vector2(720, 546), Vector2(1003, 541), Vector2(696, 594), Vector2(102, 306)
])

var _voronoi : Voronoinator
var _cells : Array[PackedVector2Array]

var _cell_to_node: Dictionary[int, MapRegion] = {}
var _highlighted : Array[int]

func set_voronoi(voronoi : Voronoinator):
	clear()
	
	_voronoi = voronoi
	_cells = voronoi.voronoi_cells
	
	_construct()

func clear():
	for child in get_children():
		if child is MapRegion:
			child.queue_free()
	_cells = []
	_voronoi = null
	_cell_to_node.clear()
	_highlighted.clear()
	
	
func _construct():
	for i in range(_cells.size()):
		var map_region : MapRegion = MapRegionScene.instantiate()
		_cell_to_node[i] = map_region
		add_child(map_region)
		map_region.shape = _cells[i]
		map_region.region_selected.connect(_on_MapRegion_selected.bind(i))

func _on_MapRegion_selected(id : int):
	# Clear previous highlight
	for idx in _highlighted:
		print("Clear highlight from" + str(idx))
		_cell_to_node[idx].set_highlight(false)
	
	_highlighted.clear()
		
	print ("Region #" + str(id) + " was selected.")
	for neighbour in _voronoi.neighboring_cells(id):
		print ("Neigbour is #" + str(neighbour))
		_cell_to_node[neighbour].set_highlight(true)
		_highlighted.append(neighbour)
