
template multiplyDiv255(c, a: uint8x8): uint8x8 =
  let ca = vmull_u8(c, a)
  vraddhn_u16(ca, vrshrq_n_u16(ca, 8))

template multiplyDiv255(c, a: uint8x16): uint8x16 =
  vcombine_u8(
    multiplyDiv255(vget_low_u8(c), vget_low_u8(a)),
    multiplyDiv255(vget_high_u8(c), vget_high_u8(a))
  )

