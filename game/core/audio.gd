extends Node
## Banco de audio 100% sintetizado em runtime (PCM16 / AudioStreamWAV).

const RATE = 22050
var streams = {}
var pool2d: Array = []
var pool3d: Array = []
var next2d = 0
var next3d = 0
var ambient: AudioStreamPlayer

func _ready() -> void:
    for i in range(14):
        var p = AudioStreamPlayer.new()
        p.bus = "Master"
        add_child(p)
        pool2d.append(p)
    for i in range(10):
        var p3 = AudioStreamPlayer3D.new()
        p3.bus = "Master"
        p3.max_distance = 85.0
        p3.unit_size = 6.0
        p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        add_child(p3)
        pool3d.append(p3)
    ambient = AudioStreamPlayer.new()
    ambient.bus = "Master"
    ambient.volume_db = -26.0
    add_child(ambient)

func _pcm(samples: PackedFloat32Array) -> PackedByteArray:
    var out = PackedByteArray()
    out.resize(samples.size() * 2)
    for i in range(samples.size()):
        var v = clampf(samples[i], -1.0, 1.0)
        var iv = int(v * 32767.0)
        if iv < 0:
            iv += 65536
        out[i * 2] = iv & 255
        out[i * 2 + 1] = (iv >> 8) & 255
    return out

func _make(key: String, dur: float, fn: Callable) -> AudioStreamWAV:
    var n = int(dur * RATE)
    var buf = PackedFloat32Array()
    buf.resize(n)
    buf.fill(0.0)
    fn.call(buf, n)
    var s = AudioStreamWAV.new()
    s.format = AudioStreamWAV.FORMAT_16_BITS
    s.mix_rate = RATE
    s.stereo = false
    s.loop_mode = AudioStreamWAV.LOOP_DISABLED
    s.data = _pcm(buf)
    streams[key] = s
    return s

func _noise(lp: float, state: Array) -> float:
    var w = randf() * 2.0 - 1.0
    state[0] = state[0] * lp + w * (1.0 - lp)
    return state[0]

func _gun(buf: PackedFloat32Array, n: int, power: float, body: float, tail: float, crack: float) -> void:
    var st = [0.0]
    var st2 = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        var env = exp(-t / body)
        var w = _noise(0.42, st)
        var low = _noise(0.955, st2)
        var thump = sin(2.0 * PI * (72.0 - t * 90.0) * t) * exp(-t / 0.11) * 0.55
        var cr = 0.0
        if t < 0.004:
            cr = (randf() * 2.0 - 1.0) * crack * (1.0 - t / 0.004)
        var tailv = _noise(0.86, st) * exp(-maxf(t - 0.06, 0.0) / tail) * 0.22
        buf[i] = clampf((w * 0.55 + low * 0.55 + thump + cr + tailv) * env * power, -1.0, 1.0)

func _click(buf: PackedFloat32Array, n: int, count: int, gap: float, tone: float) -> void:
    var st = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        var v = 0.0
        for c in range(count):
            var ct = c * gap
            if t >= ct and t < ct + 0.045:
                var lt = t - ct
                v += (_noise(0.20, st) * 0.8 + sin(2.0 * PI * tone * lt) * 0.35) * exp(-lt / 0.012)
        buf[i] = clampf(v * 0.55, -1.0, 1.0)

func _tone(buf: PackedFloat32Array, n: int, freq: float, dur: float, sweep: float) -> void:
    for i in range(n):
        var t = float(i) / RATE
        if t > dur:
            continue
        var f = freq + sweep * (t / dur)
        buf[i] = sin(2.0 * PI * f * t) * sin(PI * minf(t / dur, 1.0)) * 0.45

func _thud(buf: PackedFloat32Array, n: int, freq: float, dur: float) -> void:
    var st = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        buf[i] = clampf((sin(2.0 * PI * (freq * (1.0 - t * 0.8)) * t) * 0.55 + _noise(0.90, st) * 0.85) * exp(-t / (dur * 0.32)) * 0.8, -1.0, 1.0)

func _ricochet(buf: PackedFloat32Array, n: int) -> void:
    var st = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        buf[i] = clampf((sin(2.0 * PI * (2600.0 - t * 9000.0) * t) * 0.5 + _noise(0.1, st) * 0.3) * exp(-t / 0.05), -1.0, 1.0)

