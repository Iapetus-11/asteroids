# Package

version = "0.1.0"
author = "Iapetus11"
description = "asteroids"
license = "?"

# Deps
requires "nim >= 1.2.0"
requires "nico >= 0.2.5"

srcDir = "src"

import strformat

const releaseOpts = "-d:danger"
const debugOpts = "-d:debug"

task runr, "Runs asteroids for current platform":
 exec &"nim c -r {releaseOpts} -o:asteroids src/asteroids.nim"

task rund, "Runs debug asteroids for current platform":
 exec &"nim c -r {debugOpts} -o:asteroids src/asteroids.nim"

task release, "Builds asteroids for current platform":
 exec &"nim c {releaseOpts} -o:asteroids src/asteroids.nim"

task webd, "Builds debug asteroids for web":
 exec &"nim c {debugOpts} -d:emscripten -o:asteroids.html src/asteroids.nim"

task webr, "Builds release asteroids for web":
 exec &"nim c {releaseOpts} -d:emscripten -o:asteroids.html src/asteroids.nim"

task debug, "Builds debug asteroids for current platform":
 exec &"nim c {debugOpts} -o:asteroids_debug src/asteroids.nim"

task deps, "Downloads dependencies":
 exec "curl https://www.libsdl.org/release/SDL2-2.0.18-win32-x64.zip -o SDL2_x64.zip"
 exec "unzip SDL2_x64.zip"

task androidr, "Release build for android":
  if defined(windows):
    exec &"nicoandroid.cmd"
  else:
    exec &"nicoandroid"
  exec &"nim c -c --nimcache:android/app/jni/src/armeabi {releaseOpts}  --cpu:arm   --os:android -d:androidNDK --noMain --genScript src/asteroids.nim"
  exec &"nim c -c --nimcache:android/app/jni/src/arm64   {releaseOpts}  --cpu:arm64 --os:android -d:androidNDK --noMain --genScript src/asteroids.nim"
  exec &"nim c -c --nimcache:android/app/jni/src/x86     {releaseOpts}  --cpu:i386  --os:android -d:androidNDK --noMain --genScript src/asteroids.nim"
  exec &"nim c -c --nimcache:android/app/jni/src/x86_64  {releaseOpts}  --cpu:amd64 --os:android -d:androidNDK --noMain --genScript src/asteroids.nim"
  withDir "android":
    if defined(windows):
      exec &"gradlew.bat assembleDebug"
    else:
      exec "./gradlew assembleDebug"
