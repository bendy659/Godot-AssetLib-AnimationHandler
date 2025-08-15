@tool
extends EditorPlugin

const animationHandler: Dictionary = {
	"name": "AnimationHandler",
	"path": "res://addons/animationHandler/AnimationHandler.gd"
}

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_autoload_singleton(animationHandler["name"], animationHandler["path"])


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(animationHandler["name"])
