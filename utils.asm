; Memcopy: copy bytes from one location to another
; @param de: source
; @param hl: destination
; @param bc: length
Memcopy:
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret 

; GetTileByPixel: convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First we need to divide by 8 to convert a pixel position to a tile position
    ; Then we want to multiply the Y position by 32
    ; These operations effectively cancel out so we only need to mask the Y value
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; now we have the position * 8 in hl
    add hl, hl      ; multiply by 16 (8x2)
    add hl, hl      ; multiply by 32 (16x2)
    ; Convert the X position to an offset (using shift right instruction srl)
    ld a, b
    srl a   ; a / 2
    srl a   ; a / 4
    srl a   ; a / 8
    ; Add the 2 offsets together (using magic)
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; add the offset to the tilemaps base address
    ld bc, $9800
    add hl, bc
    ret

; IsWallTile: sets z flag if the tile is a wall tile
; @param a: the tile ID
; @return z: set if tile is a wall
IsWallTile:
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $03
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret

; CheckAndHandleBrick: checks if a brick was collided with and break it if possible.
; @param hl: address of tile
CheckAndHandleBrick:
    ld a, [hl]
    cp a, BRICK_LEFT
    jr nz, CheckAndHandleBrickRight
    ; break a brick from the left side
    ld [hl], BLANK_TILE
    inc hl
    ld [hl], BLANK_TILE
CheckAndHandleBrickRight:
    cp a, BRICK_RIGHT
    ret nz
    ; break brick from right side
    ld [hl], BLANK_TILE
    dec hl
    ld [hl], BLANK_TILE
    ret
