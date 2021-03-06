.equ ADDR_PS2, 0xFF200100
.equ STACK_POINTER, 0x04000000
.equ SCANCODE_w, 0x1D
.equ SCANCODE_f, 0x2B
.equ FREQ_TOGGLE, 0x01
.equ IRQ_7, 0x080

.text

/*
 * Main program loop to keep printing the wave or frequency.
 * When a keyboard interrupt is detected, the VGA screen will toggle between 
 * drawing the sound wave and the frequency spectrum
 */

.global main
main:

    setup: movia sp, STACK_POINTER    # Initial stack pointer 

    /*
     * Initialization of the screen with black
     */

    mov r4, r0 #filling the screen with black
    call FillColour
    
    /*
     * Enable interrupt for the PS/2 Keyboard
     */

    movia r18, ADDR_PS2 
    movia r2, 0x80 #IRQ line 7
    wrctl ienable, r2
    movia r2, 0x01 #PIE:0 
    stwio r2, 4(r18)
    wrctl status, r2
    movia r16, FREQ_TOGGLE 
    
    /*
     * Main loop for detecting keyboard input 
     * and calling proper drawing function 
     * interrupt can happen inside of the drawing functions
     */    

    MAIN_LOOP:
    movia r17, SCANCODE_w
    movia r18, SCANCODE_f 
    
    beq et, r17, set_wave
    beq et, r18, set_freq
    
    display_branch:
    bne r16, r0, 2f
        1:
        subi sp, sp, 4
        stw r10, 0(sp)
        call drawFreq
        ldw r10, 0(sp)
        addi sp, sp, 4 
        br MAIN_LOOP
        
        2:
        subi sp, sp, 4
        stw r10, 0(sp)
        call drawWave
        ldw r10, 0(sp)
        addi sp, sp, 4
        br MAIN_LOOP
    
/*
 * Branches for setting the 
 * wave or display toggle
 */

set_wave:
    movi r16, FREQ_TOGGLE
    br display_branch
    
set_freq:
    mov r16, r0
    br display_branch
    

.section .exceptions, "ax"

HANDLER:
    subi sp, sp, 28
    stw r2, 0(sp)
    stw r18, 4(sp)
    stw r4, 8(sp)
    stw r5, 12(sp)
    stw r6, 16(sp)
    stw r2, 20(sp)
    stw r3, 24(sp)

    /*
     * Checking if IRQ line 7 is the one that is 
     * activated, keyboard interrupt
     */

    rdctl r2, ipending
	movi r3, 0x7
    srl r2, r2, r3
    andi r2, r2, 0x01
    beq r2, r0, interrupt_return
	
    movia r18, ADDR_PS2
    
    check_ps2_fifo:
    ldbio et, 0(r18) #load the character
    ldwio r2, 0(r18) #check if anymore valid
    srli r2, r2, 0x0f #checking valid bit 15
    andi r2, r2, 1 
    bne r2, r0, check_ps2_fifo
    
    interrupt_return:
    ldw r2, 0(sp)
    ldw r18, 4(sp)
    ldw r4, 8(sp)
    ldw r5, 12(sp)
    ldw r6, 16(sp)
    ldw r2, 20(sp)
    ldw r3, 24(sp)
    addi sp, sp, 28
    subi ea, ea, 4
    eret