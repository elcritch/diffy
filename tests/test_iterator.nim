import std/sequtils
import std/sugar
import unittest

import pixie

import diffy

type
  StartTuple = tuple[start: tuple[x, y: int], scaled: tuple[x, y: int]]

proc gatherPositions(masterSize, imageSize: (int, int), scaleFactor: int,
                     minX, minY, maxX, maxY: int,
                     centerOutwards = false): seq[StartTuple] =
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
        centerOutwards=centerOutwards,
      )

suite "diffPositions iterator":

  test "respects default bounds":
    let positions = gatherPositions((5, 4), (2, 2), scaleFactor=1, 0, 0, int.high, int.high)
    check positions.len == 12
    check positions[0] == ((0, 0), (0, 0))
    check positions[^1] == ((3, 2), (3, 2))

  test "clamps minimums and scales coordinates":
    let positions = gatherPositions((10, 8), (4, 4), scaleFactor=2, 5, 4, int.high, int.high)
    check positions.len == 15
    check positions[0] == ((2, 2), (4, 4))
    check positions[1] == ((3, 2), (6, 4))
    check positions[^1] == ((6, 4), (12, 8))
    check positions.allIt(it.start.x >= 2)
    check positions.allIt(it.start.y >= 2)
    check positions.allIt(it.scaled.x == it.start.x * 2)
    check positions.allIt(it.scaled.y == it.start.y * 2)

  test "applies maximum bounds":
    let positions = gatherPositions((10, 8), (4, 4), scaleFactor=2, 0, 0, 9, 5)
    check positions.len == 15
    check positions[0] ==  ((0, 0), (0, 0))
    check positions[^1] == ((4, 2), (8, 4))
    check positions.allIt(it.scaled.x <= 9)
    check positions.allIt(it.scaled.y <= 5)

  test "returns empty when min exceeds max":
    let positions = gatherPositions((10, 10), (4, 4), scaleFactor=2, 8, 0, 3, int.high)
    check positions.len == 0

  test "can iterate from center outwards":
    let positions = gatherPositions((5, 4), (2, 2), scaleFactor=1, 0, 0, int.high, int.high, true)
    check positions.len == 12
    check positions[0] ==  ((1, 1), (1, 1))
    check positions[1] ==  ((0, 0), (0, 0))
    check positions[2] ==  ((1, 0), (1, 0))
    check positions[3] ==  ((2, 0), (2, 0))
    check positions[^1] == ((3, 2), (3, 2))

test "can iterate from center outwards":
    let positions = gatherPositions((5, 5), (1, 1), scaleFactor=1, 0, 0, int.high, int.high, true)
    check positions.len == 25
    check positions[0].start ==  (2, 2)
    check positions[1].start ==  (1, 1)
    check positions[2].start ==  (2, 1)
    check positions[3].start ==  (3, 1)
    check positions[4].start ==  (1, 2)
    check positions[5].start ==  (3, 2)
    check positions[6].start ==  (1, 3)
    check positions[7].start ==  (2, 3)
    check positions[8].start ==  (3, 3)
    check positions[9].start ==  (0, 0)

    check positions[^1].scaled == (4, 4)
