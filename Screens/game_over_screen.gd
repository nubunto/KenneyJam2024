extends Control

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_visibility_changed():
	if visible:
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
