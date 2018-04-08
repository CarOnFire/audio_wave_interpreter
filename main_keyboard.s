.equ PS2, 0xFF200100

.text
.global _start
_start:
    
    movia sp, 0x80000000

    movia r18, PS2
    movia r2, 0x80 #IRQ line 7
    wrctl ienable, r2
    movia r2, 0x1 #PIE:0 
    stwio r2, 4(r18)
    wrctl status, r2
    
    movia r17, 0x1D #scan code 'w'
    movia r18, 0x2B #scan code 'f'
    movia r16, 0x1 
    
    LOOP:
    beq et, r17, set_wave
    beq et, r18, set_freq
    
    display:
    bne r16, r0, 2f
        1:call drawFreq
        br LOOP
        
        2: call drawWave
        br Loop
        
set_wave:
    movi r16, 0x01
    br display
    
set_freq:
    mov r16, r0
    br display

    

.section .exceptions, "ax"

HANDLER:
    subi sp, sp, 12
    stw r2, 0(sp)
    stw r18, 4(sp)

    movia r18, PS2
    
    READ:
    ldbio et, 0(r18)
    ldwio r2, 0(r18)
    srli r2, r2, 0x0f
    andi r2, r2, 0x1 #check if valid read 
    bne r2, r0, READ
    
    
    ldw r2, 0(sp)
    ldw r18, 4(sp)
    addi sp, sp, 12
    subi ea, ea, 4
    eret
    