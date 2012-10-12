
.org $0801
;Tells BASIC to run SYS 2064 to start our program
.byte $0C,$08,$0A,$00,$9E,' ','2','0','6','4',$00,$00,$00,$00,$00

CHROUT  .equ $FFD2
GETIN   .equ $FFE4
STOP    .equ $FFE1 ; Check for run stop, sets Z flag, then exit
SCREENMEM   .equ 1024 ; Start of character screen map, color map is + $D400
VMEM    .equ $D000

; VICE Monitor Label File Loading: load_labels "/Users/Tony/Development/DrC64/labels.txt"
; Quick VICE monitor notes:
; show_labels
; m H .piece2 .piece2
; m H .varrayindex .varrayindex
; watch store .varrayindex
; watch store .varrayindex .varrayindex
; break .brkhere
; return

VIC_MEM         .equ 53248
SCREEN_BOARDER  .equ VIC_MEM + 32
SCREEN_BG_COLOR .equ VIC_MEM + 33
SCREEN_CHAR     .equ 52224
COLOR_BLACK     .equ $00
COLOR_WHITE     .equ $01
COLOR_RED       .equ $02
COLOR_CYAN      .equ $03
COLOR_MAGENTA   .equ $04
COLOR_GREEN     .equ $05
COLOR_BLUE      .equ $06
COLOR_YELLOW    .equ $07
COLOR_ORANGE    .equ $08
COLOR_BROWN     .equ $09
COLOR_PINK      .equ $0a
COLOR_DARK_GREY .equ $0b
COLOR_GREY      .equ $0c
COLOR_L_GREEN   .equ $0d
COLOR_L_BLUE    .equ $0e
COLOR_L_GREY    .equ $0f
DELAY           .equ $10
PILL_SIDE       .equ 81 ; 'o'


; Zero Page Pointers for indirect indexing
piece1          .equ $b0
piece2          .equ $b2

zpPtr1          .equ $ba
zpPtr2          .equ $b4
zpPtr3          .equ $b6
zpPtr4          .equ $b8




jmp init

; Some vars
ENDMSG      .byte 5,14,4,0
ORGBOARDER  .byte $00
ORGBGRND    .byte $00
DRAWCOUNT   .byte $00 ; How many screen draws since last reset used as a timer
WAITTIME    .byte $00 ; How many frames to wait till we start over
ORIENTATION .byte $00 ; 0 = 12, 1 = 1, 2 = 21, 3 = 2
                      ;             2              1
PRICOLOR    .byte $00
SECCOLOR    .byte $00
CONNECTCNT  .byte $00
colors      .byte COLOR_RED, COLOR_RED, COLOR_YELLOW, COLOR_BLUE
P1_SCORE    .byte $00, $00, $00, $00
varray      .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
varrayIndex .byte $00
varray2     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
varrayIndex2 .byte $00
harray      .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
harrayIndex .byte $00
harray2     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
harrayIndex2 .byte $00

RET1        .byte $00, $00
RETX        .byte $00
RETY        .byte $00
TMP         .byte $00
TMP1        .byte $00
TMP2        .byte $00
TMP3        .byte $00
TMP4        .byte $00
TMP5        .byte $00
TMP6        .byte $00
TMP7        .byte $00

init
            jsr ClearScreen
            jsr DrawGameBoarder
            jsr initClearArrays
            ldy #$00  ; set to 1024 our screen pos
            sty SCREEN_BG_COLOR
            lda COLOR_DARK_GREY
            sta SCREEN_BOARDER

DropNew
            ; Testing Counting connections
;            lda piece1
;            pha
;            lda piece1+1
;            pha
;            jsr lookForConnect4c ; varray (return>, return<, piece>, piece<)

            lda piece2
            pha
            lda piece2+1
            pha
            jsr lookForConnect4c

            jsr printConnectCount

            ldy #$13 ; Start Offset low byte location
            sty piece1
            iny
            sty piece2
            lda #$04 ; Start Offset high byte location
            sta piece1+1
            sta piece2+1

            ldy #$00
            sty ORIENTATION ; reset to 0
            sty CONNECTCNT ; reset to 0
            lda (piece1), y ; See if there is a piece in the way at the top
            cmp #" "
            bne EndGame
            lda (piece2), y ; See if there is a piece in the way at the top
            cmp #" "
            bne EndGame
            lda #PILL_SIDE ; 'o'
            sta (piece1), y ; print new pieces
            sta (piece2), y
            jsr NewColors ; Set their new random colors

; Inserted for debugging
jsr printArrayValues

; end of debugging


