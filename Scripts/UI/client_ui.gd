class_name NetworkUI extends Control

func _on_server_pressed() -> void:
	NetworkHandler.start_server()
	hide()

func _on_client_pressed() -> void:
	NetworkHandler.start_client("local_host")
	hide()

func _on_host_pressed() -> void:
	NetworkHandler.start_host()
	hide()
