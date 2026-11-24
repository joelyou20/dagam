extends SceneTree

func _initialize():
	var runtime = ClassDB.instantiate("HexRuntime")

	assert(runtime != null)
	assert(
		(
			runtime.evaluate("JSON.stringify({answer:21*2,modern:[1,2].at(-1)})")
			== '{"answer":42,"modern":2}'
		)
	)
	print("Native runtime OK")
	quit()
