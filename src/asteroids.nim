import std/[math, sets, hashes, sequtils]
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

  Circle = ref object of RootObj
    pos: PVec2  # center
    radius: PFloat

  Asteroid = ref object of Circle
    mov: PVec2
    rot: Pfloat

  GameState = enum
    ControlsHelp, Running

const
  WINDOW_X = 512
  WINDOW_Y = 512

  FPS = 30

  CGA = loadPaletteCGA()

  BULLET_COOLDOWN = 7

proc vec2(x: Pfloat, y: PFloat): PVec2 =
  return PVec2(x: x, y: y)

proc `$`(p: PVec2): string =
  return "(" & $p.x & "," & $p.y & ")"

proc `$`(b: Bullet): string =
  return "Bullet<" & $b.pos & "," & $b.mov & "," & $b.rot & ">"

proc `$`(a: Asteroid): string =
  return "Asteroid<" & $a.pos & "," & $a.mov & "," & $a.rot & "," & $a.radius & ">"

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
  let
    angle = rnd(31)
    mov = rnd(4) + 1

  case rnd(4):
  of 0: # left
    return (vec2(0, rnd(WINDOW_Y)), rot(vec2(mov, 0), angle))
  of 1: # right
    return (vec2(WINDOW_X, rnd(WINDOW_Y)), rot(vec2(-mov, 0), angle))
  of 2: # top
    return (vec2(rnd(WINDOW_X), 0), rot(vec2(0, mov), angle))
  of 3: # bottom
    return (vec2(rnd(WINDOW_X), WINDOW_Y), rot(vec2(0, -mov), angle))
  else: raise newException(ValueError, "impossible!")

proc newShip(): Ship =
  return Ship(pos: vec2(0.0, 0.0), mov: vec2(0.0, 0.0), rot: 0.0, bulletCooldown: 0)

proc newBullet(ship: Ship): Bullet =
  return Bullet(
    pos: rot(vec2(0, 10), ship.rot) + ship.pos,
    mov: rot(vec2(0, 15), ship.rot) + (ship.mov / 2),
    rot: ship.rot,
  )

proc newAsteroid(radius: int): Asteroid =
  let (pos, mov) = randomAsteroidPosMov()

  return Asteroid(
    pos: pos,
    mov: mov,
    rot: 0,
    radius: radius,
  )

proc newAsteroidChild(a: Asteroid, b: Bullet, v: int): Asteroid =
  var radius = -1

  if a.radius == 30:
    radius = (rnd(2) + 1) * 10
  else:
    radius = 10

  result = newAsteroid(radius)

  result.pos = a.pos + vec2(rnd(10)-5, rnd(10)-5)
  result.mov = (b.mov / 10) + a.mov + vec2(v, 0)

var
  ship: Ship
  bullets: seq[Bullet]
  asteroids: seq[Asteroid]
  score: int
  gameState = GameState.ControlsHelp

proc gameInit() =
  ship = newShip()
  ship.pos.x = WINDOW_X / 2
  ship.pos.y = WINDOW_Y / 2

  bullets.setLen(0)
  asteroids.setLen(0)

  score = 0

  setPalette(CGA)

proc keyboardControls() =
  if key(KeyCode.K_LEFT):
    if ship.rotMov > -15:
      ship.rotMov -= 6.5
  
  if key(KeyCode.K_RIGHT):
    if ship.rotMov < 15:
      ship.rotMov += 6.5

  if key(KeyCode.K_UP):
    ship.mov += rot(vec2(0, 2), ship.rot)
    
  if key(KeyCode.K_DOWN):
    ship.mov += rot(vec2(0, -2), ship.rot)

  if key(KeyCode.K_SPACE):
    if ship.bulletCooldown < 1:
      bullets.add(newBullet(ship))
      ship.bulletCooldown += BULLET_COOLDOWN

  if key(KeyCode.K_ESCAPE):
    nico.shutdown()
  
  if key(KeyCode.K_R):
    gameInit()

