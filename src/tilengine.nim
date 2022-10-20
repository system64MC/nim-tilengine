# Tilengine - The 2D retro graphics engine with raster effects

when defined(Windows):
  const libname* = "Tilengine.dll"
elif defined(Linux):
  const libname* = "libTilengine.so"
elif defined(MacOSX):
  const libname* = "Tilengine.dylib"

{.pragma: tln, dynlib:libname, cdecl.}

const
  TilengineVerMaj* = 2
  TilengineVerMin* = 11
  TilengineVerRev* = 1
  TilengineHeaderVersion* = ((TilengineVerMaj shl 16) or (TilengineVerMin shl 8) or TilengineVerRev)

type
  Blend* = enum
    ## Layer blend modes. Must be one of these and are mutually exclusive:
    BlendNone       ## Blending disabled
    BlendMix25      ## Color averaging 1
    BlendMix50      ## Color averaging 2
    BlendMix75      ## Color averaging 3
    BlendAdd        ## Color is always brighter (simulate light effects)
    BlendSub        ## Color is always darker (simulate shadow effects)
    BlendMod        ## Color is always darker (simulate shadow effects)
    BlendCustom     ## User provided blend function with `setCustomBlendFunction()`

const
  BlendMix* = BlendMix50

type
  LayerType* = enum
    ##  layer type retrieved by `getLayerType`
    LayerNone      ## Undefined
    LayerTile      ## Tilemap-based layer
    LayerObject    ## Objects layer
    LayerBitmap    ## Bitmapped layer
  
  Affine* = object
    ## Affine transformation parameters
    angle*: float32  ## Rotation in degrees
    dx*: float32     ## Horizontal translation
    dy*: float32     ## Vertical translation
    sx*: float32     ## Horizontal scaling
    sy*: float32     ## Vertical scaling
  
  Tile* {.bycopy.} = object
    ## Tile item for Tilemap access methods
    index*: uint16
    flags*: uint16

{.push inline.}

func tileset*(t: Tile): int = ((t.flags and 0x0700) shr 8).int
func masked*(t: Tile): bool = (t.flags and 0x0800) != 0
func priority*(t: Tile): bool = (t.flags and 0x1000) != 0
func rotate*(t: Tile): bool = (t.flags and 0x2000) != 0
func flipy*(t: Tile): bool = (t.flags and 0x4000) != 0
func flipx*(t: Tile): bool = (t.flags and 0x8000) != 0

