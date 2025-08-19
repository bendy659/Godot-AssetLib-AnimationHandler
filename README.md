# Godot-AssetLib | AnimationHandler
A lightweight, code-driven animation system for Godot. Perfect for dynamics, runtime, and plugin-based animations without the AnimationPlayer.

---

# Example

```gd
extends Control

@onready var target = $ColorRect
@onready var label = $Label

var animator
var cTime: float = 0.0

signal on_ended

func _ready() -> void:
	on_ended.connect(onEnded)
	
	animator = AnimationHandler.animator([
		AnimationHandler.animation("EXAMPLE", [
			AnimationHandler.timeline(target, "position.x", [
				AnimationHandler.keyframe(0, 181, -1.5),
				AnimationHandler.keyframe(4, 1280 - 181)
			]),
			AnimationHandler.timeline(target, "position.y", [
				AnimationHandler.keyframe(0, 539, 0.5),
				AnimationHandler.keyframe(2, 539 - 256, 2.0),
				AnimationHandler.keyframe(4, 539)
			]),
			AnimationHandler.timeline(target, "rotation_degrees", [
				AnimationHandler.keyframe(0, 0),
				AnimationHandler.keyframe(4, 360 * 2)
			]),
			AnimationHandler.timeline(target, "color", [
				AnimationHandler.keyframe(0, Color(1, 0, 0)),
				AnimationHandler.keyframe(1, Color(1, 1, 0)),
				AnimationHandler.keyframe(2, Color(0, 1, 0)),
				AnimationHandler.keyframe(3, Color(0, 1, 1)),
				AnimationHandler.keyframe(4, Color(0, 0, 1)),
				AnimationHandler.keyframe(5, Color(1, 0, 1), 1.0, self, "on_ended")
			])
		])
	])
	await Game.wait(2)
	
	animator.timeScale = 2
	animator.play("EXAMPLE", true)

func _process(delta: float) -> void:
	cTime += delta
	
	if animator:
		animator.update(delta)
	
	label.text = """
		%.2f
		Animator-Current-Time: %s
		Animator-Playing: %s
		Animator-Max-Time: %s
	""" % [cTime, animator.cTime, animator.playing, animator.mTime]

func onEnded():
	label.text = "OK"

```

----

```gd
AnimationHandler.animator(
	animations: AnimationHandler._Animation
) -> AnimationHandler._Animator
```

* Creates and returns an Animator  
* Parameters:  
\\- animations – list of animations to handle  

---

```gd
AnimationHandler.animation(
	animationName: String,
	timelines: Array[AnimationHandler._Timeline]
) -> AnimationHandler._Animation
```

* Creates and returns an Animation  
* Parameters:  
|- animationName – name of the animation  
\\- timelines – array of timelines  

---

```gd
AnimationHandler.timeline(
	target: Object,
	propertyPath: String,
	keyframes: AnimationHandler._Keyframes
) -> AnimationHandler._Timeline
```

* Creates and returns a Timeline  
* Parameters:  
|- target – object to animate  
|- propertyPath – property to animate  
\\- keyframes – list of keyframes  

---

```gd
AnimationHandler.keyframe(
	time: float,
	value: Variant,
	easing: float,
	signalObject: Object = null,
	signalName: String = ""
) -> AnimationHandler._Keyframe
```

* Creates and returns a Keyframe  
* Parameters:  
|- time – keyframe time    
|- value – value at this time  
|- easing – easing factor (like in AnimationPlayer)  
|- signalObject – optional, object to emit signal from  
\\- signalName – optional, name of the signal  
