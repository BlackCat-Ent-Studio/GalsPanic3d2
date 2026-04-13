extends Node
class_name CameraCinematic
## Stationary-camera cinematic polish: tweens Camera3D.fov + Camera3D.rotation so
## the view pitches up to frame the in-world reveal screen whenever territory is
## claimed. Camera POSITION is never touched — composes with CameraShake.

const SHOT_FOV_TARGET := 28.0                        # lower = tighter zoom; tune live
const SCREEN_LOOK_TARGET := Vector3(0.0, 6.5, -10.0) # ImageRevealScreen center in world
const ZOOM_IN_DURATION := 0.9
const ZOOM_HOLD_DURATION := 0.4
const ZOOM_OUT_DURATION := 0.9
const IDLE_INTERVAL_MIN := 12.0
const IDLE_INTERVAL_MAX := 25.0
const INPUT_IDLE_REQUIRED := 3.0  # seconds of no cursor activity before idle shot eligible

var _camera: Camera3D
var _base_fov: float
var _base_rotation: Vector3
var _shot_rotation: Vector3
var _is_playing: bool = false
var _time_since_input: float = 0.0
var _idle_timer: float = 0.0
var _next_idle_fire: float = 0.0


func _ready() -> void:
	_camera = get_parent() as Camera3D
	if _camera == null:
		set_process(false)
		return
	# CameraShake._auto_frame_camera() runs in its own _ready and may also be on
	# this Camera3D — wait one frame so the base transform is final before we
	# capture it and compute the shot rotation.
	await get_tree().process_frame
	_base_fov = _camera.fov
	_base_rotation = _camera.rotation
	_shot_rotation = _compute_shot_rotation()
	_schedule_next_idle()
	GameEvents.regions_claimed_with_data.connect(_on_claim)


## Compute the rotation that would aim the camera at SCREEN_LOOK_TARGET,
## without actually disturbing the live camera transform.
func _compute_shot_rotation() -> Vector3:
	var saved_transform := _camera.transform
	_camera.look_at(SCREEN_LOOK_TARGET, Vector3.UP)
	var rot := _camera.rotation
	_camera.transform = saved_transform
	return rot


func _process(delta: float) -> void:
	# Self-contained input-idle tracking — no coupling with InputHandler.
	if Input.get_last_mouse_velocity().length_squared() > 1.0:
		_time_since_input = 0.0
	else:
		_time_since_input += delta

	_idle_timer += delta
	if _idle_timer >= _next_idle_fire:
		_try_play_idle_shot()
		_schedule_next_idle()


## Two-stage shot: pitch+zoom in → hold → pitch+zoom out.
## Ignored if a shot is already playing.
func play_shot() -> void:
	if _is_playing or _camera == null:
		return
	_is_playing = true
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Stage 1: zoom + pitch up toward the reveal screen (parallel)
	tw.set_parallel(true)
	tw.tween_property(_camera, "fov", SHOT_FOV_TARGET, ZOOM_IN_DURATION)
	tw.tween_property(_camera, "rotation", _shot_rotation, ZOOM_IN_DURATION)
	tw.set_parallel(false)

	# Hold the tight frame briefly
	tw.tween_interval(ZOOM_HOLD_DURATION)

	# Stage 2: return to base (parallel)
	tw.set_parallel(true)
	tw.tween_property(_camera, "fov", _base_fov, ZOOM_OUT_DURATION)
	tw.tween_property(_camera, "rotation", _base_rotation, ZOOM_OUT_DURATION)
	tw.set_parallel(false)

	# Release lock after the full chain finishes
	tw.tween_callback(func() -> void: _is_playing = false)


func _try_play_idle_shot() -> void:
	if _is_playing or _time_since_input < INPUT_IDLE_REQUIRED:
		return
	play_shot()


func _schedule_next_idle() -> void:
	_idle_timer = 0.0
	_next_idle_fire = randf_range(IDLE_INTERVAL_MIN, IDLE_INTERVAL_MAX)


func _on_claim(_claimed: Array, _all: Array) -> void:
	play_shot()
