
task test, "Run tests":
  exec "nim c -r tests/test_simd.nim"
  exec "nim c -r tests/test_nosimd.nim"
