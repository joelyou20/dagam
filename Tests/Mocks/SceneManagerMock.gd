extends SceneManager
class_name SceneManagerMock

var last_scene_path := ""
var last_spawn_point := ""

func transition_to_scene(path: String, spawn_point_name: String = "PlayerSpawn"):
	last_scene_path = path
	last_spawn_point = spawn_point_name
