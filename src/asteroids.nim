import std/[math, random, sets, hashes, sequtils]
import nico

randomize()

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

  Circle = ref object of RootObj
    pos: PVec2
    radius: PFloat

  Asteroid = ref object of Circle
    mov: PVec2
    rot: Pfloat

const
  WINDOW_X = 512
  WINDOW_Y = 512

  FPS = 30

  CGA = loadPaletteCGA()

proc vec2(x: Pfloat, y: PFloat): PVec2 =
  return PVec2(x: x, y: y)

proc `$`(p: PVec2): string =
  return "(" & $p.x & "," & $p.y & ")"

proc `$`(b: Bullet): string =
  return "Bullet<" & $b.pos & "," & $b.mov & "," & $b.rot & ">"

proc `$`(a: Asteroid): string =
  return "Asteroid<" & $a.pos & "," & $a.mov & "," & $a.rot & ">"

proc hash(b: Bullet): Hash =
  return hash($b)

proc hash(a: Asteroid): Hash =
  return hash($a)

proc `+`(a: PVec2, b: PVec2): PVec2 =
  return vec2(a.x + b.x, a.y + b.y)

proc `+=`(a: PVec2, b: PVec2) =
  a.x += b.x
  a.y += b.y

proc `/`(a: PVec2, b: Pfloat): PVec2 =
  result = PVec2()
  result.x = a.x / b
  result.y = a.y / b

proc `/=`(a: PVec2, b: Pfloat) =
  a.x = a.x / b
  a.y = a.y / b

proc rot(p: PVec2, deg: Pfloat): PVec2 =
  let rad = degToRad(deg)

  return vec2(p.x * cos(rad) - p.y * sin(rad), p.x * sin(rad) + p.y * cos(rad))

proc contains(c: Circle, p: PVec2): bool =
  return pow((p.x - c.pos.x), 2) + pow((p.y - c.pos.y), 2) < pow(c.radius, 2)

proc randomAsteroidPosMov(): tuple[pos: PVec2, mov: PVec2] =
  case rand(3):
  of 0: # left
    return (vec2(0, rand(WINDOW_Y)), rot(vec2(5, 0), rand(30)))
  of 1: # right
    return (vec2(WINDOW_X, rand(WINDOW_Y)), rot(vec2(-5, 0), rand(30)))
  of 2: # top
    return (vec2(rand(WINDOW_X), 0), rot(vec2(0, 5), rand(30)))
  of 3: # bottom
    return (vec2(rand(WINDOW_X), WINDOW_Y), rot(vec2(0, -5), rand(30)))
  else: raise newException(ValueError, "impossible!")

proc newShip(): Ship =
  return Ship(pos: vec2(0.0, 0.0), mov: vec2(0.0, 0.0), rot: 0.0, bulletCooldown: 0)

proc newBullet(ship: Ship): Bullet =
  return Bullet(
    pos: rot(vec2(0, 10), ship.rot) + ship.pos,
    mov: rot(vec2(0, 15), ship.rot) + (ship.mov / 2),
    rot: ship.rot,
  )

proc newAsteroid(): Asteroid =
  let (pos, mov) = randomAsteroidPosMov()

  return Asteroid(
    pos: pos,
    mov: mov,
    rot: 0,
    radius: 30,
  )

var
  ship: Ship
  bullets: seq[Bullet]
  asteroids: seq[Asteroid]
  score: int

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
      ship.bulletCooldown += 10

  if ship.bulletCooldown > 0:
    ship.bulletCooldown -= 1

  ship.rot += ship.rotMov
  
  if ship.rotMov.abs < 0.15:
    ship.rotMov = 0
  else:
    ship.rotMov = ship.rotMov / 2.5

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

proc updateProjectiles() =
  var
    newBullets = bullets.toHashSet
    newAsteroids = asteroids.toHashSet

  for a in asteroids:
    var doContinue = false

    for b in newBullets:
      if a.contains(b.pos):
        newBullets.excl(b)
        newAsteroids.excl(a)
        score += 1
        doContinue = true

    if doContinue: continue

    if (
      a.pos.x + a.radius > 0 or
      a.pos.x + a.radius < WINDOW_X or
      a.pos.y + a.radius > 0 or
      a.pos.y + a.radius < WINDOW_Y
    ):
      a.pos += a.mov
    else:
      newAsteroids.excl(a)
  
  for b in newBullets:
    if (b.pos.x < 0 or b.pos.x > WINDOW_X or b.pos.y < 0 or b.pos.y > WINDOW_Y):
      newBullets.excl(b)
    else:
      b.pos += b.mov

  bullets = newBullets.toSeq
  asteroids = newAsteroids.toSeq

proc gameInit() =
  ship = newShip()
  ship.pos.x = WINDOW_X / 2
  ship.pos.y = WINDOW_Y / 2

  bullets.setLen(0)

  setPalette(CGA)

proc gameUpdate(dt: float32) =
  if key(KeyCode.K_ESCAPE):
    nico.shutdown()
  
  if key(KeyCode.K_R):
    gameInit()

  updateShip()
  updateProjectiles()

  if rand(30) == 15:
    asteroids.add(newAsteroid())
    
proc gameDraw() =
  cls()
  
  setColor(3)
  print("SCORE: " & $score, 4, 4, 4)

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
