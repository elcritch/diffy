# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/strutils
import std/[times, monotimes]
import unittest

import pixie

import diffy

template timeIt(name: string, body: untyped) =
  let start = getMonoTime()
  body
  let stop = getMonoTime()
  echo name, " took ", (stop - start).inMilliseconds, "ms"

let masterImagePath = "tests/data/settings.png"
let masterImageParticalPath = "tests/data/settingsPartial.png"
let targetImagePath = "tests/data/transfer_button.png"

# Load the master image (screenshot)
let masterImage = readImage(masterImagePath)
echo "Master image loaded: ", masterImage.width, "x", masterImage.height

# Load the master image partial (screenshot)
let masterImagePartial = readImage(masterImageParticalPath)
echo "Master image loaded: ", masterImage.width, "x", masterImage.height

# Load the image to find (UI element)
let targetImage = readImage(targetImagePath)
echo "Target image loaded: ", targetImage.width, "x", targetImage.height

suite "basic image search":

  test "startCenter prioritizes central match":
    let master = newImage(4, 4)
    let target = newImage(2, 2)

    let (_, posDefault) = findImg(master, target, centerResult = false, startCenter = false)
    let (_, posCentered) = findImg(master, target, centerResult = false, startCenter = true)

    check posDefault == (0, 0)
    check posCentered == (1, 1)

  test "can find":
    when false:
      let halvingsCount = 1

      # Find the target image in the master image
      echo "Searching for target image in master image..."
      echo "  Halvings: ", halvingsCount

      timeIt "findImg":
        let (confidence, position) = findImg(masterImagg, targetImage, halvingsCount)

      check confidence >= 98.0
      check position[0] == 936
      check position[1] == 1707

      echo ""
      echo "Results:"
      echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
      echo "  Position: (", position[0], ", ", position[1], ")"

      if confidence >= 80.0:
        echo "  Status: FOUND! Good match detected."
      elif confidence >= 60.0:
        echo "  Status: Possible match found."
      else:
        echo "  Status: No good match found."

  test "can find with maxY":
    let halvingsCount = 1
    let confidenceThreshold = 99.0

    # Find the target image in the master image
    echo "Searching for target image in master image partial..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImagePartial, targetImage, halvingsCount, maxY = 300, similarityThreshold = confidenceThreshold)

    echo "Results:"
    echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
    echo "  Position: (", position[0], ", ", position[1], ")"

    check confidence >= confidenceThreshold
    check position[0] == 936
    check position[1] == 277

  test "can find with minY":
    let halvingsCount = 1
    let confidenceThreshold = 99.0

    # Find the target image in the master image
    echo "Searching for target image in master image partial..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImagePartial, targetImage, halvingsCount, minY = 150, similarityThreshold = confidenceThreshold)

    echo "Results:"
    echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
    echo "  Position: (", position[0], ", ", position[1], ")"

    check confidence >= confidenceThreshold
    check position[0] == 936
    check position[1] == 277

  test "can find with minX":
    let halvingsCount = 1
    let confidenceThreshold = 99.0

    # Find the target image in the master image
    echo "Searching for target image in master image partial..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImagePartial, targetImage, halvingsCount, minX = 300, similarityThreshold = confidenceThreshold)

    echo "Results:"
    echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
    echo "  Position: (", position[0], ", ", position[1], ")"

    check confidence >= confidenceThreshold
    check position[0] == 936
    check position[1] == 277

  test "cannot find with maxY":
    let halvingsCount = 1
    let confidenceThreshold = 99.0

    # Find the target image in the master image
    echo "Searching for target image in master image partial..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImagePartial, targetImage, halvingsCount, maxY = 200, similarityThreshold = confidenceThreshold)

    echo "Results:"
    echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
    echo "  Position: (", position[0], ", ", position[1], ")"

    check confidence < confidenceThreshold
    check position[0] == 938
    check position[1] == 173

  test "cannot find with minX":
    let halvingsCount = 1
    let confidenceThreshold = 99.0

    # Find the target image in the master image
    echo "Searching for target image in master image partial..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImagePartial, targetImage, halvingsCount, minX = 600, similarityThreshold = confidenceThreshold)

    echo "Results:"
    echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
    echo "  Position: (", position[0], ", ", position[1], ")"

    check confidence < confidenceThreshold
