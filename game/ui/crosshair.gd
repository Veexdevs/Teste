extends Control

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    if G.hud != null:
        G.hud.paint_crosshair(self)
