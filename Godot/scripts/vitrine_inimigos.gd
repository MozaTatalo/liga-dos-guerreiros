extends Node
## Cena de teste: inimigos 3D de perto, no cenário gótico (abra e aperte F6).
var cen: Cenario3D
var lista := []
var k := 0
func _ready() -> void:
	cen = Cenario3D.new(); add_child(cen)
	var tipos := [Espectro3D.new("saqueador"), Espectro3D.new("atirador"), Lodo3D.new(), Morcego3D.new(), Espectro3D.new("boss")]
	var xs := [5.2, 6.6, 7.9, 9.0, 11.0]
	for i in tipos.size():
		cen.add_child(tipos[i])
		tipos[i].position = Vector3(xs[i], 1.2 if tipos[i] is Morcego3D else 0.0, 0.0)
		lista.append(tipos[i])
func _process(dt: float) -> void:
	k += 1
	cen.cam_x = 8.0 * 26.0 - 240.0
	cen.queue_redraw()
	cen.cam.fov = 13.0
	cen.cam.position.y = 1.4
	for i in lista.size():
		var e: Inimigo3D = lista[i]
		e.lado = 1 if (k / 150) % 2 == 0 else -1
		e.preparo = 1.0 if (k / 90) % 3 == 2 else 0.0
		e.posar(dt)
