import pixie
import pixie/images
import os

import diffy/simd

{.push checks: off.}
{.push stackTrace: off.}

export readImage

proc diffAt*(master, image: Image, startX, startY: int): float32 {.hasSimd, raises: [].} =
  ## Calculates the similarity score between the target image and master image at the given position.
  ## Returns a similarity score from 0-100 where 100 is a perfect match.
  var
    diffScore = 0
    diffTotal = 0

  # Compare image pixels at this position
  for x in 0 ..< image.width:
    for y in 0 ..< image.height:
      let
        m = master[startX + x, startY + y]
        u = image[x, y]

      diffScore +=
        abs(m.r.int - u.r.int) + abs(m.g.int - u.g.int) + abs(m.b.int - u.b.int)
      diffTotal += 255 * 3

  # Calculate similarity score (higher is better, 100 = perfect match)
  100.0 * (1.0 - diffScore.float32 / diffTotal.float32)

{.pop.}

proc findImg*(
    master, image: Image,
    halvings: int = 0,
    centerResult = true,
    similarityThreshold: float32 = 99.0,
    minY: int = 0,
    maxX: int = int.high,
    maxY: int = int.high,
): (float32, (int, int)) {.raises: [PixieError].} =
  ## Finds the best match of 'image' within 'master' image.
  ## Returns the confidence score (0-100) and the position (x, y) of the best match.
  ## The halvings parameter specifies how many times to reduce image sizes by half using minifyBy2().
  ## 0 = no reduction, 1 = half size, 2 = quarter size, etc.

  var
    masterToUse = master
    imageToUse = image
    scaleFactor = 1

  # Apply minifyBy2() the specified number of times
  for i in 0 ..< halvings:
    masterToUse = masterToUse.minifyBy2()
    imageToUse = imageToUse.minifyBy2()
    scaleFactor *= 2

  if imageToUse.width > masterToUse.width or imageToUse.height > masterToUse.height:
    # Image is larger than master, can't find it
    return (0.0, (0, 0))

  var
    bestScore = 0.0
    bestPos = (0, 0)

  # Search through all possible positions in master where image could fit
  block search:
    let minStartY =
      block:
        var y = minY
        if y < 0: y = 0
        # Convert requested minY (original scale) to current scaled search space
        y = y div scaleFactor
        # Ensure we don't start past the last valid row
        let maxStart = max(0, masterToUse.height - imageToUse.height)
        if y > maxStart: y = maxStart
        y

    for startY in minStartY .. (masterToUse.height - imageToUse.height):
      for startX in 0 .. (masterToUse.width - imageToUse.width):
        let similarity = diffAt(masterToUse, imageToUse, startX, startY)

        let scaledX = startX * scaleFactor
        let scaledY = startY * scaleFactor

        if similarity > bestScore:
          bestScore = similarity
          # Scale the position back to original size
          bestPos = (scaledX, scaledY)

          # Early exit if we found a perfect or very good match
          if similarity >= similarityThreshold:
            break search

        if scaledY > maxY:
          break search
        if scaledX > maxX:
          continue

  if centerResult:
    let centerX = bestPos[0] + (image.width div 2)
    let centerY = bestPos[1] + (image.height div 2)
    return (bestScore, (centerX, centerY))
  else:
    return (bestScore, bestPos)
