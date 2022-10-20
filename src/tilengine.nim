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

  Engine* = distinct pointer         ## Engine context
  Tileset* = distinct pointer        ## Opaque tileset reference
  Tilemap* = distinct pointer        ## Opaque tilemap reference
  Palette* = distinct pointer        ## Opaque palette reference
  Spriteset* = distinct pointer      ## Opaque sspriteset reference
  Sequence* = distinct pointer       ## Opaque sequence reference
  SequencePack* = distinct pointer   ## Opaque sequence pack reference
  Bitmap* = distinct pointer         ## Opaque bitmap reference
  ObjectList* = distinct pointer     ## Opaque object list reference
  
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
    Player1,                  ## Player 1
    Player2,                  ## Player 2
    Player3,                  ## Player 3
    Player4                   ## Player 4
  
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


# CreateWindow flags. Can be none or a combination of the following:

# TODO: replace with something idiomatic

const
  cwfFullscreen* = (1 shl 0)     ## Create a fullscreen window
  cwfVsync* = (1 shl 1)          ## Sync frame updates with vertical retrace
  cwfS1* = (1 shl 2)             ## Create a window the same size as the framebuffer
  cwfS2* = (2 shl 2)             ## Create a window 2x the size the framebuffer
  cwfS3* = (3 shl 2)             ## Create a window 3x the size the framebuffer
  cwfS4* = (4 shl 2)             ## Create a window 4x the size the framebuffer
  cwfS5* = (5 shl 2)             ## Create a window 5x the size the framebuffer
  cwfNearest* = (1 shl 6)        ## Unfiltered upscaling

# Error codes

type
  Error* = enum
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

# SETUP
# -------
# Basic setup and management

proc init*(hres, vres, numlayers, numsprites, numanimations: int32): Engine {.tln, importc: "TLN_Init".}
proc deinit*() {.tln, importc: "TLN_Deinit".}
proc deleteContext*(context: Engine): bool {.tln, importc: "TLN_DeleteContext", discardable.}
proc setContext*(context: Engine): bool {.tln, importc: "TLN_SetContext", discardable.}
proc getContext*(): Engine {.tln, importc: "TLN_GetContext".}
proc getWidth*(): int32 {.tln, importc: "TLN_GetWidth".}
proc getHeight*(): int32 {.tln, importc: "TLN_GetHeight".}
proc getNumObjects*(): uint32 {.tln, importc: "TLN_GetNumObjects".}
proc getUsedMemory*(): uint32 {.tln, importc: "TLN_GetUsedMemory".}
proc getVersion*(): uint32 {.tln, importc: "TLN_GetVersion".}
proc getNumLayers*(): int32 {.tln, importc: "TLN_GetNumLayers".}
proc getNumSprites*(): int32 {.tln, importc: "TLN_GetNumSprites".}
proc setBgColor*(r, g, b: uint8) {.tln, importc: "TLN_SetBGColor".}
proc setBgColorFromTilemap*(tilemap: Tilemap): bool {.tln, importc: "TLN_SetBGColorFromTilemap", discardable.}
proc disableBgColor*() {.tln, importc: "TLN_DisableBGColor".}
proc setBgBitmap*(bitmap: Bitmap): bool {.tln, importc: "TLN_SetBGBitmap", discardable.}
proc setBgPalette*(palette: Palette): bool {.tln, importc: "TLN_SetBGPalette", discardable.}
proc setRasterCallback*(a1: VideoCallback) {.tln, importc: "TLN_SetRasterCallback".}
proc setFrameCallback*(a1: VideoCallback) {.tln, importc: "TLN_SetFrameCallback".}
proc setRenderTarget*(data: ptr UncheckedArray[uint8]; pitch: int32) {.tln, importc: "TLN_SetRenderTarget".}
proc updateFrame*(frame: int32) {.tln, importc: "TLN_UpdateFrame".}
proc setLoadPath*(path: cstring) {.tln, importc: "TLN_SetLoadPath".}
proc setCustomBlendFunction*(a1: BlendFunction) {.tln, importc: "TLN_SetCustomBlendFunction".}
proc setLogLevel*(logLevel: LogLevel) {.tln, importc: "TLN_SetLogLevel".}
proc openResourcePack*(filename, key: cstring): bool {.tln, importc: "TLN_OpenResourcePack", discardable.}
proc closeResourcePack*() {.tln, importc: "TLN_CloseResourcePack".}

