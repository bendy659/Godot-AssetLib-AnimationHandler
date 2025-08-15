extends Node

## Timeline data. [br]
## Please, use function [u][AnimationHandler.timeline][/u]
class _Timeline:
	var object: Object
	var property: String
	var keyframes: Array[_Keyframe]
	
	func _init(object: Object, property: String, keyframes: Array[_Keyframe]):
		self.object = object
		self.property = property
		self.keyframes = keyframes

## Keyframe data. [br]
## Please, use function [u][method AnimationHandler.keyframe][/u]
class _Keyframe:
	var time: int
	var value: Variant
	var easing: float
	var signalObject: Object
	var signalName: String
	var eventTriggered: bool
	
	func _init(time: int, value: Variant, easing: float, signalObject: Object, signalName: String):
		self.time = time
		self.value = value
		self.easing = easing
		self.signalObject = signalObject
		self.signalName = signalName
		self.eventTriggered = false
	
	func triggered():
		eventTriggered = true
	
	func clearTrigger():
		eventTriggered = false

## Animation layer maker. [br]
## Please, use function [u][method AnimationHandler.animation][/u]
class _Animation:
	var animationName: String
	var timelines: Array[_Timeline]
	
	func _init(animationName: String, timelines: Array[_Timeline]) -> void:
		self.animationName = animationName
		self.timelines = timelines

## Animator
class _Animator:
	var animations: Dictionary = {}
	var cTime: float = 0.0
	var mTime: float = 0.0
	var cAnimation: String = "NONE"
	var playing: bool = false
	var timeScale: float = 1.0
	
	## Add animation to Animator
	func addAnimation(nAnimation: _Animation):
		self.animations[nAnimation.animationName] = nAnimation.timelines
	
	## Calc max animation time
	func mTimeApply():
		var animDat: Array[_Timeline] = animations[cAnimation]
		var max_time: float = 0.0
		
		for timeline in animDat:
			if timeline.keyframes.size() > 0:
				max_time = max(max_time, timeline.keyframes[timeline.keyframes.size() - 1].time)
		mTime = max_time
	
	## Start playing [param pAnimationName] animation
	func play(pAnimationName: String, force: bool = false):
		if !animations.has(pAnimationName): # If pAnimationName not found
			print("Animation '%s' not found!" % pAnimationName)
			return # Stoping playing
		
		if force: # if animation playing on start
			cTime = 0.0
		
		cAnimation = pAnimationName
		mTimeApply()
		playing = true
	
	## Pause active animation
	func pause(play: bool):
		playing = play
	
	## Stop playing animation
	func stop(toEnd: bool = false):
		if toEnd: # If stoping animation to end
			mTimeApply()
			cTime = mTime
		
		cAnimation = &"NONE"
		playing = false
	
	## Update animation data
	func update(delta: float):
		# If animation not now playing
		if !playing: return
		
		# If current animation named on "NONE" (NOTHING)
		if cAnimation == &"NONE": return # Not updating
		
		# If current time lower maximum time - animating
		if cTime < mTime:
			cTime += delta * timeScale
			cTime = mTime if cTime > mTime else cTime # if current highed max - lower to max
			
			var cTimelines: Array[_Timeline] = animations[cAnimation]
			
			for cLine in cTimelines:
				var cTarg: Object = cLine.object
				var cTargProp: StringName = cLine.property
				var cKeys: Array[_Keyframe] = cLine.keyframes
				
				# If keyframes count lower or equal one keyframe - skip
				if cKeys.size() <= 1: 
					playing = false # Stop playing
					return
				
				var cKey: _Keyframe
				var nKey: _Keyframe
				
				for key in cKeys:
					# If keyframe event object & signal not null and event triggered = false
					if !key.eventTriggered:
						key.eventTriggered = true # Change state
						key.signalObject.emit_signal(key.signalName) # Emit signal
					
					# If keyframe time lower or equal current time - current key = key
					# else if keyframe time highed current time and next key == null
					if key.time <= cTime:
						cKey = key
					elif key.time > cTime && !nKey:
						nKey = key
					
					if cKey && nKey: break
				
				if !cKey:
					cKey = cKeys[0]
					nKey = cKeys[0] if cKeys.size() == 1 else cKeys[1]
				
				if !nKey:
					nKey = cKey
				
				var tTime: float = nKey.time - cKey.time # Total time
				var prg = (cTime - cKey.time) / tTime if tTime > 0 else 1 # Progress (0..1)
				prg = clamp(prg, 0, 1)
				
				var eased: float = ease(prg, cKey.easing)
				var interpolated: Variant = interpolateValue(cKey.value, nKey.value, eased)
				
				set_nested(cLine.object, str(cLine.property), interpolated)
	
	func interpolateValue(from: Variant, to: Variant, weight: float) -> Variant:
		var typeA = typeof(from)
		var typeB = typeof(to)
		
		#assert(typeA != typeB, "") # If from & to - !equal types
		
		var types: Dictionary = {
			"object": [TYPE_OBJECT],
			"string": [TYPE_STRING, TYPE_STRING_NAME],
			"bool": [TYPE_BOOL],
			"vector2": [TYPE_VECTOR2, TYPE_VECTOR2I],
			"vector3": [TYPE_VECTOR3, TYPE_VECTOR3I],
			"color": [TYPE_COLOR],
			"rect2": [TYPE_RECT2, TYPE_RECT2I]
		}
		if typeA in types["string"] || typeB in types["string"]:
			return from
		elif typeA in types["bool"] || typeB in types["bool"]:
			return from
		elif typeA in types["vector2"] || typeB in types["vector2"]:
			return Vector2(from).lerp(to, weight)
		elif typeA in types["vector3"] || typeB in types["vector3"]:
			return Vector3(from).lerp(to, weight)
		elif typeA in types["color"] || typeB in types["color"]:
			return Color(from).lerp(to, weight)
		elif typeA in types["rect2"] || typeB in types["rect2"]:
			return Rect2(
				from.position.lerp(to.position, weight),
				from.size.lerp(to.size, weight)
			)
		else:
			return lerp(float(from), float(to), weight)
	
	func set_nested(obj: Object, path: String, value: Variant):
		var parts = path.replace(":", ".").split(".")
		
		if parts.size() == 1:
			obj.set(parts[0], value)
			return
		
		var base_prop = parts[0]
		var sub_path = parts.slice(1, parts.size())
		
		var target = obj.get(base_prop)
		
		# Vector2 / Vector3 / Color / Rect2 и т.д.
		if typeof(target) in [TYPE_VECTOR2, TYPE_VECTOR2I]:
			var v = target
			if sub_path[0] == "x": v.x = value
			elif sub_path[0] == "y": v.y = value
			obj.set(base_prop, v)
		elif typeof(target) in [TYPE_VECTOR3, TYPE_VECTOR3I]:
			var v = target
			if sub_path[0] == "x": v.x = value
			elif sub_path[0] == "y": v.y = value
			elif sub_path[0] == "z": v.z = value
			obj.set(base_prop, v)
		elif typeof(target) == TYPE_COLOR:
			var c = target
			if sub_path[0] == "r": c.r = value
			elif sub_path[0] == "g": c.g = value
			elif sub_path[0] == "b": c.b = value
			elif sub_path[0] == "a": c.a = value
			obj.set(base_prop, c)
		elif typeof(target) == TYPE_RECT2:
			var r = target
			if sub_path[0] == "position":
				if sub_path[1] == "x": r.position.x = value
				elif sub_path[1] == "y": r.position.y = value
			elif sub_path[0] == "size":
				if sub_path[1] == "x": r.size.x = value
				elif sub_path[1] == "y": r.size.y = value
			obj.set(base_prop, r)
		else:
			push_error("Unsupported nested type for: %s" % typeof(target))

