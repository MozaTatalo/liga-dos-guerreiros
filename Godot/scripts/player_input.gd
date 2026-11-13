class_name PlayerInput
extends RefCounted
## Fonte de comandos de um jogador. Hoje lê o teclado (ações "p1_*").
## Para multijogador: crie outra instância com prefixo "p2_" (controle/teclado)
## ou uma subclasse que receba os comandos pela rede.

var prefix := "p1_"

func _init(p := "p1_") -> void:
	prefix = p

func held(action: String) -> bool:
	return Input.is_action_pressed(prefix + action)

func tapped(action: String) -> bool:
	return Input.is_action_just_pressed(prefix + action)
