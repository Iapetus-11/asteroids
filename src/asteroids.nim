import nico

proc gameInit() =
  discard

proc gameUpdate(dt: float32) =
  discard

proc gameDraw() =
  discard

nico.createWindow("Asteroids", 256, 256, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
