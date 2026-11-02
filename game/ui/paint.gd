extends Control
## Control genérico de desenho do HUD. O `kind` escolhe o que pintar.

var kind = ""

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    if G.hud == null:
        return
    match kind:
        "minimap": G.hud.paint_minimap(self)
        "crosshair": G.hud.paint_crosshair(self)
        "weapon": G.hud.paint_weapon(self)
        "vitals": G.hud.paint_vitals(self)
        "radar": G.hud.paint_radar(self)
        "score": G.hud.paint_score(self)
        "compass": G.hud.paint_compass(self)
