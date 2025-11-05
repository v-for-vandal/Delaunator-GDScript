extends Node2D

const Delaunator := preload("res://addons/Delaunator-GDScript/Delaunator.gd")
const MapRegionScene := preload("res://addons/Delaunator-GDScript/MapRegion.tscn")
const Voronoinator := preload("res://addons/Delaunator-GDScript/Voronoinator.gd")

var points := PackedVector2Array([
	Vector2(0, 0), Vector2(1024, 0), Vector2(1024, 600), Vector2(0, 600), Vector2(29, 390), Vector2(859, 300), Vector2(65, 342), Vector2(86, 333), Vector2(962, 212), Vector2(211, 351), Vector2(3, 594), Vector2(421, 278), Vector2(608, 271), Vector2(230, 538), Vector2(870, 454), Vector2(850, 351), Vector2(583, 385), Vector2(907, 480), Vector2(749, 533), Vector2(877, 232), Vector2(720, 546), Vector2(1003, 541), Vector2(696, 594), Vector2(102, 306)
])

@onready var delaunay := Delaunator.new(points)
@onready var voronoi := Voronoinator.new(delaunay)

func _ready():
	$VoronoiVisualization.set_voronoi(voronoi)
