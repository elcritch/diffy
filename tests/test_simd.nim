# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/strutils
import std/[times, monotimes]
import unittest

import diffy

template timeIt(name: string, body: untyped) =
  let start = getMonoTime()
  body
  let stop = getMonoTime()
  echo name, " took ", (stop - start).inMilliseconds, "ms"

suite "basic image search":
  test "can find":

    let masterImagePath = "tests/data/settings.png"
    let targetImagePath = "tests/data/transfer_button.png"

    let halvingsCount = 1

    # Load the master image (screenshot)
    let masterImage = readImage(masterImagePath)
    echo "Master image loaded: ", masterImage.width, "x", masterImage.height

    # Load the image to find (UI element)
    let targetImage = readImage(targetImagePath)
    echo "Target image loaded: ", targetImage.width, "x", targetImage.height

    # Find the target image in the master image
    echo "Searching for target image in master image..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImage, targetImage, halvingsCount)

    check confidence >= 97.0
    check position[0] == 936
    check position[1] == 1707

    echo ""
    echo "Results:"
    echo "  Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
    echo "  Position: (", position[0], ", ", position[1], ")"

  test "can find with minX and minY":

    let masterImagePath = "tests/data/settings.png"
    let targetImagePath = "tests/data/transfer_button.png"

    let halvingsCount = 1

    # Load the master image (screenshot)
    let masterImage = readImage(masterImagePath)
    echo "Master image loaded: ", masterImage.width, "x", masterImage.height

    # Load the image to find (UI element)
    let targetImage = readImage(targetImagePath)
    echo "Target image loaded: ", targetImage.width, "x", targetImage.height

    # Find the target image in the master image
    echo "Searching for target image in master image..."
    echo "  Halvings: ", halvingsCount

    timeIt "findImg":
      let (confidence, position) = findImg(masterImage, targetImage, halvingsCount, minX = 300, minY = 150)

    check confidence >= 97.0
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