proc joystickControls() =
  ship.rotMov = jaxis(NicoAxis.pcXAxis2) * 15
  ship.mov += rot(vec2(0, jaxis(NicoAxis.pcYAxis) * -2), ship.rot)

  if jaxis(NicoAxis.pcRTrigger) > 0:
    if ship.bulletCooldown < 1:
      bullets.add(newBullet(ship))
      ship.bulletCooldown += BULLET_COOLDOWN

  if btn(NicoButton.pcStart):
    gameInit()

proc updateShip() =
  if ship.bulletCooldown > 0:
    ship.bulletCooldown -= 1

  ship.rot += ship.rotMov
  
  if ship.rotMov.abs < 0.15:
    ship.rotMov = 0
  else:
    ship.rotMov = ship.rotMov / 2.5

  ship.mov.x = min(ship.mov.x.abs, 6).copySign(ship.mov.x)
  ship.mov.y = min(ship.mov.y.abs, 6).copySign(ship.mov.y)

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

  ship.mov /= 1.1

proc updateProjectiles() =
  var
    newBullets = bullets.toHashSet
    newAsteroids = asteroids.toHashSet

  for a in asteroids:
    if a.contains(ship.pos):
      newAsteroids.excl(a)
      score = (score / 2).int - 10

    var doContinue = false

    for b in bullets:
      if a.contains(b.pos):
        newBullets.excl(b)
        newAsteroids.excl(a)

        score += 1
        doContinue = true

        if a.radius == 30:
          for i in 0 .. (rnd(2) + 1):
            newAsteroids.incl(newAsteroidChild(a, b, i))
        elif a.radius == 20:
            newAsteroids.incl(newAsteroidChild(a, b, 1))

    if doContinue: continue

    let r2 = a.radius * 2

    if (
      a.pos.x + r2 > 0 and
      a.pos.x - r2 < WINDOW_X and
      a.pos.y + r2 > 0 and
      a.pos.y - r2 < WINDOW_Y
    ):
      a.pos += a.mov
    else:
      newAsteroids.excl(a)
  
  for b in bullets:
    if (b.pos.x < 0 or b.pos.x > WINDOW_X or b.pos.y < 0 or b.pos.y > WINDOW_Y):
      newBullets.excl(b)
    else:
      b.pos += b.mov

  bullets = newBullets.toSeq
  asteroids = newAsteroids.toSeq

proc gameUpdate(dt: float32) =
  case gameState:
  of ControlsHelp:
    if anykeyp() or anybtnp():
      gameState = GameState.Running
  of Running:
    if anykeyp():
      keyboardControls()
    elif (
      jaxis(NicoAxis.pcXAxis) != 0 or
      jaxis(NicoAxis.pcYAxis) != 0 or
      jaxis(NicoAxis.pcXAxis2) != 0 or
      jaxis(NicoAxis.pcYAxis2) != 0
    ):
      joystickControls()

    updateShip()
    updateProjectiles()

    if rnd(30) == 15:
      asteroids.add(newAsteroid(30))
    
proc gameDraw() =
  cls()
  
  case gameState:
  of GameState.ControlsHelp:
    setColor(3)
    printc("ASTEROIDS CLONE BY IAPETUS11", (WINDOW_X / 2).int, 30, 4)

    rectfill(20, 67, WINDOW_X - 20, 70)

    printc("SPACE TO SHOOT", (WINDOW_X / 2).int, 90, 4)
    printc("LEFT / RIGHT ARROWS TURN", (WINDOW_X / 2).int, 120, 4)
    printc("UP / DOWN ARROWS FOR THRUST", (WINDOW_X / 2).int, 150, 4)

    rectfill(20, 187, WINDOW_X - 20, 190)

    printc("PRESS ANY KEY TO START!", (WINDOW_X / 2).int, 210, 4)
  of GameState.Running:
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