func `tileset=`*(t: var Tile; val: int) =  t.flags = ((val.uint16 shl 8) and 0x0700) or (t.flags and not 0x0700'u16)
func `masked=`*(t: var Tile; val: bool) =  t.flags = (val.uint16 shl 11) or (t.flags and not 0x0800'u16)
func `priority=`*(t: var Tile; val: bool) =  t.flags = (val.uint16 shl 12) or (t.flags and not 0x1000'u16)
func `rotate=`*(t: var Tile; val: bool) =  t.flags = (val.uint16 shl 13) or (t.flags and not 0x2000'u16)
func `flipy=`*(t: var Tile; val: bool) =  t.flags = (val.uint16 shl 14) or (t.flags and not 0x4000'u16)
func `flipx=`*(t: var Tile; val: bool) =  t.flags = (val.uint16 shl 15) or (t.flags and not 0x8000'u16)

{.pop.}

type
  SequenceFrame* {.bycopy.} = object
    ## Frame animation definition
    index*: int32               ## Tile/sprite index
    delay*: int32               ## Time delay for next frame
  
  ColorStrip* {.bycopy.} = object
    ## Color strip definition
    delay*: int32               ## Time delay between frames
    first*: uint8               ## Index of first color to cycle
    count*: uint8               ## Number of colors in the cycle
    dir*: uint8                 ## Direction: 0=descending, 1=ascending
  
  SequenceInfo* {.bycopy.} = object
    ## Sequence info returned by `getSequenceInfo`
    name*: array[32, char]      ## Sequence name
    numFrames*: int32           ## Number of frames

  SpriteData* {.byref.} = object
    ## Sprite creation info for `createSpriteset()`
    name*: array[64, char]      ## Entry name
    x*: int32                   ## Horizontal position
    y*: int32                   ## Vertical position
    w*: int32                   ## Width
    h*: int32                   ## Height
  
  SpriteInfo* {.bycopy.} = object
    ## Sprite information
    w*: int32                   ## Width of sprite
    h*: int32                   ## Height of sprite
  
  TileInfo* {.bycopy.} = object
    ## Tile information returned by `getLayerTile()`
    index*: uint16           ## Tile index
    flags*: uint16           ## Attributes (FLAG_FLIPX, FLAG_FLIPY, FLAG_PRIORITY)
    row*: int32              ## Row number in the tilemap
    col*: int32              ## Col number in the tilemap
    xoffset*: int32          ## Horizontal position inside the title
    yoffset*: int32          ## Vertical position inside the title
    color*: uint8            ## Color index at collision point
    kind*: uint8             ## Tile type
    empty*: bool             ## Cell is empty
  
  ObjectInfo* {.bycopy.} = object
    ## Object item info returned by `getObjectInfo()`
    id*: uint16              ## Unique ID
    gid*: uint16             ## Graphic ID (tile index)
    flags*: uint16           ## Attributes (FLAG_FLIPX, FLAG_FLIPY, FLAG_PRIORITY)
    x*: int32                ## Horizontal position
    y*: int32                ## Vertical position
    width*: int32            ## Horizontal size
    height*: int32           ## Vertical size
    kind*: uint8             ## Type property
    visible*: bool           ## Visible property
    name*: array[64, char]   ## name property
  
  TileAttributes* {.bycopy.} = object
    ## Tileset attributes for `createTileset()`
    kind*: uint8           ## Tile type
    priority*: bool        ## Priority flag set
  
  CrtEffect* {.size:4.} = enum
    ## Types of built-in CRT effect for `configCRTEffect`
    crtSlot         ## Slot mask without scanlines, similar to legacy effect
    crtAperture     ## Aperture grille with scanlines (matrix-like dot arrangement)
    crtShadow       ## Shadow mask with scanlines, diagonal subpixel arrangement
  
  PixelMap* = object
    ## Pixel mapping for `setLayerPixelMapping()`
    dx*: int16      ## Horizontal pixel displacement
    dy*: int16      ## Vertical pixel displacement
  
  Engine* = ptr object         ## Engine context
  Tileset* = ptr object        ## Opaque tileset reference
  Tilemap* = ptr object        ## Opaque tilemap reference
  Palette* = ptr object        ## Opaque palette reference
  Spriteset* = ptr object      ## Opaque spriteset reference
  Sequence* = ptr object       ## Opaque sequence reference
  SequencePack* = ptr object   ## Opaque sequence pack reference
  Bitmap* = ptr object         ## Opaque bitmap reference
  ObjectList* = ptr object     ## Opaque object list reference
  
  TileImage* {.bycopy.} = object
    ## Image Tile items for `createImageTileset`
    bitmap*: Bitmap
    id*: uint16
    kind*: uint8
  
  SpriteState* {.bycopy.} = object
    ## Sprite state
    x*: int32                   ## Screen position x
    y*: int32                   ## Screen position y
    w*: int32                   ## Actual width in screen (after scaling)
    h*: int32                   ## Actual height in screen (after scaling)
    flags*: uint32              ## Flags
    palette*: Palette           ## Assigned palette
    spriteset*: Spriteset       ## Assigned spriteset
    index*: int32               ## Graphic index inside spriteset
    enabled*: bool              ## Enabled or not
    collision*: bool            ## Per-pixel collision detection enabled or not


#  callbacks
type
  VideoCallback* = proc (scanline: int32) {.cdecl.}
  BlendFunction* = proc (src, dst: uint8): uint8 {.cdecl.}
  # SDLCallback* = proc (a1: ptr SDL_Event) {.cdecl.}
  SDLCallback* = proc (a1: pointer) {.cdecl.}   # TODO (exe)

# Player index for input assignment functions

type
  Player* = enum
    Player1          ## Player 1
    Player2          ## Player 2
    Player3          ## Player 3
    Player4          ## Player 4
  
  Input* = enum
    ## Standard inputs query for `getInput()`
    InputNone        ## No input
    InputUp          ## Up direction
    InputDown        ## Down direction
    InputLeft        ## Left direction
    InputRight       ## Right direction
    InputButton1     ## 1st action button
    InputButton2     ## 2nd action button
    InputButton3     ## 3th action button
    InputButton4     ## 4th action button
    InputButton5     ## 5th action button
    InputButton6     ## 6th action button
    InputStart       ## Start button
    InputQuit        ## Window close (only Player 1 keyboard)
    InputCrt         ## CRT toggle (only Player 1 keyboard)
              ##  ... up to 32 unique inputs
    
    # TODO: Check this.
    
    # InputP1 = (Player1 shl 5),   ## request player 1 input (default)
    # InputP2 = (Player2 shl 5),   ## request player 2 input
    # InputP3 = (Player3 shl 5),   ## request player 3 input
    # InputP4 = (Player4 shl 5)    ## request player 4 input


type
  CreateWindowFlag* = enum
    # Flags for `createWindow` proc.
    cwfFullscreen  ## Create a fullscreen window
    cwfVsync       ## Sync frame updates with vertical retrace
    cwfNearest     ## Unfiltered upscaling

proc cwf(scale: int; flags: set[CreateWindowFlag]): uint32 =
  result = 0
  if cwfFullscreen in flags: result = result or 0x01
  if cwfVsync in flags:      result = result or 0x02
  if scale > 0:              result = result or (scale.uint32 shl 2)
  if cwfVsync in flags:      result = result or 0x40
# Error codes

type
  TlnErrorKind* = enum
    errOk              ## No error
    errOutOfMemory     ## Not enough memory
    errIdxLayer        ## Layer index out of range
    errIdxSprite       ## Sprite index out of range
    errIdxAnimation    ## Animation index out of range
    errIdxPicture      ## Picture or tile index out of range
    errRefTileset      ## Invalid Tileset reference
    errRefTilemap      ## Invalid Tilemap reference
    errRefSpriteset    ## Invalid Spriteset reference
    errRefPalette      ## Invalid Palette reference
    errRefSequence     ## Invalid Sequence reference
    errRefSeqpack      ## Invalid SequencePack reference
    errRefBitmap       ## Invalid Bitmap reference
    errNullPointer     ## Null pointer as argument
    errFileNotFound    ## Resource file not found
    errWrongFormat     ## Resource file has invalid format
    errWrongSize       ## A width or height parameter is invalid
    errUnsupported     ## Unsupported function
    errRefList         ## Invalid ObjectList reference
  
  LogLevel* = enum
    ## Debug level
    logNone,             ## Don't print anything (default)
    logErrors,           ## Print only runtime errors
    logVerbose           ## Print everything
  
  TlnError* = object of CatchableError
    kind*: TlnErrorKind

# ERRORS
# ------

proc setLastError*(error: TlnErrorKind) {.tln, importc: "TLN_SetLastError".}
proc getLastError*(): TlnErrorKind {.tln, importc: "TLN_GetLastError".}
proc getErrorString*(error: TlnErrorKind): cstring {.tln, importc: "TLN_GetErrorString".}

template e: ref TlnError =
  ## Magic to create an exception with the last error message.
  let kind = getLastError()
  let err = newException(TlnError, $getErrorString(kind))
  err.kind = kind
  err

# SETUP
# -----
# Basic setup and management

proc initImpl(hres, vres, numLayers, numSprites, numAnimations: int32): Engine {.tln, importc: "TLN_Init".}
proc deleteContextImpl(context: Engine): bool {.tln, importc: "TLN_DeleteContext".}
proc setContextImpl(context: Engine): bool {.tln, importc: "TLN_SetContext".}
proc setBgColorFromTilemapImpl(tilemap: Tilemap): bool {.tln, importc: "TLN_SetBGColorFromTilemap".}
proc setBgBitmapImpl(bitmap: Bitmap): bool {.tln, importc: "TLN_SetBGBitmap".}
proc setBgPaletteImpl(palette: Palette): bool {.tln, importc: "TLN_SetBGPalette".}
proc openResourcePackImpl(filename, key: cstring): bool {.tln, importc: "TLN_OpenResourcePack".}

proc init*(hres, vres, numLayers, numSprites, numAnimations: int32): Engine {.inline.} = (result = initImpl(hres, vres, numLayers, numSprites, numAnimations); if result == nil: raise e)
proc deinit*() {.tln, importc: "TLN_Deinit".}
proc deleteContext*(context: Engine) {.inline.} = (if not deleteContextImpl(context): raise e)
proc setContext*(context: Engine) {.inline.} = (if not setContextImpl(context): raise e)
proc getContext*(): Engine {.tln, importc: "TLN_GetContext".}
proc getWidth*(): int32 {.tln, importc: "TLN_GetWidth".}
proc getHeight*(): int32 {.tln, importc: "TLN_GetHeight".}
proc getNumObjects*(): uint32 {.tln, importc: "TLN_GetNumObjects".}
proc getUsedMemory*(): uint32 {.tln, importc: "TLN_GetUsedMemory".}
proc getVersion*(): uint32 {.tln, importc: "TLN_GetVersion".}
proc getNumLayers*(): int32 {.tln, importc: "TLN_GetNumLayers".}
proc getNumSprites*(): int32 {.tln, importc: "TLN_GetNumSprites".}
proc setBgColor*(r, g, b: uint8) {.tln, importc: "TLN_SetBGColor".}
proc setBgColorFromTilemap*(tilemap: Tilemap) {.inline.} = (if not setBgColorFromTilemapImpl(tilemap): raise e)
proc disableBgColor*() {.tln, importc: "TLN_DisableBGColor".}
proc setBgBitmap*(bitmap: Bitmap) {.inline.} = (if not setBgBitmapImpl(bitmap): raise e)
proc setBgPalette*(palette: Palette) {.inline.} = (if not setBgPaletteImpl(palette): raise e)
proc setRasterCallback*(a1: VideoCallback) {.tln, importc: "TLN_SetRasterCallback".}
proc setFrameCallback*(a1: VideoCallback) {.tln, importc: "TLN_SetFrameCallback".}
proc setRenderTarget*(data: ptr UncheckedArray[uint8]; pitch: int32) {.tln, importc: "TLN_SetRenderTarget".}
proc updateFrame*(frame: int32) {.tln, importc: "TLN_UpdateFrame".}
proc setLoadPath*(path: cstring) {.tln, importc: "TLN_SetLoadPath".}
proc setCustomBlendFunction*(a1: BlendFunction) {.tln, importc: "TLN_SetCustomBlendFunction".}
proc setLogLevel*(logLevel: LogLevel) {.tln, importc: "TLN_SetLogLevel".}
proc openResourcePack*(filename, key: cstring) {.inline.} = (if not openResourcePackImpl(filename, key): raise e)
proc closeResourcePack*() {.tln, importc: "TLN_CloseResourcePack".}

# WINDOWING
# ---------
# Built-in window and input management

proc createWindowImpl(overlay: cstring; flags: uint32): bool {.tln, importc: "TLN_CreateWindow".}
proc createWindowThreadImpl(overlay: cstring; flags: uint32): bool {.tln, importc: "TLN_CreateWindowThread".}

proc createWindow*(overlay: cstring = nil; scale: range[0..5] = 0; flags: set[CreateWindowFlag] = {}) = (if not createWindowImpl(overlay, cwf(scale, flags)): raise e)
proc createWindowThread*(overlay: cstring = nil; scale: range[0..5] = 0; flags: set[CreateWindowFlag] = {}) = (if not createWindowThreadImpl(overlay, cwf(scale, flags)): raise e)
proc setWindowTitle*(title: cstring) {.tln, importc: "TLN_SetWindowTitle".}
proc processWindow*(): bool {.tln, importc: "TLN_ProcessWindow".}
proc isWindowActive*(): bool {.tln, importc: "TLN_IsWindowActive".}
proc getInput*(id: Input): bool {.tln, importc: "TLN_GetInput".}
proc enableInput*(player: Player; enable: bool) {.tln, importc: "TLN_EnableInput".}
proc assignInputJoystick*(player: Player; index: int32) {.tln, importc: "TLN_AssignInputJoystick".}
proc defineInputKey*(player: Player; input: Input; keycode: uint32) {.tln, importc: "TLN_DefineInputKey".}
proc defineInputButton*(player: Player; input: Input; joybutton: uint8) {.tln, importc: "TLN_DefineInputButton".}
proc drawFrame*(frame: int32 = 0) {.tln, importc: "TLN_DrawFrame".}
proc waitRedraw*() {.tln, importc: "TLN_WaitRedraw".}
proc deleteWindow*() {.tln, importc: "TLN_DeleteWindow".}
proc enableBlur*(mode: bool) {.tln, importc: "TLN_EnableBlur".}
proc configCrtEffect*(kind: CrtEffect; blur: bool) {.tln, importc: "TLN_ConfigCRTEffect".}
proc enableCrtEffect*(overlay: int32; overlayFactor: uint8; threshold: uint8; v0, v1, v2, v3: uint8; blur: bool; glowFactor: uint8) {.tln, importc: "TLN_EnableCRTEffect".}
proc disableCrtEffect*() {.tln, importc: "TLN_DisableCRTEffect".}
proc setSDLCallback*(a1: SDLCallback) {.tln, importc: "TLN_SetSDLCallback".}
proc delay*(msecs: uint32) {.tln, importc: "TLN_Delay".}
proc getTicks*(): uint32 {.tln, importc: "TLN_GetTicks".}
proc getWindowWidth*(): int32 {.tln, importc: "TLN_GetWindowWidth".}
proc getWindowHeight*(): int32 {.tln, importc: "TLN_GetWindowHeight".}

# SPRITESET
# ---------
# Spriteset resources management for sprites

proc createSpritesetImpl(bitmap: Bitmap; data: SpriteData; numEntries: int32): Spriteset {.tln, importc: "TLN_CreateSpriteset".}
proc loadSpritesetImpl(name: cstring): Spriteset {.tln, importc: "TLN_LoadSpriteset".}
proc cloneImpl(src: Spriteset): Spriteset {.tln, importc: "TLN_CloneSpriteset".}
proc getSpriteInfoImpl(spriteset: Spriteset; entry: int32; info: var SpriteInfo): bool {.tln, importc: "TLN_GetSpriteInfo".}
proc setDataImpl(spriteset: Spriteset; entry: int32; data: SpriteData; pixels: pointer; pitch: int32): bool {.tln, importc: "TLN_SetSpritesetData".}
proc deleteImpl(spriteset: Spriteset): bool {.tln, importc: "TLN_DeleteSpriteset".}

proc createSpriteset*(bitmap: Bitmap; data: SpriteData; numEntries: int32): Spriteset {.inline.} = (result = createSpritesetImpl(bitmap, data, numEntries); if result == nil: raise e)
proc loadSpriteset*(name: cstring): Spriteset {.inline.} = (result = loadSpritesetImpl(name); if result == nil: raise e)
proc clone*(src: Spriteset): Spriteset {.inline.} = (result = cloneImpl(src); if result == nil: raise e)
proc getSpriteInfo*(spriteset: Spriteset; entry: int32): SpriteInfo {.inline.} = (if not getSpriteInfoImpl(spriteset, entry, result): raise e)
proc getPalette*(spriteset: Spriteset): Palette {.tln, importc: "TLN_GetSpritesetPalette".}
proc findSprite*(spriteset: Spriteset; name: cstring): int32 {.tln, importc: "TLN_FindSpritesetSprite".}
proc setData*(spriteset: Spriteset; entry: int32; data: SpriteData; pixels: pointer; pitch: int32) {.inline.} = (if not setDataImpl(spriteset, entry, data, pixels, pitch): raise e)
proc delete*(spriteset: Spriteset) {.inline.} = (if not deleteImpl(spriteset): raise e)

# TILESET
# -------
# Tileset resources management for background layers

proc createTilesetImpl(numtiles: int32; width, height: int32; palette: Palette; sp: SequencePack; attributes: ptr UncheckedArray[TileAttributes]): Tileset {.tln, importc: "TLN_CreateTileset".}
proc createImageTilesetImpl(numtiles: int32; images: ptr UncheckedArray[TileImage]): Tileset {.tln, importc: "TLN_CreateImageTileset".}
proc loadTilesetImpl(filename: cstring): Tileset {.tln, importc: "TLN_LoadTileset".}
proc cloneImpl(src: Tileset): Tileset {.tln, importc: "TLN_CloneTileset".}
proc setPixelsImpl(tileset: Tileset; entry: int32; srcdata: ptr UncheckedArray[uint8]; srcpitch: int32): bool {.tln, importc: "TLN_SetTilesetPixels".}
proc deleteImpl(tileset: Tileset): bool {.tln, importc: "TLN_DeleteTileset".}

proc createTileset*(numtiles: int32; width, height: int32; palette: Palette; sp: SequencePack; attributes: ptr UncheckedArray[TileAttributes]): Tileset {.inline.} = (result = createTilesetImpl(numtiles, width, height, palette, sp, attributes); if result == nil: raise e)
proc createImageTileset*(numtiles: int32; images: ptr UncheckedArray[TileImage]): Tileset {.inline.} = (result = createImageTilesetImpl(numtiles, images); if result == nil: raise e)
proc loadTileset*(filename: cstring): Tileset {.inline.} = (result = loadTilesetImpl(filename); if result == nil: raise e)
proc clone*(src: Tileset): Tileset {.inline.} = (result = cloneImpl(src); if result == nil: raise e)
proc setPixels*(tileset: Tileset; entry: int32; srcdata: ptr UncheckedArray[uint8]; srcpitch: int32) {.inline.} = (if not setPixelsImpl(tileset, entry, srcdata, srcpitch): raise e)
proc getTileWidth*(tileset: Tileset): int32 {.tln, importc: "TLN_GetTileWidth".}
proc getTileHeight*(tileset: Tileset): int32 {.tln, importc: "TLN_GetTileHeight".}
proc getNumTiles*(tileset: Tileset): int32 {.tln, importc: "TLN_GetTilesetNumTiles".}
proc getPalette*(tileset: Tileset): Palette {.tln, importc: "TLN_GetTilesetPalette".}
proc getSequencePack*(tileset: Tileset): SequencePack {.tln, importc: "TLN_GetTilesetSequencePack".}
proc delete*(tileset: Tileset) {.inline.} = (if not deleteImpl(tileset): raise e)

# TILEMAP
# -------
# Tilemap resources management for background layers

proc createTilemapImpl(rows: int32; cols: int32; tiles: ptr UncheckedArray[Tile]; bgcolor: uint32; tileset: Tileset): Tilemap {.tln, importc: "TLN_CreateTilemap".}
proc loadTilemapImpl(filename: cstring; layername: cstring = nil): Tilemap {.tln, importc: "TLN_LoadTilemap".}
proc cloneImpl(src: Tilemap): Tilemap {.tln, importc: "TLN_CloneTilemap".}
proc setTilesetImpl(tilemap: Tilemap; tileset: Tileset): bool {.tln, importc: "TLN_SetTilemapTileset".}
proc setTilesetImpl(tilemap: Tilemap; tileset: Tileset; index: int32): bool {.tln, importc: "TLN_SetTilemapTileset2".}
proc getTileImpl(tilemap: Tilemap; row, col: int32; tile: var Tile): bool {.tln, importc: "TLN_GetTilemapTile".}
proc setTileImpl(tilemap: Tilemap; row, col: int32; tile: ptr Tile): bool {.tln, importc: "TLN_SetTilemapTile".}
proc copyTilesImpl(src: Tilemap; srcrow, srccol, rows, cols: int32; dst: Tilemap; dstrow, dstcol: int32): bool {.tln, importc: "TLN_CopyTiles".}
proc deleteImpl(tilemap: Tilemap): bool {.tln, importc: "TLN_DeleteTilemap".}

proc createTilemap*(rows: int32; cols: int32; tiles: ptr UncheckedArray[Tile]; bgcolor: uint32; tileset: Tileset): Tilemap {.inline.} = (result = createTilemapImpl(rows, cols, tiles, bgcolor, tileset); if result == nil: raise e)
proc loadTilemap*(filename: cstring; layername: cstring = nil): Tilemap {.inline.} = (result = loadTilemapImpl(filename, layername); if result == nil: raise e)
proc clone*(src: Tilemap): Tilemap {.inline.} = (result = cloneImpl(src); if result == nil: raise e)
proc getRows*(tilemap: Tilemap): int32 {.tln, importc: "TLN_GetTilemapRows".}
proc getCols*(tilemap: Tilemap): int32 {.tln, importc: "TLN_GetTilemapCols".}
proc setTileset*(tilemap: Tilemap; tileset: Tileset) {.inline.} = (if not setTilesetImpl(tilemap, tileset): raise e)
proc getTileset*(tilemap: Tilemap): Tileset {.tln, importc: "TLN_GetTilemapTileset".}
proc setTileset*(tilemap: Tilemap; tileset: Tileset; index: int32) {.inline.} = (if not setTilesetImpl(tilemap, tileset, index): raise e)
proc getTileset*(tilemap: Tilemap; index: int32): Tileset {.tln, importc: "TLN_GetTilemapTileset2".}
proc getTile*(tilemap: Tilemap; row, col: int32): Tile {.inline.} = (if not getTileImpl(tilemap, row, col, result): raise e)
proc setTile*(tilemap: Tilemap; row, col: int32; tile: ptr Tile) {.inline.} = (if not setTileImpl(tilemap, row, col, tile): raise e)
proc setTile*(tilemap: Tilemap; row, col: int32; tile: Tile): bool {.inline, discardable.} = setTile(tilemap, row, col, unsafeAddr tile)
proc clearTile*(tilemap: Tilemap; row, col: int32; tile: Tile): bool {.inline, discardable.} =
  ## Same as seting the tile's index & flags to 0.
  setTile(tilemap, row, col, nil)
proc copyTiles*(src: Tilemap; srcrow, srccol, rows, cols: int32; dst: Tilemap; dstrow, dstcol: int32) {.inline.} = (if not copyTilesImpl(src, srcrow, srccol, rows, cols, dst, dstrow, dstcol): raise e)
proc delete*(tilemap: Tilemap) {.inline.} = (if not deleteImpl(tilemap): raise e)

# PALETTE
# -------
# Color palette resources management for sprites and background layers

proc createPaletteImpl(entries: int32): Palette {.tln, importc: "TLN_CreatePalette".}
proc loadPaletteImpl(filename: cstring): Palette {.tln, importc: "TLN_LoadPalette".}
proc cloneImpl(src: Palette): Palette {.tln, importc: "TLN_ClonePalette".}
proc setColorImpl(palette: Palette; color: int32; r, g, b: uint8): bool {.tln, importc: "TLN_SetPaletteColor".}
proc mixPalettesImpl(src1, src2, dst: Palette; factor: uint8): bool {.tln, importc: "TLN_MixPalettes".}
proc addColorImpl(palette: Palette; r, g, b: uint8; start, num: uint8): bool {.tln, importc: "TLN_AddPaletteColor".}
proc subColorImpl(palette: Palette; r, g, b: uint8; start, num: uint8): bool {.tln, importc: "TLN_SubPaletteColor".}
proc modColorImpl(palette: Palette; r, g, b: uint8; start, num: uint8): bool {.tln, importc: "TLN_ModPaletteColor".}
proc deleteImpl(palette: Palette): bool {.tln, importc: "TLN_DeletePalette".}

proc createPalette*(entries: int32): Palette {.inline.} = (result = createPaletteImpl(entries); if result == nil: raise e)
proc loadPalette*(filename: cstring): Palette {.inline.} = (result = loadPaletteImpl(filename); if result == nil: raise e)
proc clone*(src: Palette): Palette {.inline.} = (result = cloneImpl(src); if result == nil: raise e)
proc setColor*(palette: Palette; color: int32; r, g, b: uint8) {.inline.} = (if not setColorImpl(palette, color, r, g, b): raise e)
proc mixPalettes*(src1, src2, dst: Palette; factor: uint8) {.inline.} = (if not mixPalettesImpl(src1, src2, dst, factor): raise e)
proc addColor*(palette: Palette; r, g, b: uint8; start, num: uint8) {.inline.} = (if not addColorImpl(palette, r, g, b, start, num): raise e)
proc subColor*(palette: Palette; r, g, b: uint8; start, num: uint8) {.inline.} = (if not subColorImpl(palette, r, g, b, start, num): raise e)
proc modColor*(palette: Palette; r, g, b: uint8; start, num: uint8) {.inline.} = (if not modColorImpl(palette, r, g, b, start, num): raise e)
proc getData*(palette: Palette; index: int32): ptr UncheckedArray[uint8] {.tln, importc: "TLN_GetPaletteData".}
proc delete*(palette: Palette) {.inline.} = (if not deleteImpl(palette): raise e)

# BITMAP
# ------
# Bitmap management

proc createBitmapImpl(width, height: int32; bpp: int32): Bitmap {.tln, importc: "TLN_CreateBitmap".}
proc loadBitmapImpl(filename: cstring): Bitmap {.tln, importc: "TLN_LoadBitmap".}
proc cloneBitmapImpl(src: Bitmap): Bitmap {.tln, importc: "TLN_CloneBitmap".}
proc setPaletteImpl(bitmap: Bitmap; palette: Palette): bool {.tln, importc: "TLN_SetBitmapPalette".}
proc deleteImpl(bitmap: Bitmap): bool {.tln, importc: "TLN_DeleteBitmap".}

proc createBitmap*(width, height: int32; bpp: int32): Bitmap {.inline.} = (result = createBitmapImpl(width, height, bpp); if result == nil: raise e)
proc loadBitmap*(filename: cstring): Bitmap {.inline.} = (result = loadBitmapImpl(filename); if result == nil: raise e)
proc cloneBitmap*(src: Bitmap): Bitmap {.inline.} = (result = cloneBitmapImpl(src); if result == nil: raise e)
proc getData*(bitmap: Bitmap; x, y: int32): ptr UncheckedArray[uint8] {.tln, importc: "TLN_GetBitmapPtr".}
proc getWidth*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapWidth".}
proc getHeight*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapHeight".}
proc getDepth*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapDepth".}
proc getPitch*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapPitch".}
proc getPalette*(bitmap: Bitmap): Palette {.tln, importc: "TLN_GetBitmapPalette".}
proc setPalette*(bitmap: Bitmap; palette: Palette) {.inline.} = (if not setPaletteImpl(bitmap, palette): raise e)
proc delete*(bitmap: Bitmap) {.inline.} = (if not deleteImpl(bitmap): raise e)

# OBJECTS
# -------
# ObjectList resources management

proc createObjectListImpl(): ObjectList {.tln, importc: "TLN_CreateObjectList".}
proc loadObjectListImpl(filename, layername: cstring): ObjectList {.tln, importc: "TLN_LoadObjectList".}
proc cloneImpl(src: ObjectList): ObjectList {.tln, importc: "TLN_CloneObjectList".}
proc addTileObjectImpl(list: ObjectList; id, gid, flags: uint16; x, y: int32): bool {.tln, importc: "TLN_AddTileObjectToList".}
proc deleteImpl(list: ObjectList): bool {.tln, importc: "TLN_DeleteObjectList".}

proc createObjectList*(): ObjectList {.inline.} = (result = createObjectListImpl(); if result == nil: raise e)
proc loadObjectList*(filename, layername: cstring): ObjectList {.inline.} = (result = loadObjectListImpl(filename, layername); if result == nil: raise e)
proc clone*(src: ObjectList): ObjectList {.inline.} = (result = cloneImpl(src); if result == nil: raise e)
proc addTileObject*(list: ObjectList; id, gid, flags: uint16; x, y: int32) {.inline.} = (if not addTileObjectImpl(list, id, gid, flags, x, y): raise e)
proc getNumObjects*(list: ObjectList): int32 {.tln, importc: "TLN_GetListNumObjects".}
proc getObject*(list: ObjectList; info: var ObjectInfo): bool {.tln, importc: "TLN_GetListObject".}
proc getObject*(list: ObjectList): (ObjectInfo, bool) {.inline.} = result[1] = getObject(list, result[0])
proc delete*(list: ObjectList) {.inline.} = (if not deleteImpl(list): raise e)

# LAYER
# -----
# Background layers management

type Layer* = distinct int32

proc setTilemapImpl(layer: Layer; tilemap: Tilemap): bool {.tln, importc: "TLN_SetLayerTilemap".}
proc setBitmapImpl(layer: Layer; bitmap: Bitmap): bool {.tln, importc: "TLN_SetLayerBitmap".}
proc setPaletteImpl(layer: Layer; palette: Palette): bool {.tln, importc: "TLN_SetLayerPalette".}
proc setPositionImpl(layer: Layer; hstart, vstart: int32): bool {.tln, importc: "TLN_SetLayerPosition".}
proc setScalingImpl(layer: Layer; xfactor, yfactor: float32): bool {.tln, importc: "TLN_SetLayerScaling".}
proc setAffineTransformImpl(layer: Layer; affine: ptr Affine): bool {.tln, importc: "TLN_SetLayerAffineTransform".}
proc setTransformImpl(layer: int32; angle: float32; dx, dy, sx, sy: float32): bool {.tln, importc: "TLN_SetLayerTransform".}
proc setPixelMappingImpl(layer: Layer; table: ptr UncheckedArray[PixelMap]): bool {.tln, importc: "TLN_SetLayerPixelMapping".}
proc setBlendModeImpl(layer: Layer; mode: Blend; factor: uint8): bool {.tln, importc: "TLN_SetLayerBlendMode".}
proc setColumnOffsetImpl(layer: Layer; offset: ptr UncheckedArray[int32]): bool {.tln, importc: "TLN_SetLayerColumnOffset".}
proc setClipImpl(layer: Layer; x1, y1, x2, y2: int32): bool {.tln, importc: "TLN_SetLayerClip".}
proc disableClipImpl(layer: Layer): bool {.tln, importc: "TLN_DisableLayerClip".}
proc setMosaicImpl(layer: Layer; width, height: int32): bool {.tln, importc: "TLN_SetLayerMosaic".}
proc disableMosaicImpl(layer: Layer): bool {.tln, importc: "TLN_DisableLayerMosaic".}
proc resetLayerModeImpl(layer: Layer): bool {.tln, importc: "TLN_ResetLayerMode".}
proc setObjectsImpl(layer: Layer; objects: ObjectList; tileset: Tileset): bool {.tln, importc: "TLN_SetLayerObjects".}
proc setPriorityImpl(layer: Layer; enable: bool): bool {.tln, importc: "TLN_SetLayerPriority".}
proc setParentImpl(layer: Layer; parent: int32): bool {.tln, importc: "TLN_SetLayerParent".}
proc disableParentImpl(layer: Layer): bool {.tln, importc: "TLN_DisableLayerParent".}
proc disableImpl(layer: Layer): bool {.tln, importc: "TLN_DisableLayer".}
proc enableImpl(layer: Layer): bool {.tln, importc: "TLN_EnableLayer".}
proc getTileInfoImpl(layer: Layer; x, y: int32; info: var TileInfo): bool {.tln, importc: "TLN_GetLayerTile".}
proc setParallaxFactorImpl(layer: Layer; x, y: float32): bool {.tln, importc: "TLN_SetLayerParallaxFactor".}

proc setTilemap*(layer: Layer; tilemap: Tilemap) {.inline.} = (if not setTilemapImpl(layer, tilemap): raise e)
proc setBitmap*(layer: Layer; bitmap: Bitmap) {.inline.} = (if not setBitmapImpl(layer, bitmap): raise e)
proc setPalette*(layer: Layer; palette: Palette) {.inline.} = (if not setPaletteImpl(layer, palette): raise e)
proc setPosition*(layer: Layer; hstart, vstart: int32) {.inline.} = (if not setPositionImpl(layer, hstart, vstart): raise e)
proc setScaling*(layer: Layer; xfactor, yfactor: float32) {.inline.} = (if not setScalingImpl(layer, xfactor, yfactor): raise e)
proc setAffineTransform*(layer: Layer; affine: ptr Affine) {.inline.} = (if not setAffineTransformImpl(layer, affine): raise e)
proc setAffineTransform*(layer: Layer; affine: Affine): bool {.inline, discardable.} = setAffineTransform(layer, unsafeAddr affine)
proc disableAffineTransform*(layer: Layer): bool {.inline, discardable.} = setAffineTransform(layer, nil)
proc setTransform*(layer: int32; angle: float32; dx, dy, sx, sy: float32) {.inline.} = (if not setTransformImpl(layer, angle, dx, dy, sx, sy): raise e)
proc setPixelMapping*(layer: Layer; table: ptr UncheckedArray[PixelMap]) {.inline.} = (if not setPixelMappingImpl(layer, table): raise e)
proc disablePixelMapping*(layer: Layer): bool {.inline, discardable.} = setPixelMapping(layer, nil)
proc setBlendMode*(layer: Layer; mode: Blend; factor: uint8) {.inline.} = (if not setBlendModeImpl(layer, mode, factor): raise e)
proc setColumnOffset*(layer: Layer; offset: ptr UncheckedArray[int32]) {.inline.} = (if not setColumnOffsetImpl(layer, offset): raise e)
proc setClip*(layer: Layer; x1, y1, x2, y2: int32) {.inline.} = (if not setClipImpl(layer, x1, y1, x2, y2): raise e)
proc disableClip*(layer: Layer) {.inline.} = (if not disableClipImpl(layer): raise e)
proc setMosaic*(layer: Layer; width, height: int32) {.inline.} = (if not setMosaicImpl(layer, width, height): raise e)
proc disableMosaic*(layer: Layer) {.inline.} = (if not disableMosaicImpl(layer): raise e)
proc resetLayerMode*(layer: Layer) {.inline.} = (if not resetLayerModeImpl(layer): raise e)
proc setObjects*(layer: Layer; objects: ObjectList; tileset: Tileset) {.inline.} = (if not setObjectsImpl(layer, objects, tileset): raise e)
proc setPriority*(layer: Layer; enable: bool) {.inline.} = (if not setPriorityImpl(layer, enable): raise e)
proc setParent*(layer: Layer; parent: int32) {.inline.} = (if not setParentImpl(layer, parent): raise e)
proc disableParent*(layer: Layer) {.inline.} = (if not disableParentImpl(layer): raise e)
proc disable*(layer: Layer) {.inline.} = (if not disableImpl(layer): raise e)
proc enable*(layer: Layer) {.inline.} = (if not enableImpl(layer): raise e)
proc getType*(layer: Layer): LayerType {.tln, importc: "TLN_GetLayerType".}
proc getPalette*(layer: Layer): Palette {.tln, importc: "TLN_GetLayerPalette".}
proc getTileset*(layer: Layer): Tileset {.tln, importc: "TLN_GetLayerTileset".}
proc getTilemap*(layer: Layer): Tilemap {.tln, importc: "TLN_GetLayerTilemap".}
proc getBitmap*(layer: Layer): Bitmap {.tln, importc: "TLN_GetLayerBitmap".}
proc getObjects*(layer: Layer): ObjectList {.tln, importc: "TLN_GetLayerObjects".}
proc getTileInfo*(layer: Layer; x, y: int32): TileInfo {.inline.} = (if not getTileInfoImpl(layer, x, y, result): raise e)
proc getWidth*(layer: Layer): int32 {.tln, importc: "TLN_GetLayerWidth".}
proc getHeight*(layer: Layer): int32 {.tln, importc: "TLN_GetLayerHeight".}
proc setParallaxFactor*(layer: Layer; x, y: float32) {.inline.} = (if not setParallaxFactorImpl(layer, x, y): raise e)

# SPRITE
# ------
# Sprites management

type Sprite* = distinct int32

proc configSpriteImpl(sprite: Sprite; spriteset: Spriteset; flags: uint32): bool {.tln, importc: "TLN_ConfigSprite".}
proc setSpriteSetImpl(sprite: Sprite; spriteset: Spriteset): bool {.tln, importc: "TLN_SetSpriteSet".}
proc setFlagsImpl(sprite: Sprite; flags: uint32): bool {.tln, importc: "TLN_SetSpriteFlags".}
proc enableFlagImpl(sprite: Sprite; flag: uint32; enable: bool): bool {.tln, importc: "TLN_EnableSpriteFlag".}
proc setPivotImpl(sprite: Sprite; px, py: float32): bool {.tln, importc: "TLN_SetSpritePivot".}
proc setPositionImpl(sprite: Sprite; x, y: int32): bool {.tln, importc: "TLN_SetSpritePosition".}
proc setPictureImpl(sprite: Sprite; entry: int32): bool {.tln, importc: "TLN_SetSpritePicture".}
proc setPaletteImpl(sprite: Sprite; palette: Palette): bool {.tln, importc: "TLN_SetSpritePalette".}
proc setBlendModeImpl(sprite: Sprite; mode: Blend; factor: uint8): bool {.tln, importc: "TLN_SetSpriteBlendMode".}
proc setScalingImpl(sprite: Sprite; sx: float32; sy: float32): bool {.tln, importc: "TLN_SetSpriteScaling".}
proc resetScalingImpl(sprite: Sprite): bool {.tln, importc: "TLN_ResetSpriteScaling".}
proc enableCollisionImpl(sprite: Sprite; enable: bool): bool {.tln, importc: "TLN_EnableSpriteCollision".}
proc getStateImpl(sprite: Sprite; state: var SpriteState): bool {.tln, importc: "TLN_GetSpriteState".}
proc setFirstSpriteImpl(sprite: Sprite): bool {.tln, importc: "TLN_SetFirstSprite".}
proc setNextSpriteImpl(sprite, next: Sprite): bool {.tln, importc: "TLN_SetNextSprite".}
proc enableMaskingImpl(sprite: Sprite; enable: bool): bool {.tln, importc: "TLN_EnableSpriteMasking".}
proc setAnimationImpl(sprite: Sprite; sequence: Sequence; loop: int32): bool {.tln, importc: "TLN_SetSpriteAnimation".}
proc disableAnimationImpl(sprite: Sprite): bool {.tln, importc: "TLN_DisableSpriteAnimation".}
proc pauseAnimationImpl(sprite: Sprite): bool {.tln, importc: "TLN_PauseSpriteAnimation".}
proc resumeAnimationImpl(sprite: Sprite): bool {.tln, importc: "TLN_ResumeSpriteAnimation".}
proc disableImpl(sprite: Sprite): bool {.tln, importc: "TLN_DisableSprite".}
proc getPaletteImpl(sprite: Sprite): Palette {.tln, importc: "TLN_GetSpritePalette".}

proc configSprite*(sprite: Sprite; spriteset: Spriteset; flags: uint32) {.inline.} = (if not configSpriteImpl(sprite, spriteset, flags): raise e)
proc setSpriteSet*(sprite: Sprite; spriteset: Spriteset) {.inline.} = (if not setSpriteSetImpl(sprite, spriteset): raise e)
proc setFlags*(sprite: Sprite; flags: uint32) {.inline.} = (if not setFlagsImpl(sprite, flags): raise e)
proc enableFlag*(sprite: Sprite; flag: uint32; enable: bool) {.inline.} = (if not enableFlagImpl(sprite, flag, enable): raise e)
proc setPivot*(sprite: Sprite; px, py: float32) {.inline.} = (if not setPivotImpl(sprite, px, py): raise e)
proc setPosition*(sprite: Sprite; x, y: int32) {.inline.} = (if not setPositionImpl(sprite, x, y): raise e)
proc setPicture*(sprite: Sprite; entry: int32) {.inline.} = (if not setPictureImpl(sprite, entry): raise e)
proc setPalette*(sprite: Sprite; palette: Palette) {.inline.} = (if not setPaletteImpl(sprite, palette): raise e)
proc setBlendMode*(sprite: Sprite; mode: Blend; factor: uint8) {.inline.} = (if not setBlendModeImpl(sprite, mode, factor): raise e)
proc setScaling*(sprite: Sprite; sx: float32; sy: float32) {.inline.} = (if not setScalingImpl(sprite, sx, sy): raise e)
proc resetScaling*(sprite: Sprite) {.inline.} = (if not resetScalingImpl(sprite): raise e)
# proc setRotation*(sprite: Sprite; angle: float32): bool {.tln, importc: "TLN_SetSpriteRotation".}
# proc resetRotation*(sprite: Sprite): bool {.tln, importc: "TLN_ResetSpriteRotation".}
proc getSpritePicture*(sprite: Sprite): int32 {.tln, importc: "TLN_GetSpritePicture".}
proc getAvailableSprite*(): int32 {.tln, importc: "TLN_GetAvailableSprite".}
proc enableCollision*(sprite: Sprite; enable: bool) {.inline.} = (if not enableCollisionImpl(sprite, enable): raise e)
proc getCollision*(sprite: Sprite): bool {.tln, importc: "TLN_GetSpriteCollision".}
proc getState*(sprite: Sprite): SpriteState {.inline.} = (if not getStateImpl(sprite, result): raise e)
proc setFirstSprite*(sprite: Sprite) {.inline.} = (if not setFirstSpriteImpl(sprite): raise e)
proc setNextSprite*(sprite, next: Sprite) {.inline.} = (if not setNextSpriteImpl(sprite, next): raise e)
proc enableMasking*(sprite: Sprite; enable: bool) {.inline.} = (if not enableMaskingImpl(sprite, enable): raise e)
proc setSpritesMaskRegion*(topLine, bottomLine: int32) {.tln, importc: "TLN_SetSpritesMaskRegion".}
proc setAnimation*(sprite: Sprite; sequence: Sequence; loop: int32) {.inline.} = (if not setAnimationImpl(sprite, sequence, loop): raise e)
proc disableAnimation*(sprite: Sprite) {.inline.} = (if not disableAnimationImpl(sprite): raise e)
proc pauseAnimation*(sprite: Sprite) {.inline.} = (if not pauseAnimationImpl(sprite): raise e)
proc resumeAnimation*(sprite: Sprite) {.inline.} = (if not resumeAnimationImpl(sprite): raise e)
proc disable*(sprite: Sprite) {.inline.} = (if not disableImpl(sprite): raise e)
proc getPalette*(sprite: Sprite): Palette {.inline.} = (result = getPaletteImpl(sprite); if result == nil: raise e)

# SEQUENCE
# --------
# Sequence resources management for layer, sprite and palette animations

proc createSequenceImpl(name: cstring; target: int32; numFrames: int32; frames: ptr UncheckedArray[SequenceFrame]): Sequence {.tln, importc: "TLN_CreateSequence".}
proc createCycleImpl(name: cstring; numStrips: int32; strips: ptr UncheckedArray[ColorStrip]): Sequence {.tln, importc: "TLN_CreateCycle".}
proc createSpriteSequenceImpl(name: cstring; spriteset: Spriteset; basename: cstring; delay: int32): Sequence {.tln, importc: "TLN_CreateSpriteSequence".}
proc cloneImpl(src: Sequence): Sequence {.tln, importc: "TLN_CloneSequence".}
proc getInfoImpl(sequence: Sequence; info: var SequenceInfo): bool {.tln, importc: "TLN_GetSequenceInfo".}
proc deleteImpl(sequence: Sequence): bool {.tln, importc: "TLN_DeleteSequence".}

proc createSequence*(name: cstring; target: int32; numFrames: int32; frames: ptr UncheckedArray[SequenceFrame]): Sequence {.inline.} = (result = createSequenceImpl(name, target, numFrames, frames); if result == nil: raise e)
proc createCycle*(name: cstring; numStrips: int32; strips: ptr UncheckedArray[ColorStrip]): Sequence {.inline.} = (result = createCycleImpl(name, numStrips, strips); if result == nil: raise e)
proc createSpriteSequence*(name: cstring; spriteset: Spriteset; basename: cstring; delay: int32): Sequence {.inline.} = (result = createSpriteSequenceImpl(name, spriteset, basename, delay); if result == nil: raise e)
proc clone*(src: Sequence): Sequence {.inline.} = (result = cloneImpl(src); if result == nil: raise e)
proc getInfo*(sequence: Sequence): SequenceInfo {.inline.} = (if not getInfoImpl(sequence, result): raise e)
proc delete*(sequence: Sequence) {.inline.} = (if not deleteImpl(sequence): raise e)

# SEQUENCEPACK
# ------------
# Sequence pack manager for grouping and finding sequences

proc createSequencePackImpl(): SequencePack {.tln, importc: "TLN_CreateSequencePack".}
proc loadSequencePackImpl(filename: cstring): SequencePack {.tln, importc: "TLN_LoadSequencePack".}
proc getSequenceImpl(sp: SequencePack; index: int32): Sequence {.tln, importc: "TLN_GetSequence".}
proc findSequenceImpl(sp: SequencePack; name: cstring): Sequence {.tln, importc: "TLN_FindSequence".}
proc addSequenceImpl(sp: SequencePack; sequence: Sequence): bool {.tln, importc: "TLN_AddSequenceToPack".}
proc deleteImpl(sp: SequencePack): bool {.tln, importc: "TLN_DeleteSequencePack".}

proc createSequencePack*(): SequencePack {.inline.} = (result = createSequencePackImpl(); if result == nil: raise e)
proc loadSequencePack*(filename: cstring): SequencePack {.inline.} = (result = loadSequencePackImpl(filename); if result == nil: raise e)
proc getSequence*(sp: SequencePack; index: int32): Sequence {.inline.} = (result = getSequenceImpl(sp, index); if result == nil: raise e)
proc findSequence*(sp: SequencePack; name: cstring): Sequence {.inline.} = (result = findSequenceImpl(sp, name); if result == nil: raise e)
proc getCount*(sp: SequencePack): int32 {.tln, importc: "TLN_GetSequencePackCount".}
proc addSequence*(sp: SequencePack; sequence: Sequence) {.inline.} = (if not addSequenceImpl(sp, sequence): raise e)
proc delete*(sp: SequencePack) {.inline.} = (if not deleteImpl(sp): raise e)

# ANIMATION
# ---------
# Color cycle animation

proc setPaletteAnimationImpl(index: int32; palette: Palette; sequence: Sequence; blend: bool): bool {.tln, importc: "TLN_SetPaletteAnimation".}
proc setPaletteAnimationSourceImpl(index: int32; a2: Palette): bool {.tln, importc: "TLN_SetPaletteAnimationSource".}
proc setAnimationDelayImpl(index, frame, delay: int32): bool {.tln, importc: "TLN_SetAnimationDelay".}
proc disablePaletteAnimationImpl(index: int32): bool {.tln, importc: "TLN_DisablePaletteAnimation".}

proc setPaletteAnimation*(index: int32; palette: Palette; sequence: Sequence; blend: bool) {.inline.} = (if not setPaletteAnimationImpl(index, palette, sequence, blend): raise e)
proc setPaletteAnimationSource*(index: int32; a2: Palette) {.inline.} = (if not setPaletteAnimationSourceImpl(index, a2): raise e)
proc getAnimationState*(index: int32): bool {.tln, importc: "TLN_GetAnimationState".}
proc setAnimationDelay*(index, frame, delay: int32) {.inline.} = (if not setAnimationDelayImpl(index, frame, delay): raise e)
proc getAvailableAnimation*(): int32 {.tln, importc: "TLN_GetAvailableAnimation".}
proc disablePaletteAnimation*(index: int32) {.inline.} = (if not disablePaletteAnimationImpl(index): raise e)

# WORLD
# -----
# World management

proc loadWorldImpl(tmxfile: cstring; firstLayer: int32): bool {.tln, importc: "TLN_LoadWorld".}
proc setSpriteWorldPositionImpl(nsprite: int32; x, y: int32): bool {.tln, importc: "TLN_SetSpriteWorldPosition".}

proc loadWorld*(tmxfile: cstring; firstLayer: int32) {.inline.} = (if not loadWorldImpl(tmxfile, firstLayer): raise e)
proc setWorldPosition*(x, y: int32) {.tln, importc: "TLN_SetWorldPosition".}
proc setSpriteWorldPosition*(nsprite: int32; x, y: int32) {.inline.} = (if not setSpriteWorldPositionImpl(nsprite, x, y): raise e)
proc releaseWorld*() {.tln, importc: "TLN_ReleaseWorld".}

