class_name ClaimTexture
extends RefCounted
## Rasterizes board state to L8 texture for ground shader.
## 3-pass: classify regions → draw walls → merge interior walls.

const TEX_SIZE := 256  # 256x256 = 65K pixels (was 512 = 262K, 4x faster)
const BOARD_MIN := Vector2(-10.0, -10.0)
const BOARD_SIZE := Vector2(20.0, 20.0)

const OUTSIDE := 0
const EMPTY := 64
const WALL := 128
const CLAIMED := 255

var _image: Image
var _texture: ImageTexture
var _pixel_data: PackedByteArray  # Direct byte access (much faster than set_pixel)


func _init() -> void:
	_pixel_data = PackedByteArray()
	_pixel_data.resize(TEX_SIZE * TEX_SIZE)
	_pixel_data.fill(EMPTY)
	_image = Image.create_from_data(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_L8, _pixel_data)
	_texture = ImageTexture.create_from_image(_image)


func get_texture() -> ImageTexture:
	return _texture


## Full regeneration from current board state.
func regenerate(regions: Array[Region], segments: Array[WallSegment]) -> void:
	# Pre-compute bounding boxes for all regions
	var region_bounds: Array[Rect2] = []
	for region in regions:
		region_bounds.append(_compute_bounds(region.polygon))

	# Pass 1: Classify pixels (with bounding box pre-check)
	_classify_pixels(regions, region_bounds)
	# Pass 2: Draw wall segments
	_draw_walls(segments)
	# Pass 3: Merge wall pixels surrounded by claimed (single pass)
	_merge_wall_pixels()
	# Upload
	_image = Image.create_from_data(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_L8, _pixel_data)
	_texture.update(_image)


func _classify_pixels(regions: Array[Region], bounds: Array[Rect2]) -> void:
	var region_count := regions.size()
	for y in TEX_SIZE:
		for x in TEX_SIZE:
			var world_pos := _pixel_to_world(x, y)
			var value := OUTSIDE
			for ri in region_count:
				# Bounding box pre-check: skip expensive point-in-polygon
				if not bounds[ri].has_point(world_pos):
					continue
				if regions[ri].contains_point(world_pos):
					value = CLAIMED if regions[ri].is_claimed else EMPTY
					break
			_pixel_data[y * TEX_SIZE + x] = value


func _draw_walls(segments: Array[WallSegment]) -> void:
	for seg in segments:
		_bresenham_thick(seg.start, seg.end, WALL, 1)


func _merge_wall_pixels() -> void:
	# Single pass: convert WALL pixels whose 4-neighbors are all CLAIMED
	for y in range(1, TEX_SIZE - 1):
		for x in range(1, TEX_SIZE - 1):
			var idx := y * TEX_SIZE + x
			if _pixel_data[idx] != WALL:
				continue
			var up := _pixel_data[(y - 1) * TEX_SIZE + x]
			var down := _pixel_data[(y + 1) * TEX_SIZE + x]
			var left := _pixel_data[y * TEX_SIZE + (x - 1)]
			var right := _pixel_data[y * TEX_SIZE + (x + 1)]
			if up >= CLAIMED and down >= CLAIMED and left >= CLAIMED and right >= CLAIMED:
				_pixel_data[idx] = CLAIMED


func _bresenham_thick(world_a: Vector2, world_b: Vector2, value: int, radius: int) -> void:
	var pa := _world_to_pixel(world_a)
	var pb := _world_to_pixel(world_b)
	var dx := absi(pb.x - pa.x)
	var dy := -absi(pb.y - pa.y)
	var sx := 1 if pa.x < pb.x else -1
	var sy := 1 if pa.y < pb.y else -1
	var err := dx + dy
	var cx := pa.x
	var cy := pa.y

	while true:
		for oy in range(-radius, radius + 1):
			for ox in range(-radius, radius + 1):
				var px := cx + ox
				var py := cy + oy
				if px >= 0 and px < TEX_SIZE and py >= 0 and py < TEX_SIZE:
					_pixel_data[py * TEX_SIZE + px] = value
		if cx == pb.x and cy == pb.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy


func _pixel_to_world(px: int, py: int) -> Vector2:
	return BOARD_MIN + Vector2(
		(float(px) + 0.5) / TEX_SIZE * BOARD_SIZE.x,
		(float(py) + 0.5) / TEX_SIZE * BOARD_SIZE.y
	)


func _world_to_pixel(world: Vector2) -> Vector2i:
	var rel := (world - BOARD_MIN) / BOARD_SIZE
	return Vector2i(
		clampi(int(rel.x * TEX_SIZE), 0, TEX_SIZE - 1),
		clampi(int(rel.y * TEX_SIZE), 0, TEX_SIZE - 1)
	)


func _compute_bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var min_pt := polygon[0]
	var max_pt := polygon[0]
	for v in polygon:
		min_pt = Vector2(minf(min_pt.x, v.x), minf(min_pt.y, v.y))
		max_pt = Vector2(maxf(max_pt.x, v.x), maxf(max_pt.y, v.y))
	return Rect2(min_pt, max_pt - min_pt)