# ERRORS
# -------
# Basic setup and management

proc setLastError*(error: Error) {.tln, importc: "TLN_SetLastError".}
proc getLastError*(): Error {.tln, importc: "TLN_GetLastError".}
proc getErrorString*(error: Error): cstring {.tln, importc: "TLN_GetErrorString".}

# WINDOWING
# -------
# Built-in window and input management

proc createWindow*(overlay: cstring = nil; flags: int32 = 0): bool {.tln, importc: "TLN_CreateWindow".}
proc createWindowThread*(overlay: cstring = nil; flags: int32 = 0): bool {.tln, importc: "TLN_CreateWindowThread".}
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
# -------
# Spriteset resources management for sprites

proc createSpriteset*(bitmap: Bitmap; data: SpriteData; numEntries: int32): Spriteset {.tln, importc: "TLN_CreateSpriteset".}
proc loadSpriteset*(name: cstring): Spriteset {.tln, importc: "TLN_LoadSpriteset".}
proc clone*(src: Spriteset): Spriteset {.tln, importc: "TLN_CloneSpriteset".}
proc getSpriteInfo*(spriteset: Spriteset; entry: int32; info: var SpriteInfo): bool {.tln, importc: "TLN_GetSpriteInfo", discardable.}
proc getSpriteInfo*(spriteset: Spriteset; entry: int32): (SpriteInfo, bool) {.inline.} =
  result[1] = getSpriteInfo(spriteset, entry, result[0])
proc getPalette*(spriteset: Spriteset): Palette {.tln, importc: "TLN_GetSpritesetPalette".}
proc findSprite*(spriteset: Spriteset; name: cstring): int32 {.tln, importc: "TLN_FindSpritesetSprite".}
proc setData*(spriteset: Spriteset; entry: int32; data: SpriteData; pixels: pointer; pitch: int32): bool {.tln, importc: "TLN_SetSpritesetData", discardable.}
proc delete*(Spriteset: Spriteset): bool {.tln, importc: "TLN_DeleteSpriteset", discardable.}

# TILESET
# -------
# Tileset resources management for background layers

proc createTileset*(numtiles: int32; width, height: int32; palette: Palette; sp: SequencePack; attributes: ptr UncheckedArray[TileAttributes]): Tileset {.tln, importc: "TLN_CreateTileset".}
proc createImageTileset*(numtiles: int32; images: ptr UncheckedArray[TileImage]): Tileset {.tln, importc: "TLN_CreateImageTileset".}
proc loadTileset*(filename: cstring): Tileset {.tln, importc: "TLN_LoadTileset".}
proc clone*(src: Tileset): Tileset {.tln, importc: "TLN_CloneTileset".}
proc setPixels*(tileset: Tileset; entry: int32; srcdata: ptr UncheckedArray[uint8]; srcpitch: int32): bool {.tln, importc: "TLN_SetTilesetPixels", discardable.}
proc getTileWidth*(tileset: Tileset): int32 {.tln, importc: "TLN_GetTileWidth".}
proc getTileHeight*(tileset: Tileset): int32 {.tln, importc: "TLN_GetTileHeight".}
proc getNumTiles*(tileset: Tileset): int32 {.tln, importc: "TLN_GetTilesetNumTiles".}
proc getPalette*(tileset: Tileset): Palette {.tln, importc: "TLN_GetTilesetPalette".}
proc getSequencePack*(tileset: Tileset): SequencePack {.tln, importc: "TLN_GetTilesetSequencePack".}
proc delete*(tileset: Tileset): bool {.tln, importc: "TLN_DeleteTileset", discardable.}

# TILEMAP
# -------
# Tilemap resources management for background layers

