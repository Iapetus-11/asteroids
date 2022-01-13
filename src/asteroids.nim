import std/[math]
import nico

type
  PVec2 = ref object
    x: PFloat
    y: PFloat

  Ship = ref object
    pos: PVec2  # center of ship
    mov: PVec2
    rot: Pfloat
    rotMov: Pfloat
    bulletCooldown: Pint

  Bullet = ref object
    pos: PVec2 # the front of the bullet
    mov: PVec2
    rot: Pfloat

  Asteroid = ref object
    pos: PVec2
    mov: PVec2
    rot: Pfloat
    radius: PFloat

const
  WINDOW_X = 512
  WINDOW_Y = 512

  FPS = 30

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

proc `/=`(a: PVec2, b: Pfloat) =
  a.x = a.x / b
  a.y = a.y / b

proc rot(p: PVec2, deg: Pfloat): PVec2 =
  let rad = degToRad(deg)

  return vec2(p.x * cos(rad) - p.y * sin(rad), p.x * sin(rad) + p.y * cos(rad))

proc newShip(): Ship =
  return Ship(pos: vec2(0.0, 0.0), mov: vec2(0.0, 0.0), rot: 0.0, bulletCooldown: 0)

proc newBullet(ship: Ship): Bullet =
  return Bullet(
    pos: rot(vec2(0, 10), ship.rot) + ship.pos,
    mov: rot(vec2(0, 10), ship.rot) + ship.mov,
    rot: ship.rot,
  )

var
  ship: Ship
  bullets: seq[Bullet]
  asteroids: seq[Asteroid]

proc updateShip() =
  if key(KeyCode.K_LEFT):
    if ship.rotMov > -20:
      ship.rotMov -= 10
  
  if key(KeyCode.K_RIGHT):
    if ship.rotMov < 20:
      ship.rotMov += 10

  if key(KeyCode.K_UP):
    let f = rot(vec2(0, 3), ship.rot)

    ship.mov.x += f.x
    ship.mov.y += f.y
    
  if key(KeyCode.K_DOWN):
    let f = rot(vec2(0, -3), ship.rot)

    ship.mov.x += f.x
    ship.mov.y += f.y

  if key(KeyCode.K_SPACE):
    if ship.bulletCooldown < 1:
      bullets.add(newBullet(ship))
      ship.bulletCooldown += 15

  if ship.bulletCooldown > -30:  # allows ships to build up a burst of bullets
    ship.bulletCooldown -= 1

  ship.rot += ship.rotMov
  
  if ship.rotMov.abs < 0.15:
    ship.rotMov = 0
  else:
    ship.rotMov = ship.rotMov / 2

  ship.mov.x = min(ship.mov.x.abs, 8).copySign(ship.mov.x)
  ship.mov.y = min(ship.mov.y.abs, 8).copySign(ship.mov.y)

  if ship.pos.x + ship.mov.x < 0:
    ship.pos.x = WINDOW_X
  elif ship.pos.x + ship.mov.x > WINDOW_X:
    ship.pos.x = 0

  if ship.pos.y + ship.mov.y < 0:
    ship.pos.y = WINDOW_Y
  elif ship.pos.y + ship.mov.y > WINDOW_Y:
    ship.pos.y = 0

  ship.pos.x += ship.mov.x
  ship.pos.y += ship.mov.y

  ship.mov /= 1.05

proc updateBullets() =
  if bullets.len == 0:
    return

  var newBullets: seq[Bullet]

  for b in bullets:
    if not (b.pos.x < 0 or b.pos.x > WINDOW_X or b.pos.y < 0 or b.pos.y > WINDOW_Y):
      b.pos += b.mov
      newBullets.add(b)

  bullets = newBullets

proc gameInit() =
  ship = newShip()
  ship.pos.x = WINDOW_X / 2
  ship.pos.y = WINDOW_Y / 2

  bullets.setLen(0)

  setPalette(loadPaletteCGA())

proc gameUpdate(dt: float32) =
  if key(KeyCode.K_ESCAPE):
    nico.shutdown()
  
  if key(KeyCode.K_R):
    gameInit()

  updateShip()
  updateBullets()
    
proc gameDraw() =
  cls()

  let
    a = rot(vec2(0, 10), ship.rot) + ship.pos
    b = rot(vec2(-5, -5), ship.rot) + ship.pos
    c = rot(vec2(5, -5), ship.rot) + ship.pos
  
  # draw ship
  setColor(3)
  trifill(a.x, a.y, b.x, b.y, c.x, c.y)

  # draw bullets
  setColor(1) # cyan
  for b in bullets:
    let o = rot(vec2(0, -5), b.rot) + b.pos
    line(o.x, o.y, b.pos.x, b.pos.y)

  # draw asteroids
  setColor(3)
  for a in asteroids:
    circ(a.pos.x, a.pos.y, a.radius)

nico.timeStep = 1 / FPS
nico.init("me.iapetus11", "asteroids")
nico.createWindow("Asteroids", WINDOW_X, WINDOW_Y, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)
