import pixie
import pixie/images
import os

import diffy/simd

{.push checks: off.}
{.push stackTrace: off.}

export readImage

iterator diffPositions*(
    master, image: Image,
    scaleFactor: Natural,
    minX, minY: int,
    maxX, maxY: int
): tuple[startX, startY, scaledX, scaledY: int] =
  ## Generates the (startX, startY) offsets to check when matching an image.
  ## Returns both the scaled and unscaled coordinates so callers can avoid
  ## recomputing them. The iterator respects the optional min/max constraints
  ## and clamps them to the bounds of the provided images.

  let clampedMinX = minX.max(0)
  let clampedMinY = minY.max(0)

  let maxStartWidth = max(master.width - image.width, 0)
  let maxStartHeight = max(master.height - image.height, 0)

  let minStartX = min(clampedMinX div scaleFactor, maxStartWidth)
  let minStartY = min(clampedMinY div scaleFactor, maxStartHeight)

  let maxStartX =
    if maxX == int.high:
      maxStartWidth
    else:
      min(max(maxX div scaleFactor, 0), maxStartWidth)

  let maxStartY =
    if maxY == int.high:
      maxStartHeight
    else:
      min(max(maxY div scaleFactor, 0), maxStartHeight)

  if minStartX > maxStartX or minStartY > maxStartY:
    discard
  else:
    for startY in minStartY .. maxStartY:
      let scaledY = startY * scaleFactor
      for startX in minStartX .. maxStartX:
        let scaledX = startX * scaleFactor
        yield (startX, startY, scaledX, scaledY)

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
    halvings: Natural = 0,
    centerResult = true,
    similarityThreshold: float32 = 99.0,
    minX: int = 0,
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
    for (startX, startY, scaledX, scaledY) in diffPositions(
        masterToUse,
        imageToUse,
        scaleFactor=scaleFactor,
        minX=minX,
        minY=minY,
        maxX=maxX,
        maxY=maxY,
      ):
      let similarity = diffAt(masterToUse, imageToUse, startX, startY)

      if similarity > bestScore:
        bestScore = similarity
        # Scale the position back to original size
        bestPos = (scaledX, scaledY)

        # Early exit if we found a perfect or very good match
        if similarity >= similarityThreshold:
          break search

  if centerResult:
    let centerX = bestPos[0] + (image.width div 2)
    let centerY = bestPos[1] + (image.height div 2)
    return (bestScore, (centerX, centerY))
  else:
    return (bestScore, bestPos)
