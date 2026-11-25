"""Author the small editable meadow test scene with terrain, elevation and NPCs."""

from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[2]


def build():
    resources = []
    nodes = []
    serial = 0

    def resource(kind, properties):
        nonlocal serial
        serial += 1
        name = f"{kind}_{serial}"
        resources.append(f'[sub_resource type="{kind}" id="{name}"]\n{properties}\n')
        return f'SubResource("{name}")'

    def node(name, kind, parent=".", properties=""):
        nodes.append(
            f'[node name="{name}" type="{kind}" parent="{parent}"]\n{properties}\n'
        )

    def material(colour):
        rgb = tuple(int(colour[i : i + 2], 16) / 255 for i in (0, 2, 4))
        return resource(
            "StandardMaterial3D",
            f"albedo_color = Color({rgb[0]}, {rgb[1]}, {rgb[2]}, 1)\nroughness = 1.0",
        )

    colours = {
        key: material(value)
        for key, value in {
            "earth": "6f5540",
            "rock": "777f76",
            "wood": "644832",
            "lightwood": "a57b4e",
            "leaf": "4e813e",
            "lightleaf": "6e9b48",
            "cream": "eee3b9",
            "red": "aa524d",
            "stone": "b3b6a0",
        }.items()
    }

    def box(name, position, size, colour, collision=False, parent=".", rotation=None):
        mesh = resource(
            "BoxMesh", f"size = Vector3{size}\nmaterial = {colours[colour]}"
        )
        props = f"position = Vector3{position}\nmesh = {mesh}"
        if rotation:
            props += f"\nrotation = Vector3{rotation}"
        node(name, "MeshInstance3D", parent, props)
        if collision:
            path = name if parent == "." else parent + "/" + name
            shape = resource("BoxShape3D", f"size = Vector3{size}")
            node("Body", "StaticBody3D", path)
            node("Shape", "CollisionShape3D", path + "/Body", f"shape = {shape}")

    def plane(name, position, size, parent="."):
        mesh = resource("PlaneMesh", f"size = Vector2{size}")
        node(
            name,
            "MeshInstance3D",
            parent,
            f'position = Vector3{position}\nmesh = {mesh}\nmaterial_override = ExtResource("1_ground")',
        )

    def sphere(name, position, radius, colour, parent="."):
        mesh = resource(
            "SphereMesh",
            f"radius = {radius}\nheight = {radius * 2}\nradial_segments = 10\nrings = 5\nmaterial = {colours[colour]}",
        )
        node(
            name,
            "MeshInstance3D",
            parent,
            f"position = Vector3{position}\nmesh = {mesh}",
        )

    box("Island", (0, -0.2, 0), (12, 0.4, 10), "earth", True)
    plane("Meadow", (0, 0.004, 0), (12, 10))
    box("RaisedClearing", (0, 0.3, -2.5), (5, 0.6, 3), "rock", True)
    plane("RaisedMeadow", (0, 0.605, -2.5), (5, 3))

    # The ramp surface joins ground and plateau continuously; its underside is embedded.
    angle = math.atan2(0.6, 1.8)
    box(
        "Ramp",
        (0, 0.3 - 0.1 * math.cos(angle), -0.1 - 0.1 * math.sin(angle)),
        (1.6, 0.2, math.hypot(1.8, 0.6)),
        "lightwood",
        True,
        rotation=(angle, 0, 0),
    )
    for index in range(10):
        z = 0.8 - (index + 0.5) * 1.8 / 10
        y = (0.8 - z) / 3 + 0.006
        box(
            f"RampPlank{index}",
            (0, y, z),
            (1.56, 0.012, 0.15),
            "wood" if index % 2 else "lightwood",
            rotation=(angle, 0, 0),
        )

    for index, (x, z) in enumerate(
        [(-5, -4), (-4.7, 3.8), (4.8, -3.7), (4.8, 2.8), (-1.4, 4.1), (2.8, 3.9)]
    ):
        node(f"Tree{index}", "Node3D", properties=f"position = Vector3({x}, 0, {z})")
        box("Trunk", (0, 0.35, 0), (0.14, 0.7, 0.14), "wood", True, f"Tree{index}")
        sphere("Crown", (0, 0.98, 0), 0.53, "leaf", f"Tree{index}")
        sphere("CrownLight", (-0.22, 1.1, -0.08), 0.34, "lightleaf", f"Tree{index}")

    for index, (x, z) in enumerate(
        [(-2.7, -1), (-4.5, -1.4), (-3, -3.5), (3.7, -1.4), (3.4, 1.5), (-4.2, 2.7)]
    ):
        sphere(f"Rock{index}", (x, 0.1, z), 0.18 + (index % 2) * 0.06, "rock")

    node("Market", "Node3D", properties="position = Vector3(-3, 0, 1.1)")
    box("Counter", (0, 0.1, 0.08), (1.35, 0.2, 0.3), "lightwood", True, "Market")
    for index, x in enumerate([-0.75, 0.75]):
        box(
            f"Post{index}", (x, 0.4, -0.32), (0.065, 0.8, 0.065), "wood", True, "Market"
        )
    for index in range(8):
        box(
            f"Canopy{index}",
            (-0.7 + index * 0.2, 0.82, -0.25),
            (0.2, 0.04, 0.85),
            "red" if index % 2 else "cream",
            parent="Market",
            rotation=(-0.08, 0, 0),
        )
    for index in range(3):
        box(
            f"CardBox{index}",
            (-0.45 + index * 0.35, 0.23, 0.1),
            (0.16, 0.06, 0.12),
            "red" if index % 2 else "wood",
            parent="Market",
        )
    nodes.append(
        '[node name="Shopkeeper" parent="Market" instance=ExtResource("2_shopkeeper")]\nposition = Vector3(0, 0.14, 0.5)\n'
    )
    box("SupplyCrate", (-4.1, 0.13, 1.2), (0.33, 0.26, 0.33), "lightwood", True)
    nodes.append(
        '[node name="Rival" parent="." instance=ExtResource("3_rival")]\nposition = Vector3(1.25, 0.74, -2.5)\n'
    )
    for index in range(10):
        theta = index * math.tau / 10
        sphere(
            f"ClearingStone{index}",
            (1.25 + math.cos(theta) * 0.65, 0.62, -2.5 + math.sin(theta) * 0.65),
            0.045,
            "stone",
        )
    box("BannerPole", (2.1, 1.05, -3.4), (0.035, 0.9, 0.035), "wood")
    box("RivalBanner", (2.23, 1.25, -3.4), (0.26, 0.3, 0.025), "red")

    # Low boundary rocks hide the static collision walls around the test island.
    for name, position, size in [
        ("NorthBoundary", (0, 0.1, -4.8), (12, 0.5, 0.2)),
        ("SouthBoundary", (0, 0.1, 4.8), (12, 0.5, 0.2)),
        ("WestBoundary", (-5.8, 0.1, 0), (0.2, 0.5, 10)),
        ("EastBoundary", (5.8, 0.1, 0), (0.2, 0.5, 10)),
    ]:
        box(name, position, size, "rock", True)

    node("PlayerSpawn", "Marker3D", properties="position = Vector3(0, 0.15, 3.1)")
    environment = resource(
        "Environment",
        "background_mode = 1\nbackground_color = Color(0.51, 0.65, 0.69, 1)\nambient_light_source = 3\nambient_light_color = Color(0.86, 0.91, 1, 1)\nambient_light_energy = 0.45\ntonemap_mode = 0",
    )
    node(
        "WorldEnvironment",
        "WorldEnvironment",
        properties=f"environment = {environment}",
    )
    node(
        "Sun",
        "DirectionalLight3D",
        properties="rotation_degrees = Vector3(-55, -25, 0)\nlight_color = Color(1, 0.92, 0.78, 1)\nlight_energy = 0.65\nshadow_enabled = true",
    )

    header = [
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Material" path="res://Resources/Terrain/meadow_ground.tres" id="1_ground"]',
        '[ext_resource type="PackedScene" path="res://Scenes/Shopkeeper.tscn" id="2_shopkeeper"]',
        '[ext_resource type="PackedScene" path="res://Scenes/Enemies/Rival.tscn" id="3_rival"]',
        "",
    ]
    text = (
        "\n".join(header)
        + "\n".join(resources)
        + '\n[node name="MeadowTest" type="Node3D"]\n\n'
        + "\n".join(nodes)
    )
    (ROOT / "Scenes/Environments/MeadowTest.tscn").write_text(text)


if __name__ == "__main__":
    build()