func _boom(buf: PackedFloat32Array, n: int, dur: float) -> void:
    var st = [0.0]
    var st2 = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        var env = exp(-t / (dur * 0.30))
        buf[i] = clampf((_noise(0.975, st2) * 1.5 + _noise(0.55, st) * 0.7 * exp(-t / (dur * 0.55)) + sin(2.0 * PI * (55.0 - t * 12.0) * t) * 0.9) * env * 0.85, -1.0, 1.0)

func _wind(buf: PackedFloat32Array, n: int, dur: float) -> void:
    var st = [0.0]
    var st2 = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        var gust = 0.55 + 0.45 * sin(t * 1.7) * sin(t * 0.43 + 1.2)
        buf[i] = clampf((_noise(0.992, st) * 1.5 + _noise(0.90, st2) * 0.5) * gust * 0.22, -1.0, 1.0)

func _radio(buf: PackedFloat32Array, n: int, dur: float) -> void:
    var st = [0.0]
    for i in range(n):
        var t = float(i) / RATE
        var syllable = sin(2.0 * PI * 3.1 * t) * 0.5 + 0.5
        var env = sin(PI * minf(t / dur, 1.0))
        buf[i] = clampf((sin(2.0 * PI * (430.0 + 70.0 * sin(t * 24.0)) * t) * 0.45 + _noise(0.65, st) * 0.32) * syllable * env * 0.55, -1.0, 1.0)

func build_all() -> void:
    if streams.size() > 0:
        return
    _make("rifle", 0.42, func(b, n): _gun(b, n, 0.95, 0.055, 0.13, 0.9))
    _make("rifle_heavy", 0.50, func(b, n): _gun(b, n, 1.0, 0.068, 0.18, 1.0))
    _make("smg", 0.32, func(b, n): _gun(b, n, 0.80, 0.038, 0.09, 0.75))
    _make("sniper", 0.75, func(b, n): _gun(b, n, 1.0, 0.085, 0.28, 1.15))
    _make("pistol", 0.34, func(b, n): _gun(b, n, 0.82, 0.042, 0.10, 0.8))
    _make("step", 0.16, func(b, n): _thud(b, n, 115.0, 0.10))
    _make("reload", 0.85, func(b, n): _click(b, n, 3, 0.26, 820.0))
    _make("empty", 0.10, func(b, n): _click(b, n, 1, 0.0, 1400.0))
    _make("impact", 0.16, func(b, n): _thud(b, n, 240.0, 0.045))
    _make("ricochet", 0.30, func(b, n): _ricochet(b, n))
    _make("hit", 0.09, func(b, n): _tone(b, n, 1250.0, 0.055, 350.0))
    _make("ui", 0.10, func(b, n): _tone(b, n, 660.0, 0.07, 180.0))
    _make("beep", 0.14, func(b, n): _tone(b, n, 940.0, 0.10, 0.0))
    _make("radio", 0.95, func(b, n): _radio(b, n, 0.90))
    _make("boom", 1.70, func(b, n): _boom(b, n, 1.60))
    _make("plant", 0.30, func(b, n): _click(b, n, 2, 0.13, 560.0))
    _make("wind", 2.60, func(b, n): _wind(b, n, 2.60))
    _make("amb", 4.00, func(b, n): _wind(b, n, 4.00))
    var a: AudioStreamWAV = streams["amb"]
    a.loop_mode = 1
    a.loop_begin = 0
    a.loop_end = int(4.00 * RATE) - 1
    _make("build", 0.55, func(b, n): _thud(b, n, 90.0, 0.30))
    G.note("audio: %d amostras sintetizadas" % streams.size())

func get_stream(key: String) -> AudioStreamWAV:
    if not streams.has(key):
        build_all()
    return streams.get(key)

func play_ambient() -> void:
    if ambient == null:
        return
    var s = get_stream("amb")
    if s == null or ambient.playing:
        return
    ambient.stream = s
    ambient.volume_db = -26.0
    ambient.play()

func play(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    var s = get_stream(key)
    if s == null:
        return
    var p: AudioStreamPlayer = pool2d[next2d % pool2d.size()]
    next2d += 1
    p.stream = s
    p.volume_db = volume_db
    p.pitch_scale = pitch
    p.play()

func play_at(key: String, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    var s = get_stream(key)
    if s == null:
        return
    var p: AudioStreamPlayer3D = pool3d[next3d % pool3d.size()]
    next3d += 1
    if G.player != null and is_instance_valid(G.player):
        volume_db -= clampf(G.player.global_position.distance_to(pos) * 0.09, 0.0, 18.0)
    p.stream = s
    p.global_position = pos
    p.volume_db = volume_db
    p.pitch_scale = pitch
    p.play()
