import nimsimd/hassimd, nimsimd/neon, pixie, pixie/images, pixie/common

{.push stackTrace: off.}

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
    
        # SIMD processing: handle 4 pixels at a time (16 bytes = 4 RGBX pixels)
    while x <= image.width - 4:
      let 
        masterData = vld1q_u8(master.data[masterRowStart + x].addr)
        imageData = vld1q_u8(image.data[imageRowStart + x].addr)
      
      # We need to mask out the alpha channel since we only want RGB
      # Create mask for RGBX format: keep RGB (0xFF), zero out X (0x00)
      let rgbMask = vreinterpretq_u8_u32(vmovq_n_u32(0x00FFFFFF'u32))  # Each 32-bit word: 0x00FFFFFF
      
      let
        masterRgb = vandq_u8(masterData, rgbMask)
        imageRgb = vandq_u8(imageData, rgbMask)
      
      # Calculate absolute differences for all bytes
      # Use conditional subtraction: if a < b then b-a else a-b
      let
        aLtB = vcltq_u8(masterRgb, imageRgb)  # masterRgb < imageRgb
        diff1 = vsubq_u8(imageRgb, masterRgb)  # image - master (when master < image)
        diff2 = vsubq_u8(masterRgb, imageRgb)  # master - image (when master >= image)
        absDiff = vbslq_u8(aLtB, diff1, diff2)  # select diff1 if a<b, else diff2
      
      # Sum up all the differences using pairwise addition
      let
        sum16 = vpaddlq_u8(absDiff)      # u8 -> u16, pairwise add
        sum32 = vpaddlq_u16(sum16)       # u16 -> u32, pairwise add
      
      # Accumulate the sum
      diffScore += vaddlvq_u32(sum32)
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
