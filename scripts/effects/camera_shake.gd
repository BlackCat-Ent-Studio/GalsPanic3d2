extends Node
class_name CameraShake
## Applies additive shake offset to parent Camera3D.

var _camera: Camera3D
var _original_pos: Vector3
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _active: bool = false


func _ready() -> void:
	_camera = get_parent() as Camera3D
	if _camera:
		_auto_frame_camera()
		_original_pos = _camera.position
	GameEvents.arm_destroyed.connect(_on_arm_destroyed)
	GameEvents.generator_destroyed.connect(_on_generator_destroyed)
	set_process(false)


## Auto-position camera to frame both the board (Y=0) and wall screen (Y~12.5).
func _auto_frame_camera() -> void:
	# Scene: board at Y=0 Z[-10,10], wall screen top at Y~12.5 Z=-10
	# Camera looks at center of the combined scene
	var look_target := Vector3(0, 4.0, -2.0)  # Midpoint between board and screen
	var pitch_deg := 35.0  # Angle from horizontal
	var distance := 32.0   # Distance from target

	var pitch_rad := deg_to_rad(pitch_deg)
	var cam_offset := Vector3(
		0,
		sin(pitch_rad) * distance,
		cos(pitch_rad) * distance
	)
	_camera.position = look_target + cam_offset
	_camera.look_at(look_target, Vector3.UP)
	_camera.fov = 45.0


func shake(intensity: float, duration: float) -> void:
	if intensity > _shake_intensity or not _active:
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_timer = 0.0
		_active = true
		set_process(true)


func _process(delta: float) -> void:
	if not _camera or not _active:
		set_process(false)
		return
	_shake_timer += delta
	if _shake_timer >= _shake_duration:
		_camera.position = _original_pos
		_active = false
		_shake_intensity = 0.0
		set_process(false)
		return
	var decay := 1.0 - (_shake_timer / _shake_duration)
	var offset := Vector3(
		randf_range(-1.0, 1.0) * _shake_intensity * decay,
		randf_range(-1.0, 1.0) * _shake_intensity * decay * 0.5,
		0.0
	)
	_camera.position = _original_pos + offset


func _on_arm_destroyed() -> void:
	shake(0.08, 0.3)


func _on_generator_destroyed() -> void:
	shake(0.15, 0.5)