;the main game loop
GameLoop
        lda DRAWCOUNT
        cmp #DELAY
        BCS MoveDownJump
        JSR GETIN ; get a key input
        cmp #'w'
        beq SwapColors
        cmp #'d'
        beq MoveRightOneJump
        cmp #'a'
        beq MoveLeftOneJump
        cmp #'s'
        beq MoveDownJump
        cmp #"q"
        beq Return
        cmp #" "
        beq rotateJsr
        MoveDone
        jsr WaitFrame
        jmp GameLoop

MoveLeftOneJump jmp MoveLeftOne
MoveDownJump jmp ZeroCountAndMoveDown
MoveDown     jmp MoveDownOne
SwapColors   jsr ColorSwap
rotateJsr    jmp rotate
MoveRightOneJump    jmp MoveRightOne

                jmp GameLoop
EndGame      jmp printMsg


WaitFrame
            stx RETX
            lda $d012
            cmp #$F8
            beq WaitFrame
            ;wait for the raster to reach line $f8 (should be closer to the start of this line this way)
WaitStep2   lda $d012
            cmp #$F8
            bne WaitStep2
            ;jmp MoveDownOne
            ldx DRAWCOUNT
            inx
            stx DRAWCOUNT
Return
            ldx RETX
            rts







rotate
        ; Cleared printed pill first
        ldy #$00
        lda #" "
        sta (piece1), y
        sta (piece2), y
        lda ORIENTATION
        beq rotateUnder
        cmp #$01
        beq rotateToLeft
        cmp #$02
        beq rotateToTop
        cmp #$03
        beq rotateToRight
rotateUnder
        inc ORIENTATION
        lda piece1
        sta zpPtr2
        lda piece1+1
        sta zpPtr2+1

        lda zpPtr2
        sta piece2
        lda zpPtr2+1
        sta piece2+1

        ; Subtract one row from zptr2
        lda zpPtr2
        sec
        sbc #40
        sta piece1
        lda zpPtr2+1
        sbc #$00
        sta piece1+1
        jmp RotateFinished
rotateToLeft
; Just put them back horizontally and swap the colors
        inc ORIENTATION
; piece one is on top, return it to the bottom, and move
; piece2 to the right
; Piece2 is currently where we want 1 at
        clc
        lda piece2
        sta piece1
        adc #$01
        sta piece2

        lda piece2+1
        sta piece1+1
        adc #$00
        sta piece2+1
        jsr ColorSwap
        lda #$00
        sta ORIENTATION
;        jmp RotateFinished
RotateFinished
        jsr ChangeColor
        ; print the result
        ldy #$00
        lda #PILL_SIDE ; 'o'
        sta (piece1), y
        sta (piece2), y
        jmp MoveDone
rotateToTop     jmp MoveDone
rotateToRight   jmp MoveDone




MoveRightOne
        lda piece2
        sta zpPtr2
        lda piece2+1
        sta zpPtr2+1

        jsr CheckCollisionRight_zpPtr2
        bne rightMoveDone

; Secondary piece
        ldy #$00 ; offset from current char pos
        lda #' '
        sta (piece2), y
        clc
        lda #$01
        adc piece2
        sta piece2
        lda #$00 ; Add any roll over to the high byte
        adc piece2+1
        sta piece2+1
        lda #PILL_SIDE
        sta (piece2), y
        ; clear pos
        lda #' '
        sta (piece1), y
        ; increment the pointer value by one
        clc
        lda #$01
        adc piece1
        sta piece1
        lda #$00 ; Add any roll over to the high byte
        adc piece1+1
        sta piece1+1
        lda #PILL_SIDE
        sta (piece1), y
        JSR ChangeColor
rightMoveDone
        jmp MoveDone





MoveLeftOne
                lda piece1
                sta zpPtr2
                lda piece1+1
                sta zpPtr2+1
                jsr CheckCollisionLeft_zpPtr2
                bne leftMoveDone

                ; Clear the current pos
                ldy #$00 ; offset from current char pos
                lda #" "
                sta (piece1), y

                ; decrement the pointer value by one
                sec
                lda piece1
                sbc #$01
                sta piece1
                lda piece1+1 ; subtract 0 and any borrow generated above
                sbc #$00
                sta piece1+1
                lda #PILL_SIDE
                sta (piece1), y

; Second
lda #" "
sta (piece2), y

; decrement the pointer value by one
sec
lda piece2
sbc #$01
sta piece2
lda piece2+1 ; subtract 0 and any borrow generated above
sbc #$00
sta piece2+1
lda #PILL_SIDE
sta (piece2), y

