INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

jp EntryPoint

ds $150 - @, 0  ; make room for header

EntryPoint:
    ; ! don't turn the LCD off outside WaitVBlank, doing so can damage the gameboy
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; turn off LCD
    ld a, 0
    ld [rLCDC], a

    ; copy tile data
    ld de, Tiles                ; start of tiles
    ld hl, $9000                ; start of where to move the tiles
    ld bc, TilesEnd - Tiles     ; tiles length
	call Memcopy

    ; copy the tilemap
    ld de, Tilemap
    ld hl, $9800
    ld bc, TilemapEnd - Tilemap
	call Memcopy

	; clear OAM
	ld a, 0			; value to fill the OAM with
	ld b, 160		; length of OAM
	ld hl, _OAMRAM	; beginning of OAM
ClearOam:
	ld [hl+], a
	dec b
	jp nz, ClearOam

	; add an object to the OAM (Object Attribute Memory)
	; x and y coord are pivoted around the top left pixel
	; add paddle
	ld hl, _OAMRAM
	ld a, 128 + 16		; object Y = 128 (adjusted for offset) from top of the screen
	ld [hl+], a
	ld a, 64 + 8		; object X = 16 (adjuested for offset) from left of the screen
	ld [hl+], a
	ld a, 0				; tile ID = 0
	ld [hl+], a
	ld [hl+], a			; attributes = %00000000
	; add ball
	ld a, 100 + 16		; object Y = 100
	ld [hl+], a
	ld a, 32 + 8		; object X = 32
	ld [hl+], a
	ld a, 1				; tile ID = 1 (ball sprite)
	ld [hl+], a
	ld a, 0
	ld [hl], a			; attributes = %00000000

	; initialise the ball velocity going up to the right (1, -1)
	ld a, 1
	ld [wBallVelX], a
	ld a, -1
	ld [wBallVelY], a


	; copy tile data for the paddle
	ld de, Paddle
	ld hl, $8000
	ld bc, PaddleEnd - Paddle
	call Memcopy

	; copy tile data for the ball
	ld de, Ball
	ld hl, $8010
	ld bc, BallEnd - Ball
	call Memcopy

	; turn the LCD back on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON	; turn on LCD, draw background and enable objects
    ld [rLCDC], a

	; during first (blank) frame, initialise display registers
	ld a, %11_10_01_00	; colour palette
	ld [rBGP], a		; load into background colour palette
	ld a, %11_10_01_00	; colour palette
	ld [rOBP0], a

	ld a, 0
	ld [wFrameCounter], a

Main:
	ld a, [rLY]
	cp 144
	jp nc, Main
WaitVBlank2:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank2

    ; add the balls velocity to its position
    ld a, [wBallVelX]
    ld b, a
    ld a, [BALL + OBJ_X]
    add a, b
    ld [BALL + OBJ_X], a

    ld a, [wBallVelY]
    ld b, a
    ld a, [BALL + OBJ_Y]
    add a, b
    ld [BALL + OBJ_Y], a
    
BounceOnTop:
	; jp BounceOnTop2
	; Remember to offset OAM position!
	; (8, 16) in OAM coords is (0, 0) on the screen
	ld a, [BALL + OBJ_Y]	; ball Y
	sub a, 16 + 1			; subtract OAM offset for use in GetTileByPixel (+1 because we need to get the tile *below* the ball)
	ld c, a					; store ball Y in c for use in GetTileByPixel
	ld a, [BALL + OBJ_X]	; ball X
	sub a, 8				; same thing again
	ld b, a					; store ball X in b for use in GetTileByPixel
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnRight
	call CheckAndHandleBrick
	ld a, 1
	ld [wBallVelY], a		; set ball vel Y to 1 (going down)


BounceOnRight:
	ld a, [BALL + OBJ_Y]	; same as before
	sub a, 16				; not adding 1 here because we're not checking above the ball; we're checking to the right
	ld c, a
	ld a, [BALL + OBJ_X]
	sub a, 8 - 1			; -1 because we're checking to the left of the ball
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnLeft
	call CheckAndHandleBrick
	ld a, -1				; set ball vel X to 1 (going right)
	ld [wBallVelX], a

BounceOnLeft:
	ld a, [BALL + OBJ_Y]
	sub a, 16
	ld c, a
	ld a, [BALL + OBJ_X]
	sub a, 8 + 1			; +1 because we're checking on the right
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnBottom
	call CheckAndHandleBrick
	ld a, 1					; set ball vel X to 1 (going left)
	ld [wBallVelX], a

BounceOnBottom:
	ld a, [BALL + OBJ_Y]
	sub a, 16 - 1			; -1 because we're checking above
	ld c, a
	ld a, [BALL + OBJ_X]
	sub a, 8
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceDone
	call CheckAndHandleBrick
	ld a, -1				; set ball vel Y to -1 (going up)
	ld [wBallVelY], a
	
BounceDone:

	; paddle bounce logic
	; First check if ball is low enough to bounce on the paddle
	ld a, [PADDLE + OBJ_Y]
	sub a, 3
	ld b, a
	ld a, [BALL + OBJ_Y]
	cp a, b
	jp nz, PaddleBounceDone		; if the balls Y isnt the same as the paddles Y the ball cant bounce off the paddle
	ld a, [PADDLE + OBJ_X]		; Paddle's X position.
	ld b, a
	ld a, [BALL + OBJ_X]		; Balls's X position.
	add a, 16
	cp a, b
	jp c, PaddleBounceDone
	sub a, 16 + 8				; 8 to undo, 16 as width
	cp a, b
	jp nc, PaddleBounceDone

PaddleBounce2:

	ld a, -1
	ld [wBallVelY], a
	

PaddleBounceDone:

	; Check the current keys every frame and move left or right.
	call UpdateKeys

	; First, check if the left button is pressed.
CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	; Move the paddle one pixel to the left.
	ld a, [_OAMRAM + 1]
	dec a
	; If we've already hit the edge of the playfield, don't move.
	cp a, 15
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

; Then check the right button.
CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main
Right:
	; Move the paddle one pixel to the right.
	ld a, [_OAMRAM + 1]
	inc a
	; If we've already hit the edge of the playfield, don't move.
	cp a, 105
	jp z, Main
	ld [_OAMRAM + 1], a

	jp Main

DEF PADDLE  	EQU _OAMRAM + 0
DEF BALL    	EQU _OAMRAM + 4

DEF OBJ_Y       EQU 0
DEF OBJ_X       EQU 1
DEF OBJ_TILE    EQU 2
DEF OBJ_ATTR    EQU 3

DEF BRICK_LEFT	EQU $05
DEF BRICK_RIGHT	EQU $06
DEF BLANK_TILE	EQU $08

INCLUDE "io.asm"
INCLUDE "utils.asm"

INCLUDE "tileset.asm"
INCLUDE "object_tiles.asm"
INCLUDE "tilemap.asm"

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Ball Data", WRAM0
wBallVelX: db
wBallVelY: db