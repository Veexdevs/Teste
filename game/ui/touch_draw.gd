extends Control

func _draw() -> void:
    if G.touch != null:
        G.touch.paint(self)
