import nimsimd/hassimd, nimsimd/neon, pixie, pixie/images, pixie/common

when defined(release):
  {.push checks: off.}

proc diffAtNeon*(master, image: Image, startX, startY: int): float32 {.simd.} =
  ## NEON SIMD optimized version of diffAt.
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
    
    # SIMD processing: handle 16 pixels at a time (4 components × 4 pixels = 16 bytes)
    while x <= image.width - 4:
      let 
        masterData = vld4_u8(master.data[masterRowStart + x].addr)
        imageData = vld4_u8(image.data[imageRowStart + x].addr)
      
      # Calculate absolute differences for R, G, B channels (skip alpha)  
      # Implement abs(a - b) using conditional subtraction with vcltq_u8
      let
        rCombinedM = vcombine_u8(masterData.val[0], masterData.val[0])
        rCombinedI = vcombine_u8(imageData.val[0], imageData.val[0])
        rLt = vcltq_u8(rCombinedM, rCombinedI)  # master < image
        rDiff1 = vsubq_u8(rCombinedI, rCombinedM)  # image - master (when master < image)
        rDiff2 = vsubq_u8(rCombinedM, rCombinedI)  # master - image (when master >= image)
        rDiffFinal = vbslq_u8(rLt, rDiff1, rDiff2)
        rDiff = vget_low_u8(rDiffFinal)
        
        gCombinedM = vcombine_u8(masterData.val[1], masterData.val[1])
        gCombinedI = vcombine_u8(imageData.val[1], imageData.val[1])
        gLt = vcltq_u8(gCombinedM, gCombinedI)
        gDiff1 = vsubq_u8(gCombinedI, gCombinedM)
        gDiff2 = vsubq_u8(gCombinedM, gCombinedI)
        gDiffFinal = vbslq_u8(gLt, gDiff1, gDiff2)
        gDiff = vget_low_u8(gDiffFinal)
        
        bCombinedM = vcombine_u8(masterData.val[2], masterData.val[2])
        bCombinedI = vcombine_u8(imageData.val[2], imageData.val[2])
        bLt = vcltq_u8(bCombinedM, bCombinedI)
        bDiff1 = vsubq_u8(bCombinedI, bCombinedM)
        bDiff2 = vsubq_u8(bCombinedM, bCombinedI)
        bDiffFinal = vbslq_u8(bLt, bDiff1, bDiff2)
        bDiff = vget_low_u8(bDiffFinal)
      
      # Sum up the differences by extending to u16 then to u32
      let
        rSum = vpaddlq_u8(vcombine_u8(rDiff, rDiff))  # u8 -> u16, pairwise add
        gSum = vpaddlq_u8(vcombine_u8(gDiff, gDiff))
        bSum = vpaddlq_u8(vcombine_u8(bDiff, bDiff))
        rgSum = vaddq_u16(rSum, gSum)
        rgbSum = vaddq_u16(rgSum, bSum)
        rgbSum32 = vpaddlq_u16(rgbSum)  # u16 -> u32, pairwise add
      
      # Accumulate the sum
      diffScore += vaddlvq_u32(rgbSum32)
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