## API functions

## Creates a new animator and adds the provided animations to it. [br]
## [br]
## [param animations] Array of [AnimationHandler._Animation] objects to add to the animator. [br]
## [br]
## Example:
## [codeblock]
## @onready var target_node: Control = $TargetNode
## var animator
##
## func _ready():
##     animator = AnimationHandler.animator([
##         AnimationHandler.animation(
##             "Example-Animation",
##             AnimationHandler.timeline(
##                 target_node,
##                 "position",
##                 [
##                     AnimationHandler.keyframe(0, Vector2(16, 16)),
##                     AnimationHandler.keyframe(1, Vector2(64, 64))
##                 ]
##             )
##         )
##     ])
##
## func _process(delta: float):
##     animator.update(delta)
## [/codeblock]
func animator(animations: Array[_Animation]) -> _Animator:
	var oAnimator = _Animator.new()
	for ani in animations:
		oAnimator.addAnimation(ani)
	return oAnimator

## Creates a new animation object. [br]
## [br]
## [param animationName] Name of the animation. [br]
## [param timeline] A [_Timeline] object describing the animation's keyframes. [br]
## [br]
## Example:
## [codeblock]
## AnimationHandler.animation(
##     "MoveAnimation",
##     AnimationHandler.timeline($Node, "position", [
##         AnimationHandler.keyframe(0, Vector2(0, 0)),
##         AnimationHandler.keyframe(1, Vector2(100, 100))
##     ])
## )
## [/codeblock]
func animation(animationName: String, timelines: Array[_Timeline]) -> _Animation:
	return _Animation.new(animationName, timelines)

## Creates a timeline for an animation. [br]
## [br]
## [param target] The object whose property will be animated. [br]
## [param property] The name of the property (StringName) to modify. [br]
## [param keyframes] Array of [AnimationHandler._Keyframe] objects describing the animation steps. [br]
## [br]
## Example:
## [codeblock]
## signal animationEnded
##
## AnimationHandler.timeline($Control, "transform", [
##     AnimationHandler.keyframe(0, Vector2(16, 16), 0.5),
##     AnimationHandler.keyframe(1, Vector2(64, 64), 1.0, animationEnded)
## ])
## [/codeblock]
func timeline(target: Object, property: String, keyframes: Array[_Keyframe]) -> _Timeline:
	return _Timeline.new(target, property, keyframes)

## Creates a keyframe for an animation. [br]
## [br]
## [param time] The timestamp (in seconds or ticks) at which the value is set. [br]
## [param value] The value to apply to the property at the specified time. [br]
## [param easing] The easing curve (1.0 — linear, >1 — ease-in, <1 — ease-out). [br]
## [param event] Optional [Signal] to emit when the animation reaches this keyframe. [br]
## [br]
## Example:
## [codeblock]
## AnimationHandler.keyframe(1, Color.RED, 1.0, my_signal)
## [/codeblock]
func keyframe(time: int, value: Variant, easing: float = 1.0, signalObject: Object = Object, signalName: String = "") -> _Keyframe:
	return _Keyframe.new(time, value, easing, signalObject, signalName)

## Main

func _ready() -> void:
	print("[AnimationHandler] Loaded.")
