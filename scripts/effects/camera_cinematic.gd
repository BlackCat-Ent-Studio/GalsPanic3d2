extends Node
class_name CameraCinematic
## Stationary-camera cinematic polish. Two shot types:
##   1. Claim shot: zoom to reveal screen (static target) — triggered by region claim.
##   2. Boss idle shot: zoom to a BossFireball and track it moving (dynamic target)
##      — triggered when player is idle. Interrupts on cursor movement or boss death.
## Camera POSITION is never touched — composes with CameraShake.

enum State { IDLE, ZOOMING_IN, TRACKING, ZOOMING_OUT }

const SHOT_FOV_TARGET := 28.0                        # lower = tighter zoom
const SCREEN_LOOK_TARGET := Vector3(0.0, 6.5, -10.0) # ImageRevealScreen center
const ZOOM_IN_DURATION := 0.9
const ZOOM_HOLD_DURATION := 0.4                       # hold time for claim shot (static)
const ZOOM_OUT_DURATION := 0.9
const BOSS_TRACK_DURATION := 4.0                      # how long to watch the boss move
const IDLE_INTERVAL_MIN := 12.0
const IDLE_INTERVAL_MAX := 25.0
const INPUT_IDLE_REQUIRED := 3.0
const TRACK_SMOOTH_SPEED := 4.0                       # how fast camera rotation follows boss

var _camera: Camera3D
var _base_fov: float
var _base_rotation: Vector3
var _screen_rotation: Vector3
var _state: int = State.IDLE
var _time_since_input: float = 0.0
var _idle_timer: float = 0.0
var _next_idle_fire: float = 0.0
var _tracked_boss: Node3D = null
var _track_timer: float = 0.0
var _active_tween: Tween = null


func _ready() -> void:
	_camera = get_parent() as Camera3D
	if _camera == null:
		set_process(false)
		return
	# Wait one frame so CameraShake._auto_frame_camera() finishes first.
	await get_tree().process_frame
	_base_fov = _camera.fov
	_base_rotation = _camera.rotation
	_screen_rotation = _compute_look_rotation(SCREEN_LOOK_TARGET)
	_schedule_next_idle()
	GameEvents.regions_claimed_with_data.connect(_on_claim)


## Compute rotation to aim at a world position without disturbing live transform.
func _compute_look_rotation(target: Vector3) -> Vector3:
	var saved := _camera.transform
	_camera.look_at(target, Vector3.UP)
	var rot := _camera.rotation
	_camera.transform = saved
	return rot


func _process(delta: float) -> void:
	# Input-idle tracking
	if Input.get_last_mouse_velocity().length_squared() > 1.0:
		_time_since_input = 0.0
		# Interrupt boss tracking on cursor movement
		if _state == State.TRACKING:
			_start_zoom_out()
	else:
		_time_since_input += delta

	# Boss tracking: smoothly follow the boss each frame
	if _state == State.TRACKING:
		_process_tracking(delta)

	# Idle timer
	if _state == State.IDLE:
		_idle_timer += delta
		if _idle_timer >= _next_idle_fire:
			_try_play_boss_shot()
			_schedule_next_idle()


## --- CLAIM SHOT (static target: reveal screen) ---

func play_screen_shot() -> void:
	if _state != State.IDLE or _camera == null:
		return
	_state = State.ZOOMING_IN
	_kill_active_tween()

	var tw := create_tween()
	_active_tween = tw
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Zoom in to screen
	tw.tween_property(_camera, "fov", SHOT_FOV_TARGET, ZOOM_IN_DURATION)
	tw.parallel().tween_property(_camera, "rotation", _screen_rotation, ZOOM_IN_DURATION)

	# Hold
	tw.tween_interval(ZOOM_HOLD_DURATION)

	# Zoom out
	tw.tween_property(_camera, "fov", _base_fov, ZOOM_OUT_DURATION)
	tw.parallel().tween_property(_camera, "rotation", _base_rotation, ZOOM_OUT_DURATION)

	tw.tween_callback(_on_shot_finished)


## --- BOSS IDLE SHOT (dynamic target: track a BossFireball) ---

func _try_play_boss_shot() -> void:
	if _state != State.IDLE or _time_since_input < INPUT_IDLE_REQUIRED:
		return
	var boss := _find_boss()
	if boss == null:
		return
	_tracked_boss = boss
	_track_timer = 0.0
	_state = State.ZOOMING_IN
	_kill_active_tween()

	# Zoom in toward boss's current position
	var boss_rot := _compute_look_rotation(boss.global_position)
	var tw := create_tween()
	_active_tween = tw
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_camera, "fov", SHOT_FOV_TARGET, ZOOM_IN_DURATION)
	tw.parallel().tween_property(_camera, "rotation", boss_rot, ZOOM_IN_DURATION)
	tw.tween_callback(func() -> void: _state = State.TRACKING)


func _process_tracking(delta: float) -> void:
	# Boss died or removed — bail out
	if not is_instance_valid(_tracked_boss):
		_tracked_boss = null
		_start_zoom_out()
		return

	# Smoothly rotate to follow the boss
	var target_rot := _compute_look_rotation(_tracked_boss.global_position)
	_camera.rotation = _camera.rotation.lerp(target_rot, TRACK_SMOOTH_SPEED * delta)

	_track_timer += delta
	if _track_timer >= BOSS_TRACK_DURATION:
		_start_zoom_out()


func _start_zoom_out() -> void:
	_state = State.ZOOMING_OUT
	_tracked_boss = null
	_kill_active_tween()

	var tw := create_tween()
	_active_tween = tw
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_camera, "fov", _base_fov, ZOOM_OUT_DURATION)
	tw.parallel().tween_property(_camera, "rotation", _base_rotation, ZOOM_OUT_DURATION)
	tw.tween_callback(_on_shot_finished)


## --- HELPERS ---

func _find_boss() -> BossFireball:
	var fb_mgr := get_tree().get_first_node_in_group("fireballs")
	if fb_mgr == null:
		# Fallback: search by class across scene
		for node in get_tree().get_nodes_in_group("fireballs"):
			for child in node.get_children():
				if child is BossFireball:
					return child
		return null
	for child in fb_mgr.get_children():
		if child is BossFireball:
			return child
	return null


func _kill_active_tween() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null


func _on_shot_finished() -> void:
	_state = State.IDLE
	_active_tween = null
	_tracked_boss = null


func _schedule_next_idle() -> void:
	_idle_timer = 0.0
	_next_idle_fire = randf_range(IDLE_INTERVAL_MIN, IDLE_INTERVAL_MAX)


func _on_claim(_claimed: Array, _all: Array) -> void:
	play_screen_shot()
