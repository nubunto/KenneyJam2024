extends Area3D

func _on_body_entered(body: Node3D):
	if body.has_method("player_died"):
		body.player_died()