JSR ChangeColor
leftMoveDone                jmp MoveDone







ZeroCountAndMoveDown
                lda #$00
                sta DRAWCOUNT
MoveDownOne
; Clear
ldy #$00
lda #" "
sta (piece1), y
sta (piece2), y

lda ORIENTATION
cmp #$01
beq checkSecondaryBottom

checkPrimaryBottom ldy #$00 ; offset from current char pos
                ; See if we can move down, is something there already??

                lda piece1 ; Copy piece into zpPtr2 for checking
                sta zpPtr2
                iny
                lda piece1+1
                sta zpPtr2+1
                jsr CheckCollisionBelow_zpPtr2
                bne DropNewPiece
                ; Moving piece down first clear value then add 40 to main piece

checkSecondaryBottom
                ldy #$00 ; offset from current char pos
                ; See if we can move down, is something there already??

                lda piece2, y ; Copy piece into zpPtr2 for checking
                sta zpPtr2, y
                iny
                lda piece2, y
                sta zpPtr2, y
                jsr CheckCollisionBelow_zpPtr2
                bne DropNewPiece
                ; Moving piece down first clear value then add 40 to main piece

movePrimaryDown ; increment the pointer value by 40, we should check to see that it didn't go over 2024
                clc
                lda #40
                adc piece1
                sta piece1
                lda #$00 ; Add any roll over to the high byte
                adc piece1+1
                sta piece1+1
moveSecondaryDown
                clc
                lda #40
                adc piece2
                sta piece2
                lda #$00 ; Add any roll over to the high byte
                adc piece2+1
                sta piece2+1

                JSR ChangeColor

MoveComplete
lda #PILL_SIDE
sta (piece1), y
sta (piece2), y
jmp MoveDone
DropNewPiece
lda #PILL_SIDE
sta (piece1), y
sta (piece2), y
jmp DropNew


CheckCollisionBelow_zpPtr2 ; Sets a = 1 if there will be collition below then rts
                lda zpPtr2 ; Make a copy of the current possition
                sta zpPtr3 ; into zpPtr3
                lda zpPtr2+1
                sta zpPtr3+1

                ; Look below to see what's there, is it a space?
                clc
                lda #40
                adc zpPtr3
                sta zpPtr3
                lda #$00 ; Add any roll over to the high byte
                adc zpPtr3+1
                sta zpPtr3+1
            
                ldy #$00
                lda (zpPtr3), y
                cmp #" "
                beq noCollitionDetected
                bne collitionDetected
collitionDetected
lda #"1"
sta 1024
                lda #$01
                rts
noCollitionDetected
lda #"0"
sta 1024
                lda #$00
                rts

; function CheckCollisionLeft_zpPtr2
CheckCollisionLeft_zpPtr2 ; Sets a = 1 if there will be collition below then rts
            lda zpPtr2 ; Make a copy of the current possition
            sta zpPtr3 ; into zpPtr3
            lda zpPtr2+1
            sta zpPtr3+1

            ; Look below to see what's there, is it a space?
            sec
            lda zpPtr3
            sbc #$01
            sta zpPtr3
            lda zpPtr3+1
            sbc #$00
            sta zpPtr3+1
            ldy #$00
            lda (zpPtr3), y
            cmp #" "
            beq noCollitionDetectedLeft
            bne collitionDetectedLeft
noCollitionDetectedLeft
            lda #"0"
            sta 1024
            lda #$00
            rts
collitionDetectedLeft
            lda #"1"
            sta 1024
            lda #$01
            rts

; function CheckCollisionLeft_zpPtr2
CheckCollisionRight_zpPtr2 ; Sets a = 1 if there will be collition below then rts
            ldy #$01
            lda (zpPtr2), y
            cmp #" "
            beq noCollitionDetectedRight
            bne collitionDetectedRight
noCollitionDetectedRight
            lda #"0"
            sta 1024
            lda #$00
            rts
collitionDetectedRight
            lda #"1"
            sta 1024
            lda #$01
            rts





NewColors
            jsr get_random_number
            and #3
            tay
            lda colors, y
            sta PRICOLOR
            jsr get_random_number
            and #3
            tay
            lda colors, y
            sta SECCOLOR
ChangeColor ldy #00
            lda piece1
            sta zpPtr2
            lda piece1+1
            sta zpPtr2+1
            lda #$D4
            clc
            adc zpPtr2+1
            sta zpPtr2+1

            lda PRICOLOR
            sta (zpPtr2), y
            lda piece2
            sta zpPtr2
            lda piece2+1
            sta zpPtr2+1
            lda #$D4
            clc
            adc zpPtr2+1
            sta zpPtr2+1
            lda SECCOLOR
            sta (zpPtr2), y
            RTS

