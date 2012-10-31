;PILL_SIDE       .equ 81 ; 'o'
;VIRUS_ONE       .equ 83
;VIRUS_TWO       .equ 84
;PILL_LEFT       .equ 107
;PILL_RIGHT      .equ 115
;PILL_TOP        .equ 114
;PILL_BOTTOM     .equ 113

;lda #$0F ; Low byte start location
;lda #$04 ; High byte start location


test1 ; Test to see that horizontal drops are joined together
;    ldy #$00

    lda #$d8
    sta zpPtr2
    lda #$04
    sta zpPtr2+1

    ldy #6
    lda #PILL_LEFT
    sta (zpPtr2),y
    lda #PILL_RIGHT
    iny
    sta (zpPtr2),y

    ldy #46
    lda #PILL_LEFT
    sta (zpPtr2), y
    iny
    lda #PILL_RIGHT
    sta (zpPtr2),y

    ldy #86
    lda #PILL_SIDE
    sta (zpPtr2),y
    iny
    sta (zpPtr2),y
    ldy #166
    sta (zpPtr2),y
    iny
    sta (zpPtr2),y

    rts

test2 ; Test to see that two veritically stacked pieces will drop okay together
    ldy #$00
    lda #$D8
    sta zpPtr2
    lda #$04
    sta zpPtr2+1

    ldy #7
    lda #PILL_TOP
    sta (zpPtr2),y
    ldy #47
    lda #PILL_BOTTOM
    sta (zpPtr2),y

    ldy #127
    lda #PILL_TOP
    sta (zpPtr2), y
    ldy #167
    lda #PILL_BOTTOM
    sta (zpPtr2),y

    ldy #207
    lda #PILL_SIDE
    sta (zpPtr2),y
    rts

test3 ; replicate issue I took a picture of
    ldy #0

    lda #OnePGameFieldLocLow
    clc
    adc #$e2
    sta zpPtr2

    lda #OnePGameFieldLocHigh
    adc #$01
    sta zpPtr2+1

    lda #PILL_SIDE
    sta (zpPtr2),y

    iny
    lda #PILL_SIDE
    sta (zpPtr2),y


    ldy #40
    lda #PILL_SIDE
    sta (zpPtr2),y
    iny
    lda #PILL_SIDE
    sta (zpPtr2),y


    ldy #80
lda #VIRUS_TWO
    sta (zpPtr2),y
iny

    lda #PILL_SIDE
    sta (zpPtr2),y

    ldy #121
    lda #VIRUS_ONE
    sta (zpPtr2),y
    rts

test4 ; not doing well at clearing more than 2 viruses at a time with scoring
    lda #OnePGameFieldLocLow
    clc
    adc #$e2
    sta zpPtr2

    lda #OnePGameFieldLocHigh
    adc #$01
    sta zpPtr2+1
    lda #PILL_SIDE
    sta (zpPtr2),y

    lda #VIRUS_ONE
    iny
       sta (zpPtr2),y
    iny
   sta (zpPtr2),y
    iny
   sta (zpPtr2),y
    iny
    iny
    sta (zpPtr2),y
    rts

test5 ; clearing a + sign of stuff
    lda #OnePGameFieldLocLow
    clc
    adc #$a4
    sta zpPtr2

    lda #OnePGameFieldLocHigh
    adc #$00
    sta zpPtr2+1

    lda #VIRUS_ONE
    sta (zpPtr2),y

ldy #40
lda #VIRUS_ONE
sta (zpPtr2),y
ldy #78
lda #VIRUS_ONE
sta (zpPtr2),y
iny
lda #VIRUS_ONE
sta (zpPtr2),y
iny
lda #VIRUS_ONE
sta (zpPtr2),y
iny
lda #VIRUS_ONE
sta (zpPtr2),y
ldy #120
lda #VIRUS_ONE
sta (zpPtr2),y
ldy #160
lda #VIRUS_ONE
sta (zpPtr2),y
rts

test6 ; Not clearing half way clears that end up at the top of the screen
lda #OnePGameFieldLocLow
sec
sbc #39
sta zpPtr2

lda #OnePGameFieldLocHigh
sbc #$00
sta zpPtr2+1

lda #PILL_CLEAR_1
sta (zpPtr2),y
rts

