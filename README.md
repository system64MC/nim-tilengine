# nim-tilengine

Nim bindings for [Tilengine](https://www.tilengine.org/) - a free, cross-platform 2D graphics engine for creating classic/retro games with tile maps, sprites and palettes.


## Documentation

Refer to the [C docs](https://www.tilengine.org/doc/) and peek at the Nim source to get a feel for things.

These Nim bindings are close to the C bindings, with the following changes:

- "TLN_" prefixes have been dropped, e.g. `TLN_CreateBitmap` &nbsp; → &nbsp; `createBitmap`
- Procs acting on a common type have the name omitted, e.g. `TLN_GetBitmapWidth` &nbsp; → &nbsp; `getWidth`
- Procs returning an "out param" via pointer, plus a success bool, now return both as a tuple like `(value, ok)`.
- Layers & sprites are [distinct](https://nim-lang.org/docs/manual.html#types-distinct-type) integer types, so you can kinda treat them like objects.
- Almost all procs returning `bool` are [discardable](https://nim-lang.org/docs/tut1.html#procedures-discard-statement), except those deemed important to check.
- `Tile` objects have accessors (e.g. `t.flipx = true`) so you don't have to get your hands dirty with flags.
- Enums with short prefixes use camelCase e.g. `cwfVsync`, `errFileNotFound`
- Enums with long prefixes use PascalCase e.g. `BlendNone`, `InputLeft`
- Procs have been added to avoid the need for nil. e.g. `TLN_SetLayerPixelMapping(layer, NULL)` &nbsp; → &nbsp; `layer.disablePixelMapping()`
- Where a pointer refers to the first element in an array, `ptr UncheckedArray[T]` is used instead of `ptr T`

Note: these bindings do use manual memory management, so you must call `foo.delete()` etc. to avoid leaks.

## Example

```nim
import tilengine

# Initialise the engine
let engine = init(400, 240, numlayers = 1, numsprites = 0, numanimations = 0)

# Load a tilemap
let fg = loadTilemap("assets/forest/map.tmx")

# Modify a tile
block:
  let x = 10'i32
  let y = 12'i32
  var (tile, _) = fg.getTile(y, x)
  tile.flipx = true
  tile.flipy = true
  fg.setTile(y, x, tile)

# Assign tilemap to layer
const layer = Layer(0)
layer.setTilemap(fg)

# Create window and run game loop
doAssert createWindow()

while processWindow():
  drawFrame()

# Cleanup
fg.delete()
deinit()
```

## Installation

You will need the following shared libraries installed on your system or placed in the same directory as your executable.
- tilengine (build from [source](https://github.com/megamarc/Tilengine) or buy from [itch](https://megamarc.itch.io/tilengine)).
- SDL2
- libpng

Clone the repo, use nimble to install it, then try building the example!

```sh
git clone https://git.sr.ht/~exelotl/nim-tilengine
cd nim-tilengine
nimble install
cd examples
nim c -r example.nim
```

Any questions, just send an email to the public mailing list at [~exelotl/public-inbox@lists.sr.ht](mailto:~exelotl/public-inbox@lists.sr.ht).
