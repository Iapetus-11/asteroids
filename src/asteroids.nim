import nico

type
  Mat2 = array[2, array[2, Pfloat]]

  PVec2 = ref object
    x: PFloat
    y: PFloat

  Ship = ref object
    pos: PVec2
    mov: PVec2
    rot: Pfloat

const
  WINDOW_X = 512
  WINDOW_Y = 512

proc vec2(x: Pfloat, y: PFloat): PVec2 =
  return PVec2(x: x, y: y)

proc `$`(p: PVec2): string =
  return "(" & $p.x & "," & $p.y & ")"

proc newShip(): Ship =
  return Ship(pos: vec2(0.0, 0.0), mov: vec2(0.0, 0.0), rot: 0.0)

proc `*`(a: PVec2, b: Mat2): PVec2 =
  return vec2(a.x * b[0][0] + a.y * b[1][0], a.x * b[0][1] + a.y * b[1][1])

proc rotatePoint(p: PVec2, deg: Pfloat): PVec2 =
  if deg == 0:
    return p

  var r: Mat2

  let
    cosD = cos(deg)
    sinD = sin(deg)

  if deg < 0:  # clockwise
    r = [[cosD, -sinD], [-sinD, cosD]]
  else: # counterclockwise
    r = [[cosD, sinD], [sinD, cosD]]

  return p * r

init("me.iapetus11", "asteroids")

var
  ship = newShip()

proc gameInit() =
  ship.pos.x = WINDOW_X / 2
  ship.pos.y = WINDOW_Y / 2
  ship.rot = 0

  setPalette(loadPaletteCGA())

proc gameUpdate(dt: float32) =
  if btn(NicoButton.pcLeft):
    ship.rot -= 1
  
  if btn(NicoButton.pcRight):
    ship.rot += 1

proc gameDraw() =
  cls()

  let a = rotatePoint(vec2(ship.pos.x, ship.pos.y + 10), ship.rot)
  let b = rotatePoint(vec2(ship.pos.x - 5, ship.pos.y - 5), ship.rot)
  let c = rotatePoint(vec2(ship.pos.x + 5, ship.pos.y - 5), ship.rot)

  echo a, " | ", b, " | ", c
  
  setColor(3)
  trifill(a.x, a.y, b.x, b.y, c.x, c.y)

nico.createWindow("Asteroids", WINDOW_X, WINDOW_Y, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)
