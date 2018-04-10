.equ WIDTH, 320
.equ HEIGHT, 240
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ ADDR_SLIDESWITCHES, 0xFF200040
.equ TIMER1, 0xFF202000
.equ PIXBUF, 0x08000000	# Pixel buffer. Same on all boards.
.equ MAX_ROW, 239
.equ MIN_ROW, 0
.equ CENTER_ROW, 119

.data
WAVE_DATA:
    .skip 1288

.text

.global drawWave

drawWave:
    subi sp, sp, 16
    stw ra, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw r21, 12(sp)

    movia r21, WAVE_DATA
    subi r21, r21, 1288

    mov r10 , r0 #sample counter
    
    /*
     * Reading the switches to determine the shift amount
     */

    shift_read: movia r2, ADDR_SLIDESWITCHES
	movi r17, 1
    ldwio r2, 0(r2) #determine shift amount
	sll r17, r17, r2 # 2^(r2) 
    
    /*
     * clearing the fifo so that we always start at a clean slate
     */
     
    clear_fifo: movia r18, ADDR_AUDIODACFIFO
    ldwio r2,12(r18) # Load mic
    ldwio r2,8(r18)
    ldwio r2, 4(r18)      # Read fifospace register 
    andi  r2, r2, 0xff    # Extract # of samples in Input Right Channel FIFO 
    bne   r2, r0, clear_fifo  # If no samples in FIFO, go back to start 
    
    /*
     * extracting samples from the fifo
     */
    
    check_fifo: movia r18, ADDR_AUDIODACFIFO
    ldwio r2, 4(r18)      # Read fifospace register 
    andi  r2, r2, 0xff    # Extract # of samples in Input Right Channel FIFO 
    beq   r2, r0, check_fifo  # If no samples in FIFO, go back to start 
    
    ldwio r2,12(r18) # Load mic
    ldwio r2,8(r18) 
    div r18, r2, r17 # Normalize right shift by 2^(r2)
    
    subi r21, r21, 4
    stw r18, 0(r21) # Storing sample to stack
    addi r10, r10, 1 # Increase counter
    
    movi r18, WIDTH # Check if enough samples
    beq r10, r18, draw_screen #draw screen is samples are enough
   	br check_fifo
    
    
/*
 * draws the screen by going through the array and printing array values to the screen
 */
 
draw_screen:

	mov r10, r21
    movi r18, WIDTH-33
    
	draw_wave_start:
    mov r5, r18 #col
	mov r4, r0 #black
	call FillLine #erases previous
    
    mov r4, r18 #col
	movia r6, 0xffffffff #white
    
    ldw r17, 0(r10) #getting array value
    addi r5, r17, CENTER_ROW #centering at 120
    movi r2, MAX_ROW #lower limit
	bgt r5, r2, normalize_down #normalization, incase amplitude is too large
	blt r5, r0, normalize_up
    draw_amp_pixel: call WritePixel
    addi r10, r10, 4 #increase array value
    subi r18, r18, 1 #increase col value
    movi r2, 31
   	bne r18, r2, draw_wave_start
    
    /*
     * Control for the refresh rate of our wave drawing
     */
     
    movia r18, TIMER1 #timer initialization
    movia r2, 0xB9AA #60 Hz
    stwio r2, 8(r18)
    movi r2, 0x65
    stwio r2, 12(r18)
    movi r2, 0x4
    stwio r2, 4(r18) #timer start
    
    check_wave_timer: ldwio r2, 0(r18)
    andi r2, r2, 0x01
    beq r2, r0, check_wave_timer
    stwio r0, 0(r18) #clearing timer
    
    mov r10, r0 #reset counter
	movia r21, WAVE_DATA # Initial stack pointer
    br exit_drawWave
    
normalize_down:
	movi r5, MAX_ROW
	br draw_amp_pixel

normalize_up:
	movi r5, MIN_ROW
	br draw_amp_pixel

exit_drawWave:
    ldw ra, 0(sp)
    ldw r17, 4(sp)
    ldw r18, 8(sp)
    ldw r21, 12(sp)
    addi sp, sp, 16
    ret
