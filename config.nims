
task test, "Run tests":
  exec "nim c tests/test_simd.nim"
  exec "nim c tests/test_nosimd.nim"

  echo "\n##### Running Non-SIMD test #####\n"
  exec "tests/test_nosimd"
  echo "\n##### Running SIMD test #####\n"
  exec "tests/test_simd"