proc createTilemap*(rows: int32; cols: int32; tiles: ptr UncheckedArray[Tile]; bgcolor: uint32; tileset: Tileset): Tilemap {.tln, importc: "TLN_CreateTilemap".}
proc loadTilemap*(filename: cstring; layername: cstring = nil): Tilemap {.tln, importc: "TLN_LoadTilemap".}
proc clone*(src: Tilemap): Tilemap {.tln, importc: "TLN_CloneTilemap".}
proc getRows*(tilemap: Tilemap): int32 {.tln, importc: "TLN_GetTilemapRows".}
proc getCols*(tilemap: Tilemap): int32 {.tln, importc: "TLN_GetTilemapCols".}
proc setTileset*(tilemap: Tilemap; tileset: Tileset): bool {.tln, importc: "TLN_SetTilemapTileset", discardable.}
proc getTileset*(tilemap: Tilemap): Tileset {.tln, importc: "TLN_GetTilemapTileset".}
proc setTileset*(tilemap: Tilemap; tileset: Tileset; index: int32): bool {.tln, importc: "TLN_SetTilemapTileset2", discardable.}
proc getTileset*(tilemap: Tilemap; index: int32): Tileset {.tln, importc: "TLN_GetTilemapTileset2".}
proc getTile*(tilemap: Tilemap; row, col: int32; tile: var Tile): bool {.tln, importc: "TLN_GetTilemapTile", discardable.}
proc getTile*(tilemap: Tilemap; row, col: int32): (Tile, bool) {.inline.} =
  result[1] = getTile(tilemap, row, col, result[0])
proc setTile*(tilemap: Tilemap; row, col: int32; tile: ptr Tile): bool {.tln, importc: "TLN_SetTilemapTile", discardable.}
proc setTile*(tilemap: Tilemap; row, col: int32; tile: Tile): bool {.inline, discardable.} =
  setTile(tilemap, row, col, unsafeAddr tile)
proc clearTile*(tilemap: Tilemap; row, col: int32; tile: Tile): bool {.inline, discardable.} =
  ## Same as seting the tile's index & flags to 0.
  setTile(tilemap, row, col, nil)
proc copyTiles*(src: Tilemap; srcrow, srccol, rows, cols: int32; dst: Tilemap; dstrow, dstcol: int32): bool {.tln, importc: "TLN_CopyTiles", discardable.}
proc delete*(tilemap: Tilemap): bool {.tln, importc: "TLN_DeleteTilemap", discardable.}

# PALETTE
# -------
# Color palette resources management for sprites and background layers

proc createPalette*(entries: int32): Palette {.tln, importc: "TLN_CreatePalette".}
proc loadPalette*(filename: cstring): Palette {.tln, importc: "TLN_LoadPalette".}
proc clone*(src: Palette): Palette {.tln, importc: "TLN_ClonePalette".}
proc setColor*(palette: Palette; color: int32; r, g, b: uint8): bool {.tln, importc: "TLN_SetPaletteColor", discardable.}
proc mixPalettes*(src1: Palette; src2: Palette; dst: Palette; factor: uint8): bool {.tln, importc: "TLN_MixPalettes", discardable.}
proc addColor*(palette: Palette; r, g, b: uint8; start, num: uint8): bool {.tln, importc: "TLN_AddPaletteColor", discardable.}
proc subColor*(palette: Palette; r, g, b: uint8; start, num: uint8): bool {.tln, importc: "TLN_SubPaletteColor", discardable.}
proc modColor*(palette: Palette; r, g, b: uint8; start, num: uint8): bool {.tln, importc: "TLN_ModPaletteColor", discardable.}
proc getData*(palette: Palette; index: int32): ptr UncheckedArray[uint8] {.tln, importc: "TLN_GetPaletteData".}
proc delete*(palette: Palette): bool {.tln, importc: "TLN_DeletePalette", discardable.}

# BITMAP
# ------
# Bitmap management

proc createBitmap*(width, height: int32; bpp: int32): Bitmap {.tln, importc: "TLN_CreateBitmap".}
proc loadBitmap*(filename: cstring): Bitmap {.tln, importc: "TLN_LoadBitmap".}
proc cloneBitmap*(src: Bitmap): Bitmap {.tln, importc: "TLN_CloneBitmap".}
proc getData*(bitmap: Bitmap; x, y: int32): ptr UncheckedArray[uint8] {.tln, importc: "TLN_GetBitmapPtr".}
proc getWidth*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapWidth".}
proc getHeight*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapHeight".}
proc getDepth*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapDepth".}
proc getPitch*(bitmap: Bitmap): int32 {.tln, importc: "TLN_GetBitmapPitch".}
proc getPalette*(bitmap: Bitmap): Palette {.tln, importc: "TLN_GetBitmapPalette".}
proc setPalette*(bitmap: Bitmap; palette: Palette): bool {.tln, importc: "TLN_SetBitmapPalette", discardable.}
proc delete*(bitmap: Bitmap): bool {.tln, importc: "TLN_DeleteBitmap", discardable.}

