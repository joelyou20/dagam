extends SceneManager
class_name SceneManagerMock

var last_scene_path := ""
var last_spawn_point := ""

func load_scene(path: String, should_fade_out: bool = true, should_fade_in: bool = true, spawn_point_name: String = "PlayerSpawn", fade_speed: float = 1.0):
	last_scene_path = path
	last_spawn_point = spawn_point_name