ColorSwap   lda PRICOLOR
            ldx SECCOLOR
            sta SECCOLOR
            stx PRICOLOR
            jsr ChangeColor
            rts

; Print Message subrutine
printMsg    lda #$53   ; low byte character location
            STA zpPtr2 ; low byte
            STA zpPtr3 ; temp low byte of color
            lda #$05   ; high byte offset
            sta zpPtr2+1 ; Temp character location
            sta zpPtr3+1 ; Temp color location
            lda #$D4
            clc
            adc zpPtr3+1 ; add to high byte of color to get location
            sta zpPtr3+1

            ldy #$00
printLoop   lda ENDMSG, y
            beq printComplete
            sta (zpPtr2), y
            lda #COLOR_WHITE
            sta (zpPtr3), y
            iny
            jmp printLoop
printComplete
            sty WAITTIME
waitDrawLoop
            lda WAITTIME
            beq RestartGame
            inc WAITTIME
            jsr WaitFrame
            jmp waitDrawLoop
RestartGame jmp init











lookForConnect4c ; varray (return>, return<, piece>, piece<)
            pla
            sta ret1+1
            pla
            sta ret1
            pla
            sta tmp+1
            pla
            sta tmp
            ; put back return address onto stack
            lda ret1
            pha
            lda ret1+1
            pha
; clear out the arrays we're going to use
            jsr initClearArrays
; Look for vertical blocks to clear on piece one
lookUp ; start at the top and work my way down
            sec
            lda tmp ; piece
            sbc #40
            sta zpPtr2
            lda tmp+1
            sbc #$00
            sta zpPtr2+1
            ldy #$00 ; index offset for zp load
            lda (zpPtr2),y
            cmp #PILL_SIDE
            bne lookUpComplete
            clc
            lda zpPtr2 ; load back in low byte
            sta zpPtr3 ; and copy it over to the color place
            lda #$D4
            adc zpPtr2+1
            sta zpPtr3+1
            lda (zpPtr3),y
            and #$0f
            cmp PRICOLOR
            bne lookUpComplete
            ; Piece is the same color, and type
            lda zpPtr2
            sta tmp ; make it the active top piece
            lda zpPtr2+1
            sta tmp+1
            jmp lookUp
lookUpComplete
            lda tmp
            sta zpPtr2
            pha
            lda tmp+1
            sta zpPtr2+1
            pha
            jsr pushOntoVarray
lookDown
            clc ; Look for a piece below
            lda #40
            adc zpPtr2
            sta zpPtr2
            lda #$00
            adc zpPtr2+1
            sta zpPtr2+1
            ldy #$00
            lda (zpPtr2), y
            cmp #PILL_SIDE
            bne lookDownDone

            clc ; Now look for color
            lda zpPtr2
            sta zpPtr3
            lda #$D4
            adc zpPtr2+1
            sta zpPtr3+1
            lda (zpPtr3), y
            and #$0f ; mask out the top part of the byte, it could be garbage
            cmp PRICOLOR
            bne lookDownDone

            ; Trying out our array
            lda zpPtr2 ; Store away low byte
            pha
            lda zpPtr2+1 ; Store away high byte onto stack
            pha
            jsr pushOntoVarray ; void (ret2, ret1, addy2, addy1)
            inc CONNECTCNT
            jmp lookDown ; loop until we've counted them all
lookDownDone
            jsr clearPiecesInArray ; only runs if there are more than 3 in array
            rts


; Push 16 bit value onto varray
pushOntoVarray ; void (ret2, ret1, addy2, addy1)
            lda varrayIndex
            asl ; multiply * 2
            tax ; copy to x
            pla
            sta ret1+1
            pla
            sta ret1
            pla
            sta varray+1, x
            pla
            sta varray, x
            inc varrayIndex
            ; Return to where we came from
            lda ret1
            pha
            lda ret1+1
            pha
            rts

pushOntoVarray2 ; void (ret2, ret1, addy2, addy1)
            lda varrayIndex2
            asl ; multiply * 2
            tax ; copy to x
            pla
            sta ret1+1
            pla
            sta ret1
            pla
            sta varray2+1, x
            pla
            sta varray2, x
            inc varrayIndex2
            ; Return to where we came from
            lda ret1
            pha
            lda ret1+1
            pha
            rts