# OBJECTS
# -------
# ObjectList resources management

proc createObjectList*(): ObjectList {.tln, importc: "TLN_CreateObjectList".}
proc loadObjectList*(filename, layername: cstring): ObjectList {.tln, importc: "TLN_LoadObjectList".}
proc addTileObject*(list: ObjectList; id, gid, flags: uint16; x, y: int32): bool {.tln, importc: "TLN_AddTileObjectToList", discardable.}
proc clone*(src: ObjectList): ObjectList {.tln, importc: "TLN_CloneObjectList".}
proc getNumObjects*(list: ObjectList): int32 {.tln, importc: "TLN_GetListNumObjects".}
proc getObject*(list: ObjectList; info: var ObjectInfo): bool {.tln, importc: "TLN_GetListObject".}
proc getObject*(list: ObjectList): (ObjectInfo, bool) {.inline.} =
  result[1] = getObject(list, result[0])
proc delete*(list: ObjectList): bool {.tln, importc: "TLN_DeleteObjectList", discardable.}

# LAYER
# -----
# Background layers management

type Layer* = distinct int32

proc setTilemap*(layer: Layer; tilemap: Tilemap): bool {.tln, importc: "TLN_SetLayerTilemap", discardable.}
proc setBitmap*(layer: Layer; bitmap: Bitmap): bool {.tln, importc: "TLN_SetLayerBitmap", discardable.}
proc setPalette*(layer: Layer; palette: Palette): bool {.tln, importc: "TLN_SetLayerPalette", discardable.}
proc setPosition*(layer: Layer; hstart, vstart: int32): bool {.tln, importc: "TLN_SetLayerPosition", discardable.}
proc setScaling*(layer: Layer; xfactor, yfactor: float32): bool {.tln, importc: "TLN_SetLayerScaling", discardable.}
proc setAffineTransform*(layer: Layer; affine: ptr Affine): bool {.tln, importc: "TLN_SetLayerAffineTransform", discardable.}
proc setAffineTransform*(layer: Layer; affine: Affine): bool {.inline, discardable.} = setAffineTransform(layer, unsafeAddr affine)
proc disableAffineTransform*(layer: Layer): bool {.inline, discardable.} = setAffineTransform(layer, nil)
proc setTransform*(layer: int32; angle: float32; dx, dy, sx, sy: float32): bool {.tln, importc: "TLN_SetLayerTransform", discardable.}
proc setPixelMapping*(layer: Layer; table: ptr UncheckedArray[PixelMap]): bool {.tln, importc: "TLN_SetLayerPixelMapping", discardable.}
proc disablePixelMapping*(layer: Layer): bool {.inline, discardable.} = setPixelMapping(layer, nil)
proc setBlendMode*(layer: Layer; mode: Blend; factor: uint8): bool {.tln, importc: "TLN_SetLayerBlendMode", discardable.}
proc setColumnOffset*(layer: Layer; offset: ptr UncheckedArray[int32]): bool {.tln, importc: "TLN_SetLayerColumnOffset", discardable.}
proc setClip*(layer: Layer; x1, y1, x2, y2: int32): bool {.tln, importc: "TLN_SetLayerClip", discardable.}
proc disableClip*(layer: Layer): bool {.tln, importc: "TLN_DisableLayerClip", discardable.}
proc setMosaic*(layer: Layer; width, height: int32): bool {.tln, importc: "TLN_SetLayerMosaic", discardable.}
proc disableMosaic*(layer: Layer): bool {.tln, importc: "TLN_DisableLayerMosaic", discardable.}
proc resetLayerMode*(layer: Layer): bool {.tln, importc: "TLN_ResetLayerMode", discardable.}
proc setObjects*(layer: Layer; objects: ObjectList; tileset: Tileset): bool {.tln, importc: "TLN_SetLayerObjects", discardable.}
proc setPriority*(layer: Layer; enable: bool): bool {.tln, importc: "TLN_SetLayerPriority", discardable.}
proc setParent*(layer: Layer; parent: int32): bool {.tln, importc: "TLN_SetLayerParent", discardable.}
proc disableParent*(layer: Layer): bool {.tln, importc: "TLN_DisableLayerParent", discardable.}
proc disable*(layer: Layer): bool {.tln, importc: "TLN_DisableLayer", discardable.}
proc enable*(layer: Layer): bool {.tln, importc: "TLN_EnableLayer", discardable.}
proc getType*(layer: Layer): LayerType {.tln, importc: "TLN_GetLayerType".}
proc getPalette*(layer: Layer): Palette {.tln, importc: "TLN_GetLayerPalette".}
proc getTileset*(layer: Layer): Tileset {.tln, importc: "TLN_GetLayerTileset".}
proc getTilemap*(layer: Layer): Tilemap {.tln, importc: "TLN_GetLayerTilemap".}
proc getBitmap*(layer: Layer): Bitmap {.tln, importc: "TLN_GetLayerBitmap".}
proc getObjects*(layer: Layer): ObjectList {.tln, importc: "TLN_GetLayerObjects".}
proc getTileInfo*(layer: Layer; x, y: int32; info: var TileInfo): bool {.tln, importc: "TLN_GetLayerTile", discardable.}
proc getTileInfo*(layer: Layer; x, y: int32): (TileInfo, bool) {.inline.} =
  result[1] = getTileInfo(layer, x, y, result[0])
