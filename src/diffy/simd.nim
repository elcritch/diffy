import nimsimd/hassimd

export hassimd

const allowSimd* = not defined(diffyNoSimd) and not defined(tcc)

when allowSimd:
  when defined(amd64):
    import diffy_sse2
    export diffy_sse2

    import nimsimd/sse2 as nimsimdsse2
    export nimsimdsse2

  elif defined(arm64):
    import diffy_neon
    export diffy_neon

    import nimsimd/neon as nimsimdneon
    export nimsimdneon
