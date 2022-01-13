import nico
import math
import os

type
  PVec2 = ref object
    x: PFloat
    y: PFloat

  Ship = ref object
    pos: PVec2
    mov: PVec2
    rot: Pfloat
    rotMov: Pfloat

  Bullet = ref object
    pos: PVec2 # the front of the bullet
    mov: PVec2
    rot: Pfloat

const
  WINDOW_X = 512
  WINDOW_Y = 512
  FPS = 30
  SPF = 1 / FPS

proc vec2(x: Pfloat, y: PFloat): PVec2 =
  return PVec2(x: x, y: y)

proc `$`(p: PVec2): string =
  return "(" & $p.x & "," & $p.y & ")"

proc `$`(b: Bullet): string =
  return "Bullet<" & $b.pos & "," & $b.mov & "," & $b.rot & ">"

proc `+`(a: PVec2, b: PVec2): PVec2 =
  return vec2(a.x + b.x, a.y + b.y)

proc `+=`(a: PVec2, b: PVec2) =
  a.x += b.x
  a.y += b.y

proc rot(p: PVec2, deg: Pfloat): PVec2 =
  let rad = degToRad(deg)

  return vec2(p.x * cos(rad) - p.y * sin(rad), p.x * sin(rad) + p.y * cos(rad))

proc newShip(): Ship =
  return Ship(pos: vec2(0.0, 0.0), mov: vec2(0.0, 0.0), rot: 0.0)

proc newBullet(ship: Ship): Bullet =
  return Bullet(
    pos: rot(vec2(0, 10), ship.rot) + ship.pos,
    mov: rot(vec2(0, 10), ship.rot) + ship.mov,
    rot: ship.rot,
  )

var
  ship = newShip()
  bullets: seq[Bullet]
  frameCounter = 0

proc gameInit() =
  ship.pos.x = WINDOW_X / 2
  ship.pos.y = WINDOW_Y / 2
  ship.rot = 0

  setPalette(loadPaletteCGA())

proc gameUpdate(dt: float32) =
  var
    movInput = false

  if key(KeyCode.K_LEFT):
    if ship.rotMov > -20:
      ship.rotMov -= 10

    movInput = true
  
  if key(KeyCode.K_RIGHT):
    if ship.rotMov < 20:
      ship.rotMov += 10

    movInput = true

  if key(KeyCode.K_UP):
    let f = rot(vec2(0, 3), ship.rot)

    ship.mov.x += f.x
    ship.mov.y += f.y

    movInput = true
    
  if key(KeyCode.K_DOWN):
    let f = rot(vec2(0, -3), ship.rot)

    ship.mov.x += f.x
    ship.mov.y += f.y

    movInput = true

  if key(KeyCode.K_SPACE):
    bullets.add(newBullet(ship))

  ship.rot += ship.rotMov
  
  if ship.rotMov.abs < 0.15:
    ship.rotMov = 0
  else:
    ship.rotMov = ship.rotMov / 2

  ship.mov.x = min(ship.mov.x.abs, 8).copySign(ship.mov.x)
  ship.mov.y = min(ship.mov.y.abs, 8).copySign(ship.mov.y)

  ship.pos.x += ship.mov.x
  ship.pos.y += ship.mov.y

  for b in bullets:
    b.pos += b.mov

  sleep((SPF - dt).int)
    
proc gameDraw() =
  cls()

  let
    a = rot(vec2(0, 10), ship.rot) + ship.pos
    b = rot(vec2(-5, -5), ship.rot) + ship.pos
    c = rot(vec2(5, -5), ship.rot) + ship.pos
  
  # draw ship
  setColor(3) # white
  trifill(a.x, a.y, b.x, b.y, c.x, c.y)

  # draw bullets
  setColor(1) # cyan
  for b in bullets:
    let o = rot(vec2(0, -5), b.rot) + b.pos
    line(o.x, o.y, b.pos.x, b.pos.y)

nico.init("me.iapetus11", "asteroids")
nico.createWindow("Asteroids", WINDOW_X, WINDOW_Y, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)