proc getWidth*(layer: Layer): int32 {.tln, importc: "TLN_GetLayerWidth".}
proc getHeight*(layer: Layer): int32 {.tln, importc: "TLN_GetLayerHeight".}
proc setParallaxFactor*(layer: Layer; x, y: float32): bool {.tln, importc: "TLN_SetLayerParallaxFactor", discardable.}

# SPRITE
# -------
# Sprites management

type Sprite* = distinct int32

proc configSprite*(sprite: Sprite; spriteset: Spriteset; flags: uint32): bool {.tln, importc: "TLN_ConfigSprite", discardable.}
proc setSpriteSet*(sprite: Sprite; spriteset: Spriteset): bool {.tln, importc: "TLN_SetSpriteSet", discardable.}
proc setFlags*(sprite: Sprite; flags: uint32): bool {.tln, importc: "TLN_SetSpriteFlags", discardable.}
proc enableFlag*(sprite: Sprite; flag: uint32; enable: bool): bool {.tln, importc: "TLN_EnableSpriteFlag", discardable.}
proc setPivot*(sprite: Sprite; px: float32; py: float32): bool {.tln, importc: "TLN_SetSpritePivot", discardable.}
proc setPosition*(sprite: Sprite; x, y: int32): bool {.tln, importc: "TLN_SetSpritePosition", discardable.}
proc setPicture*(sprite: Sprite; entry: int32): bool {.tln, importc: "TLN_SetSpritePicture", discardable.}
proc setPalette*(sprite: Sprite; palette: Palette): bool {.tln, importc: "TLN_SetSpritePalette", discardable.}
proc setBlendMode*(sprite: Sprite; mode: Blend; factor: uint8): bool {.tln, importc: "TLN_SetSpriteBlendMode", discardable.}
proc setScaling*(sprite: Sprite; sx: float32; sy: float32): bool {.tln, importc: "TLN_SetSpriteScaling", discardable.}
proc resetScaling*(sprite: Sprite): bool {.tln, importc: "TLN_ResetSpriteScaling", discardable.}
# proc setRotation*(sprite: Sprite; angle: float32): bool {.tln, importc: "TLN_SetSpriteRotation", discardable.}
# proc resetRotation*(sprite: Sprite): bool {.tln, importc: "TLN_ResetSpriteRotation", discardable.}

proc getSpritePicture*(sprite: Sprite): int32 {.tln, importc: "TLN_GetSpritePicture".}
proc getAvailableSprite*(): int32 {.tln, importc: "TLN_GetAvailableSprite".}
proc enableCollision*(sprite: Sprite; enable: bool): bool {.tln, importc: "TLN_EnableSpriteCollision", discardable.}
proc getCollision*(sprite: Sprite): bool {.tln, importc: "TLN_GetSpriteCollision".}
proc getState*(sprite: Sprite; state: var SpriteState): bool {.tln, importc: "TLN_GetSpriteState", discardable.}
proc setFirstSprite*(sprite: Sprite): bool {.tln, importc: "TLN_SetFirstSprite", discardable.}
proc setNextSprite*(sprite, next: Sprite): bool {.tln, importc: "TLN_SetNextSprite", discardable.}
proc enableMasking*(sprite: Sprite; enable: bool): bool {.tln, importc: "TLN_EnableSpriteMasking", discardable.}
proc setSpritesMaskRegion*(topLine, bottomLine: int32) {.tln, importc: "TLN_SetSpritesMaskRegion".}
proc setAnimation*(sprite: Sprite; sequence: Sequence; loop: int32): bool {.tln, importc: "TLN_SetSpriteAnimation", discardable.}
proc disableAnimation*(sprite: Sprite): bool {.tln, importc: "TLN_DisableSpriteAnimation", discardable.}
proc pauseAnimation*(sprite: Sprite): bool {.tln, importc: "TLN_PauseSpriteAnimation", discardable.}
proc resumeAnimation*(sprite: Sprite): bool {.tln, importc: "TLN_ResumeSpriteAnimation", discardable.}
proc disable*(sprite: Sprite): bool {.tln, importc: "TLN_DisableSprite", discardable.}
proc getPalette*(sprite: Sprite): Palette {.tln, importc: "TLN_GetSpritePalette".}

