# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import diffy

test "can add":

  let masterImagePath = "tests/master.png"
  let targetImagePath = "tests/target.png"

  let halvingsCount =
    if paramCount() >= 4:
      try:
        parseInt(paramStr(4))
      except ValueError:
        echo "Error: Invalid halvings value. Must be a non-negative integer"
        quit(1)
    else:
      0

  # Validate parameters
  if halvingsCount < 0:
    echo "Error: Halvings must be a non-negative integer"
    quit(1)

  try:
    # Load the master image (screenshot)
    let masterImage = readImage(masterImagePath)
    echo "Master image loaded: ", masterImage.width, "x", masterImage.height

    # Load the image to find (UI element)
    let targetImage = readImage(targetImagePath)
    echo "Target image loaded: ", targetImage.width, "x", targetImage.height

    # Find the target image in the master image
    echo "Searching for target image in master image..."
    echo "  Halvings: ", halvingsCount

    let (confidence, position) = findImg(masterImage, targetImage, halvingsCount)

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
  except CatchableError as e:
    echo "Error: ", e.msg
    quit(1)