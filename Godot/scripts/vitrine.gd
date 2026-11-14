extends Node2D
## Vitrine para conferir os bonecos 3D de perto (cena de teste).
var views := []
var estados := ["idle", "run", "ar", "atk"]
var k := 0
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#2a2540"))
	for i in 3:
		var v := HeroView.new(GameData.CLASSES[i])
		v.position = Vector2(90 + i * 150, 230)
		v.scale = Vector2(4, 4)
		add_child(v)
		views.append(v)
func _physics_process(_d: float) -> void:
	k += 1
	for v in views:
		v.boneco.estado = estados[(k / 120) % 4]
		v.boneco.t = fmod(k / 60.0, 0.54)
		v.animar(1.0 / 60.0)