# SEQUENCE
# -------
# Sequence resources management for layer, sprite and palette animations

proc createSequence*(name: cstring; target: int32; numFrames: int32; frames: ptr UncheckedArray[SequenceFrame]): Sequence {.tln, importc: "TLN_CreateSequence".}
proc createCycle*(name: cstring; numStrips: int32; strips: ptr UncheckedArray[ColorStrip]): Sequence {.tln, importc: "TLN_CreateCycle".}
proc createSpriteSequence*(name: cstring; spriteset: Spriteset; basename: cstring; delay: int32): Sequence {.tln, importc: "TLN_CreateSpriteSequence".}
proc clone*(src: Sequence): Sequence {.tln, importc: "TLN_CloneSequence".}
proc getInfo*(sequence: Sequence; info: var SequenceInfo): bool {.tln, importc: "TLN_GetSequenceInfo", discardable.}
proc getInfo*(sequence: Sequence): (SequenceInfo, bool) {.inline.} =
  result[1] = getInfo(sequence, result[0])
proc delete*(sequence: Sequence): bool {.tln, importc: "TLN_DeleteSequence", discardable.}

# SEQUENCEPACK
# -------
# Sequence pack manager for grouping and finding sequences

proc createSequencePack*(): SequencePack {.tln, importc: "TLN_CreateSequencePack".}
proc loadSequencePack*(filename: cstring): SequencePack {.tln, importc: "TLN_LoadSequencePack".}
proc getSequence*(sp: SequencePack; index: int32): Sequence {.tln, importc: "TLN_GetSequence".}
proc findSequence*(sp: SequencePack; name: cstring): Sequence {.tln, importc: "TLN_FindSequence".}
proc getCount*(sp: SequencePack): int32 {.tln, importc: "TLN_GetSequencePackCount".}
proc addSequence*(sp: SequencePack; sequence: Sequence): bool {.tln, importc: "TLN_AddSequenceToPack", discardable.}
proc delete*(sp: SequencePack): bool {.tln, importc: "TLN_DeleteSequencePack", discardable.}

# ANIMATION
# -------
# Color cycle animation

proc setPaletteAnimation*(index: int32; palette: Palette; sequence: Sequence; blend: bool): bool {.tln, importc: "TLN_SetPaletteAnimation", discardable.}
proc setPaletteAnimationSource*(index: int32; a2: Palette): bool {.tln, importc: "TLN_SetPaletteAnimationSource", discardable.}
proc getAnimationState*(index: int32): bool {.tln, importc: "TLN_GetAnimationState".}
proc setAnimationDelay*(index, frame, delay: int32): bool {.tln, importc: "TLN_SetAnimationDelay", discardable.}
proc getAvailableAnimation*(): int32 {.tln, importc: "TLN_GetAvailableAnimation".}
proc disablePaletteAnimation*(index: int32): bool {.tln, importc: "TLN_DisablePaletteAnimation", discardable.}

# WORLD
# -------
# World management

proc loadWorld*(tmxfile: cstring; firstLayer: int32): bool {.tln, importc: "TLN_LoadWorld", discardable.}
proc setWorldPosition*(x, y: int32) {.tln, importc: "TLN_SetWorldPosition".}
proc setSpriteWorldPosition*(nsprite: int32; x, y: int32): bool {.tln, importc: "TLN_SetSpriteWorldPosition", discardable.}
proc releaseWorld*() {.tln, importc: "TLN_ReleaseWorld".}

