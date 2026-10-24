extends SceneTree
func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size()!=1:
		printerr("Expected output directory")
		quit(1)
		return
	var directory := arguments[0]
	var license_file := FileAccess.open(directory.path_join("GODOT-LICENSE.txt"),FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	var notices := {"copyright":Engine.get_copyright_info(),"licenses":Engine.get_license_info()}
	var notices_file := FileAccess.open(directory.path_join("GODOT-THIRD-PARTY-NOTICES.json"),FileAccess.WRITE)
	notices_file.store_string(JSON.stringify(notices,"  "))
	print("RUNTIME_NOTICES: written from bundled engine")
	quit()
