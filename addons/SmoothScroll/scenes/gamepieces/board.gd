extends Node3D

### Handles board creation and access.
## Can receive effects.

const TILE_LENIENCE = 0.1
var grid_h : int
var grid_w : int
const TILE_RES = preload("res://scenes/gamepieces/tile.tscn")
var sizeinc : float
var camera : Camera3D
var grid = [] ## 2D array containing all tiles

signal board_done(center : Vector3) # Board generated.
signal started_ng(h : int, w : int) ## Start of a new game triggered.
signal tile_selected(x : int, y : int)
func _on_ready():
	camera = get_tree().root.get_camera_3d()
	started_ng.emit(7,7) # TEST FORMAT

func _new_board(h : int, w : int): ## Creates board's necessary data elements.
	## Cleanup old tiles
	var tile_scene = TILE_RES.instantiate()
	sizeinc = tile_scene.get_child(1).get_child(0).shape.size.x + TILE_LENIENCE
	tile_scene = null
	## Setup new tiles
	grid_h = h
	grid_w = w
	var startPos = Vector3.ZERO
	var endPos = Vector3.ZERO
	var totalTiles = (grid_w * grid_h)

	## Handle centers
	var even_width = ((grid_w % 2) == 0)
	var even_height = ((grid_h % 2) == 0)
	var centers = []
	var true_center = Vector2i(floori(grid_w / 2.0), floori(grid_h / 2.0))
	centers.append(true_center) ## so in a 7 by 7, this would be pos(3,3)
	if even_height: ## if grid is evenly tall
		centers.append(Vector2i(true_center.x, true_center.y - 1))
		if even_width: ## if grid is evenly wide
			centers.append(Vector2i(true_center.x - 1, true_center.y - 1))
	if even_width: ## if grid is evenly wide
		centers.append(Vector2i(true_center.x - 1, true_center.y))
	
	for c in centers: 
		print("This grid has a center at (" + str(c.x) + "," + str(c.y) + ")")
	
	## Generate tiles
	var numGen = 0
	for i in range(grid_w):
		grid.append([]) ## Create new row (2D array)
		var x_offset = i * sizeinc
		for j in range(grid_h):
			# print("trying to make tile " + str(i) + " " + str(j))
			var tile = TILE_RES.instantiate()
			# Determine default color of tile
			var defaultColor = Color.WHITE
			if i == j or i == (grid_w - j - 1): defaultColor = Color.GRAY
			else: if (i % 2) == (j % 2): defaultColor = Color.ANTIQUE_WHITE
			# Determine centers
			for c in centers:
				if(c.x == i && c.y == j):
					# defaultColor = Color.DARK_GRAY
					print("cool!")
			# Determine position of tile
			var z_offset = j * sizeinc
			tile.position = Vector3(x_offset,0,z_offset)
			numGen += 1
			# Determine corners of map
			if numGen == 1: startPos = tile.position
			if numGen == totalTiles: endPos = tile.position
			tile.name = "Tile " + str(i) + ", " + str(j)
			tile.add_to_group("tiles")
			grid[i].append(tile) ## Add tile to row
			add_child(tile)
			tile.xy = Vector2i(i,j)
			tile.defaultColor = defaultColor
			tile.unpaint()
	print("Generated " + str(numGen) + " tiles")
	# Position the camera
	var targetPos = (startPos + endPos) / 2.0
	# print(targetPos)
	position = position - targetPos
	board_done.emit(targetPos)
