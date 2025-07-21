import nimsimd/hassimd, nimsimd/sse2, pixie, pixie/images, pixie/common

when defined(release):
  {.push checks: off.}

proc diffAtSse2*(master, image: Image, startX, startY: int): float32 {.simd.} =
  ## SSE2 SIMD optimized version of diffAt.
  ## Calculates the similarity score between the target image and master image at the given position.
  ## Returns a similarity score from 0-100 where 100 is a perfect match.
  
  var
    diffScore = 0'u64
    diffTotal = 0'u64
  
  # Process pixels row by row for better memory access patterns
  for y in 0 ..< image.height:
    let 
      masterRowStart = master.dataIndex(startX, startY + y)
      imageRowStart = image.dataIndex(0, y)
    
    var x = 0
    
    # SIMD processing: handle 4 pixels at a time (16 bytes = 4 RGBX pixels)
    while x <= image.width - 4:
      let 
        masterData = mm_loadu_si128(master.data[masterRowStart + x].addr)
        imageData = mm_loadu_si128(image.data[imageRowStart + x].addr)
      
      # We need to mask out the alpha channel since we only want RGB
      # Create mask: FF FF FF 00 FF FF FF 00 FF FF FF 00 FF FF FF 00
      let rgbMask = mm_set_epi32(0x00FFFFFF'u32, 0x00FFFFFF'u32, 0x00FFFFFF'u32, 0x00FFFFFF'u32)
      
      let
        masterRgb = mm_and_si128(masterData, rgbMask)
        imageRgb = mm_and_si128(imageData, rgbMask)
      
      # Calculate sum of absolute differences for all bytes
      # This will include some 0s from the alpha channels we masked out
      let sad = mm_sad_epu8(masterRgb, imageRgb)
      
      # Extract the two 64-bit results and add them
      let 
        sad1 = mm_cvtsi128_si64(sad)
        sad2 = mm_cvtsi128_si64(mm_srli_si128(sad, 8))
      
      diffScore += sad1.uint64 + sad2.uint64
      diffTotal += 255 * 3 * 4  # 4 pixels, 3 channels each, max value 255
      
      x += 4
    
    # Handle remaining pixels with scalar operations
    for x in x ..< image.width:
      let
        m = master.unsafe[startX + x, startY + y]
        u = image.unsafe[x, y]
      
      diffScore += abs(m.r.int64 - u.r.int64).uint64 + 
                   abs(m.g.int64 - u.g.int64).uint64 + 
                   abs(m.b.int64 - u.b.int64).uint64
      diffTotal += 255 * 3
  
  # Calculate similarity score (higher is better, 100 = perfect match)
  if diffTotal == 0:
    return 100.0
  else:
    return 100.0 * (1.0 - diffScore.float32 / diffTotal.float32)

when defined(release):
  {.pop.}
