import nico
import math

type
  PVec2 = ref object
    x: PFloat
    y: PFloat

  Ship = ref object
    pos: PVec2
    mov: PVec2
    rot: Pfloat
    rotMov: Pfloat

const
  WINDOW_X = 512
  WINDOW_Y = 512

proc vec2(x: Pfloat, y: PFloat): PVec2 =
  return PVec2(x: x, y: y)

proc `$`(p: PVec2): string =
  return "(" & $p.x & "," & $p.y & ")"

proc `+`(a: PVec2, b: PVec2): PVec2 =
  return vec2(a.x + b.x, a.y + b.y)

proc newShip(): Ship =
  return Ship(pos: vec2(0.0, 0.0), mov: vec2(0.0, 0.0), rot: 0.0)

proc rot(p: PVec2, deg: Pfloat): PVec2 =
  let rad = degToRad(deg)

  return vec2(p.x * cos(rad) - p.y * sin(rad), p.x * sin(rad) + p.y * cos(rad))

init("me.iapetus11", "asteroids")

var
  ship = newShip()

proc gameInit() =
  ship.pos.x = WINDOW_X / 2
  ship.pos.y = WINDOW_Y / 2
  ship.rot = 0

  setPalette(loadPaletteCGA())

proc gameUpdate(dt: float32) =
  var
    movInput = false

  if btn(NicoButton.pcLeft):
    if ship.rotMov > -20:
      ship.rotMov -= 5

    movInput = true
  
  if btn(NicoButton.pcRight):
    if ship.rotMov < 20:
      ship.rotMov += 5

    movInput = true

  if btn(NicoButton.pcUp):
    if ship.mov.y < 10:
      let f = rot(vec2(0, 5), ship.rot)

      ship.mov.x += f.x
      ship.mov.y += f.y

    movInput = true
    
  if btn(NicoButton.pcDown):
    if ship.mov.y > -10:
      let f = rot(vec2(0, -5), ship.rot)

      ship.mov.x += f.x
      ship.mov.y += f.y

    movInput = true

  ship.rot += ship.rotMov

  ship.pos.x += ship.mov.x
  ship.pos.y += ship.mov.y
  
  if ship.rotMov.abs > 3:
    ship.rotMov -= 3.copySign(ship.rotMov)
    
proc gameDraw() =
  cls()

  let
    a = rot(vec2(0, 10), ship.rot) + ship.pos
    b = rot(vec2(-5, -5), ship.rot) + ship.pos
    c = rot(vec2(5, -5), ship.rot) + ship.pos
  
  setColor(3)
  trifill(
    a.x,
    a.y,
    b.x,
    b.y,
    c.x,
    c.y,
  )

nico.createWindow("Asteroids", WINDOW_X, WINDOW_Y, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)
