class_name Voronoinator
extends RefCounted

# input - delaunator
var _delaunay: Delaunator
# our public members

## Voronoi cells - array of polygon, each polygon is an array of Vector2f points
var voronoi_cells: Array[PackedVector2Array] = []
## Mapping from triangle to cells that it is part of. Cells are represented
## as indices in `voronoi_cells` member
var triangle_to_cells: Dictionary[int, PackedInt32Array] = { }

## Mapping from voronoi cell to triangles that it was built from
var cell_to_triangles: Dictionary[int, PackedInt32Array] = { }


static func next_half_edge(e: int) -> int:
	return e - 2 if e % 3 == 2 else e + 1


static func triangle_of_edge(e: int) -> int:
	return floori(e / 3.0)


static func edges_of_triangle(t: int) -> Array[int]:
	return [3 * t, 3 * t + 1, 3 * t + 2]


static func circumcenter(a, b, c) -> Vector2:
	var ad = a[0] * a[0] + a[1] * a[1]
	var bd = b[0] * b[0] + b[1] * b[1]
	var cd = c[0] * c[0] + c[1] * c[1]
	var d = 2 * (a[0] * (b[1] - c[1]) + b[0] * (c[1] - a[1]) + c[0] * (a[1] - b[1]))

	return Vector2(
		1 / d * (ad * (b[1] - c[1]) + bd * (c[1] - a[1]) + cd * (a[1] - b[1])),
		1 / d * (ad * (c[0] - b[0]) + bd * (a[0] - c[0]) + cd * (b[0] - a[0])),
	)


static func centroid(a, b, c) -> Vector2:
	var c_x = (a[0] + b[0] + c[0]) / 3
	var c_y = (a[1] + b[1] + c[1]) / 3

	return Vector2(c_x, c_y)


static func incenter(a, b, c) -> Vector2:
	var ab = sqrt(pow(a[0] - b[0], 2) + pow(b[1] - a[1], 2))
	var bc = sqrt(pow(b[0] - c[0], 2) + pow(c[1] - b[1], 2))
	var ac = sqrt(pow(a[0] - c[0], 2) + pow(c[1] - a[1], 2))
	var c_x = (ab * a[0] + bc * b[0] + ac * c[0]) / (ab + bc + ac)
	var c_y = (ab * a[1] + bc * b[1] + ac * c[1]) / (ab + bc + ac)

	return Vector2(c_x, c_y)


func _init(delaunay: Delaunator, forced_boundary: Rect2 = Rect2(Vector2.INF, Vector2.ZERO)) -> void:
	_delaunay = delaunay

	_constructor(forced_boundary)


func _constructor(forced_boundary: Rect2) -> void:
	_get_voronoi_cells(forced_boundary)


func edges_around_point(start):
	var result = []
	var incoming = start
	while true:
		result.append(incoming)
		var outgoing = next_half_edge(incoming)
		incoming = _delaunay.halfedges[outgoing]
		if not (incoming != -1 and incoming != start):
			break
	return result


func points_of_triangle(t: int) -> Array[Vector2]:
	var points_of_triangle: Array[Vector2] = []
	for e in edges_of_triangle(t):
		points_of_triangle.append(_delaunay.points[_delaunay.triangles[e]])
	return points_of_triangle


func triangle_center(t: int, center = "circumcenter") -> Vector2:
	var vertices := points_of_triangle(t)
	match center:
		"circumcenter":
			return circumcenter(vertices[0], vertices[1], vertices[2])
		"centroid":
			return centroid(vertices[0], vertices[1], vertices[2])
		"incenter":
			return incenter(vertices[0], vertices[1], vertices[2])
		_:
			return circumcenter(vertices[0], vertices[1], vertices[2])


func _get_voronoi_cells(forced_boundary: Rect2) -> void:
	voronoi_cells.clear()
	triangle_to_cells.clear()
	cell_to_triangles.clear()

	var seen = [] # TODO: make it a dictionary (no sets in godot)
	for e in _delaunay.triangles.size():
		var triangles: Array[int] = []
		var vertices: Array[Vector2] = []
		var p := _delaunay.triangles[next_half_edge(e)]
		if not seen.has(p):
			seen.append(p)
			var edges = edges_around_point(e)
			for edge in edges:
				triangles.append(triangle_of_edge(edge))
			for t in triangles:
				vertices.append(triangle_center(t))

		if triangles.size() > 2:
			var voronoi_cell := PackedVector2Array()
			for vertice in vertices:
				if forced_boundary.size > Vector2.ZERO:
					# skip points that are outside boundary. This will leave some
					# holes
					if not (vertice.x >= forced_boundary.position.x 
						and	vertice.x <= forced_boundary.end.x
						and vertice.y >= forced_boundary.position.y
						and vertice.y <= forced_boundary.end.y
						):
							# skip vertices outside of boundary
							continue
					vertice = vertice.clamp(forced_boundary.position, forced_boundary.end)

				voronoi_cell.append(vertice)
				
			if voronoi_cell.size() >= 3:
				var voronoi_cell_idx := voronoi_cells.size()
				voronoi_cells.append(voronoi_cell)
				cell_to_triangles[voronoi_cell_idx] = PackedInt32Array(triangles)
				for t in triangles:
					triangle_to_cells.get_or_add(t, PackedInt32Array()).append(voronoi_cell_idx)


## Given an index of a cell, returns indicies of its neighbours
func neighboring_cells(cell_id: int) -> Array[int]:
	assert(cell_id < voronoi_cells.size())
	var result: Array[int] = []

	for triangle in cell_to_triangles[cell_id]:
		for cell in triangle_to_cells[triangle]:
			if cell == cell_id:
				continue
			# That is quadratic complexity, but we ususally don't have more than
			# 5-6 neighbours
			if result.has(cell):
				continue
			result.append(cell)
	return result