clearPiecesInArray
            ; see if there are more than 3 values in here
            lda varrayIndex
            cmp #04
            bcc finishedClearing ; >= 4
            ldx #$00 ; varray indexing * 2
            ldy #$00 ; zero page indexing, leave as 0
            sty tmp
clearingLoop
; 1  2  3  4  5  6  7  8
;01 23 45 67 89 01 23 45
            lda varray, x
            sta zpPtr4
            lda varray+1, x
            sta zpPtr4+1
            inx
            inx
            inc tmp
lda #86 ; clearing with this symbol
            lda #86 ; X type cross out
            sta (zpPtr4), y
            jsr WaitFrame
            jsr WaitFrame
            lda #90 ; diamond
            sta (zpPtr4), y
            jsr WaitFrame
            jsr WaitFrame
            lda #' '
            sta (zpPtr4), y
            lda tmp
            cmp varrayIndex
            bne clearingLoop
finishedClearing
            rts


; Print in 1024+1 the vertical count
printConnectCount
    lda #$01 ; Low byte location
    sta zpPtr2
    lda #$04 ; high byte of character location for 1025
    sta zpPtr2+1
    lda varrayIndex
    ldy #$00
    cmp #$0A
    bcc NumericOnly ; >= to 10 then print a letter
HexAlpha
    sta (zpPtr2), y
    rts
NumericOnly
    ora #$30
    sta (zpPtr2), y
    rts






; Zeros out the vertical clear array
initClearArrays
            ldx #17 ; 8 x 2 bytes is how large it can be
            lda #$00
            sta varrayIndex
            sta varrayIndex2
            sta harrayIndex
            sta harrayIndex2
initClearArrayLoop
            sta varray, x
            sta varray2, x
            sta harray, x
            sta harray2, x
            dex
            bne initClearArrayLoop ; check for x != 0
            rts






; Print V Array possitions on the left of the screen, there are 8 16 bit values
; looks like index x isn't used for these subroutines so we can use it.
; Array Value 0
printArrayValues ; void () ; alters x, y, tmp, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6
            ldx #$00 ; used for varray offset
pavLoop
            lda varray, x
            pha
            lda varray+1, x
            pha
            jsr bin2hex16bit ; TMP, TMP2, TMP3 (ret_2, ret_1, binNumber_high, binNumber_low) alters tmp, tmp2, tmp3, tmp4, tmp5
            lda tmp2 ; store tmp2 away so that it doesn't get overwritten in the multiply later
            sta tmp6
            ; Get screen pos to print at
            txa
            tya
            iny ; shift down the screen one
            iny ; shift down another
            tya
            lsr ; divide index by two
            pha
            lda #40
            pha
            jsr eightBitMul ; tmp1, tmp4 = (return_2, return_1, num1, num2) ; alter x, tmp1, tmp2, tmp4
            ; Shift it in a couple pos from the left
            inc tmp1
            inc tmp1
            inc tmp1
            inc tmp1
            lda tmp4 ; add 1024 to high byte
            ora #$04
            sta tmp4
            lda tmp ; result of the bin2 hex
            pha
            lda tmp1 ; One row down low byte
            pha
            lda tmp4 ; high byte pos
            pha
            jsr print8BitDecNumber ; void (ret_2, ret_1, pos_high, pos_low, number); Store away return address

            dec tmp1 ; left 2 characters to be printed
            dec tmp1
            lda tmp6
            pha
            lda tmp1 ; One row down
            pha
            lda tmp4
            pha
            jsr print8BitDecNumber ; void (ret_2, ret_1, pos_high, pos_low, number); Store away return address
            inx
            inx
            cpx #16 ; actually looking for 16, but we're incrementing right before by 2, so 18
            bne pavLoop
            rts



; Draw game board using char 230 as the boarder
; We'll start at the top left +3, draw down 16, 8 accross
DrawGameBoarder
        ldx #$00 ; Our counter
        lda #$0F ; Low byte start location
        sta zpPtr2
        lda #$04 ; High byte start location
        sta zpPtr2+1
        lda #230
        ldy #$00
        sta (zpPtr2), y
        ldy #9
        sta (zpPtr2), y
dgbLoop ldy #00
        clc
        lda #40
        adc zpPtr2
        sta zpPtr2
        lda #$00
        adc zpPtr2+1
        sta zpPtr2+1
        lda #230
        sta (zpPtr2), y
        ldy #9
        sta (zpPtr2), y
        inx
        cpx #16
        bne dgbLoop
; then finish off the bottom line
ldy #1
DrawBottom
sta (zpPtr2), y
iny
cpy #9
bne DrawBottom
dgbDone rts

