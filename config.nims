
task test, "Run tests":
  exec "nim c tests/test_simd.nim"
  exec "nim c tests/test_nosimd.nim"

  exec "tests/test_nosimd"
  exec "tests/test_simd"
