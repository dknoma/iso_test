extends CharacterBody3D

class_name SubmarineA



const SPEED = 1.0
var currentSpeed = 0
var speedPos = 0
var rudderAngle = 0
var planeAngle = 0
var pitchTarget
var curPitch
var has_control = false

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	player.Captain.connect(playerCaptain)

func playerCaptain():
	has_control = true

func _physics_process(delta):
	
	if has_control:
		vesselControl()

	velocity = global_transform.basis.z * currentSpeed
	rotate_y(deg_to_rad(rudderAngle * speedPos)* delta)
	rotation.x = lerp(curPitch, pitchTarget, delta/2)
	
	move_and_slide()
#movement of vessel in forward or backwards
func propSpeed():
	if Input.is_action_just_pressed("vesselForward"):
		speedPos += 1
	if speedPos > 5:
			speedPos = 5
	elif Input.is_action_just_pressed("vesselBackwards"):
		speedPos -= 1
		if speedPos < -3:
			speedPos = -3
	currentSpeed = SPEED * speedPos 

func rudder_Angle():
	if Input.is_action_just_pressed("vesselTurnLeft"):
		rudderAngle += 1
	if rudderAngle > 3:
			rudderAngle = 3
	elif Input.is_action_just_pressed("vesselTurnRight"):
		rudderAngle -= 1
		if rudderAngle < -3:
			rudderAngle = -3
		#lerp(Vector2(0.0, sideDash*direction), Vector2.ZERO, t)

#movement 0, turn/cilmb 0
func plane_Angle():
	if Input.is_action_just_pressed("vesselClimb"):
		planeAngle += 1
	if planeAngle > 3:
			planeAngle = 3
	elif Input.is_action_just_pressed("vesselDive"):
		planeAngle -= 1
		if planeAngle < -3:
			planeAngle = -3
	curPitch = rotation.x
	pitchTarget = deg_to_rad(planeAngle * 9)

func allControllReset():
	if Input.is_action_just_pressed("ControllSurfReset"):
		rudderAngle = 0
		planeAngle = 0

func vesselControl():
	propSpeed()
	rudder_Angle()
	plane_Angle()
	allControllReset()
