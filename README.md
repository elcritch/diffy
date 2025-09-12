# Diffy

A high-performance image comparison and sub-image finding library for Nim, built on top of [Pixie](https://github.com/treeform/pixie) with **SIMD optimizations** for ARM64 (NEON) and x86-64 (SSE2).

## Features

- 🔍 **Sub-image finding**: Locate one image within another with high accuracy
- 📊 **Similarity scoring**: Get confidence scores (0-100%) for image matches
- ⚡ **SIMD accelerated**: Up to **10x faster** with ARM64 NEON and x86-64 SSE2 optimizations
- 🔧 **Configurable search**: Control performance vs accuracy with halving parameters
- 📍 **Flexible positioning**: Get top-left corner or center coordinates
- 🎯 **Early termination**: Stop searching when confidence threshold is reached

## Performance

Diffy includes optimized SIMD implementations that provide dramatic performance improvements:

| Architecture | Implementation | Performance | Baseline | Speedup |
|-------------|---------------|-------------|-------------|----------|
| ARM64 | NEON SIMD | **759ms** | **5835ms** | **7.6x faster** |
| x86-64 | SSE2 SIMD | **1341ms** | **10709ms** | **7.9x faster** |

*Benchmark: Finding a 944×103 UI element in a 1440×2046 screenshot with 1 halving*

## Installation

Add diffy to your `.nimble` file:

```nimble
requires "https://github.com/elcritch/diffy >= 0.1.0"
```

Or install directly:

```bash
atlas use https://github.com/elcritch/diffy.git
nimble install https://github.com/elcritch/diffy.git
```

## Quick Start

```nim
import diffy

# Load images
let screenshot = readImage("screenshot.png")  
let button = readImage("button.png")

# Find the button in the screenshot
let (confidence, position) = findImg(screenshot, button)

if confidence >= 90.0:
  echo "Found button at (", position[0], ", ", position[1], ") with ", confidence, "% confidence"
else:
  echo "Button not found"
```

## API Reference

### `findImg`

```nim
proc findImg*(
  master, image: Image,
  halvings: int = 0,
  centerResult: bool = true,
  similarityThreshold: float32 = 99.0,
  minX: int = 0,
  minY: int = 0,
  maxX: int = int.high,
  maxY: int = int.high
): (float32, (int, int))
```

Finds the best match of `image` within `master` image.

**Parameters:**
- `master`: The larger image to search within
- `image`: The smaller image to find
- `halvings`: Number of times to reduce image sizes by half (0=full resolution, 1=half, 2=quarter, etc.)
- `centerResult`: If `true`, returns center coordinates; if `false`, returns top-left coordinates
- `similarityThreshold`: Stop searching early if this confidence level is reached (0-100)
- `minX`, `minY`: Start search at these coordinates to skip rows/columns above/left
- `maxX`, `maxY`: Limit search area for performance

**Returns:**
- `float32`: Confidence score (0-100%, where 100% is a perfect match)
- `(int, int)`: Position coordinates (x, y)

### `diffAt`

```nim
proc diffAt*(master, image: Image, startX, startY: int): float32
```

Calculates the similarity score between images at a specific position.

**Parameters:**
- `master`: The master image
- `image`: The image to compare
- `startX`, `startY`: Position in master image to compare

**Returns:**
- `float32`: Similarity score (0-100%)

## Usage Examples

### Basic Image Finding

```nim
import diffy

let screenshot = readImage("desktop.png")
let icon = readImage("trash_icon.png")

let (confidence, pos) = findImg(screenshot, icon)
echo "Confidence: ", confidence.formatFloat(ffDecimal, 2), "%"
echo "Position: (", pos[0], ", ", pos[1], ")"
```

### Performance-Optimized Search

```nim
# Use halvings to trade accuracy for speed
let (confidence, pos) = findImg(screenshot, icon, 
  halvings = 2,              # Search at 1/4 resolution
  similarityThreshold = 85.0 # Stop at 85% confidence
)
```

### UI Automation Example

```nim
import diffy

proc clickButton(buttonImage: string): bool =
  let screenshot = captureScreen()  # Your screen capture function
  let button = readImage(buttonImage)
  
  let (confidence, pos) = findImg(screenshot, button, halvings = 1)
  
  if confidence >= 95.0:
    clickAt(pos[0], pos[1])  # Your click function
    return true
  return false

# Usage
if clickButton("login_button.png"):
  echo "Login button clicked successfully!"
else:
  echo "Login button not found"
```

## Performance Tuning

### Halving Strategy

The `halvings` parameter is crucial for performance:

- `halvings = 0`: Full resolution, highest accuracy, slowest
- `halvings = 1`: Half resolution, good balance and usually accurate
- `halvings = 2`: Quarter resolution, faster but less precise
- `halvings = 3+`: Very fast but may confuse smaller images

### Search Area Limiting

Restrict search areas when you know approximate locations:

```nim
# Only search in the top-right quadrant
let (confidence, pos) = findImg(screenshot, icon,
  maxX = screenshot.width div 2,
  maxY = screenshot.height div 2
)
```

## SIMD Optimizations

Diffy automatically detects your CPU architecture and uses the fastest available implementation:

- **ARM64**: Uses NEON SIMD instructions for vectorized pixel comparisons
- **x86-64**: Uses SSE2 SIMD instructions with sum-of-absolute-differences
- **Other**: Falls back to optimized scalar implementation

To disable SIMD optimizations:

```nim
# Compile with SIMD disabled
nim c -d:diffyNoSimd myapp.nim
```

## Requirements

- Nim >= 2.0.0
- Pixie >= 5.0.6

## License

Apache-2.0

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Acknowledgments

- Built on top of the excellent [Pixie](https://github.com/treeform/pixie) graphics library
- SIMD optimizations inspired by high-performance image processing techniques
- Special thanks to the Nim community for the powerful SIMD intrinsics 
