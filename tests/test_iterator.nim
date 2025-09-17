import std/sequtils
import std/sugar
import unittest

import pixie

import diffy

type
  StartTuple = tuple[startX, startY, scaledX, scaledY: int]

proc gatherPositions(masterSize, imageSize: (int, int), scaleFactor: int,
                     minX, minY, maxX, maxY: int): seq[StartTuple] =
  let master = newImage(masterSize[0], masterSize[1])
  let image = newImage(imageSize[0], imageSize[1])

  toSeq diffPositions(
        master,
        image,
        scaleFactor,
        minX,
        minY,
        maxX,
        maxY,
      )

suite "diffPositions iterator":

  test "respects default bounds":
    let positions = gatherPositions((5, 4), (2, 2), 1, 0, 0, int.high, int.high)
    check positions.len == 12
    check positions[0] == (0, 0, 0, 0)
    check positions[^1] == (3, 2, 3, 2)

  test "clamps minimums and scales coordinates":
    let positions = gatherPositions((10, 8), (4, 4), 2, 5, 4, int.high, int.high)
    check positions.len == 15
    check positions[0] == (2, 2, 4, 4)
    check positions[1] == (3, 2, 6, 4)
    check positions[^1] == (6, 4, 12, 8)
    check positions.allIt(it.startX >= 2)
    check positions.allIt(it.startY >= 2)
    check positions.allIt(it.scaledX == it.startX * 2)
    check positions.allIt(it.scaledY == it.startY * 2)

  test "applies maximum bounds":
    let positions = gatherPositions((10, 8), (4, 4), 2, 0, 0, 9, 5)
    check positions.len == 15
    check positions[0] == (0, 0, 0, 0)
    check positions[^1] == (4, 2, 8, 4)
    check positions.allIt(it.scaledX <= 9)
    check positions.allIt(it.scaledY <= 5)

  test "returns empty when min exceeds max":
    let positions = gatherPositions((10, 10), (4, 4), 2, 8, 0, 3, int.high)
    check positions.len == 0
