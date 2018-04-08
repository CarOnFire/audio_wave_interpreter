# 320x240, 1024 bytes/row, 2 bytes per pixel: DE1-SoC
.equ WIDTH, 320
.equ HEIGHT, 240
.equ LOG2_BYTES_PER_ROW, 10
.equ LOG2_BYTES_PER_PIXEL, 1
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ ADDR_SLIDESWITCHES, 0xFF200040
.equ TIMER1, 0xFF202000
.equ PIXBUF, 0x08000000	# Pixel buffer. Same on all boards.
	
.global _start
_start:

	setup:movia sp, 0x80000000	# Initial stack pointer 
    
    # Initialization of the screen with black
	movi r4, 0x0 #moving black into
    call FillColour		# Fill screen with a colour
    
    /*
     * The stack is decreased to leave space for
     * the storage of our temporary variable
     */
     
    allocate_space: subi sp, sp, 1288
    movia r21, 0x80000000
    movi r10 , 0x0
    
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
    
    movia r18, WIDTH # Check if enough samples
    beq r10, r18, draw_screen #draw screen is samples are enough
   	br check_fifo
    
    
/*
 * draws the screen by going through the array and printing array values to the screen
 */
 
draw_screen:

	add r10, r0, r21
    movia r18, WIDTH-1
    
	draw: mov r5, r18 #col
	movi r4, 0x0 #black
	call FillLine #erases previous
    
    mov r4, r18 #col
	movia r6, 0xffffffff #white
    
    ldw r17, 0(r10) #getting array value
    addi r5, r17, 120 #centering at 120
    movi r2, 239 #lower limit
	bgt r5, r2, normalize_down #normalization, incase amplitude is too large
	blt r5, r0, normalize_up
    draw_pixel: call WritePixel
    addi r10, r10, 4 #increase array value
    subi r18, r18, 1 #increase col value
   	bne r18, r0, draw
    
    /*
     * Control for the refresh rate of our wave drawing
     */
     
    movia r18, TIMER1 #timer initialization
    movia r2, 0xB9AA #60 Hz
    stwio r2, 8(r18)
    movia r2, 0x65
    stwio r2, 12(r18)
    movi r2, 0x4
    stwio r2, 4(r18) #timer start
    
    check_timer: ldwio r2, 0(r18)
    andi r2, r2, 0x01
    beq r2, r0, check_timer
    stwio r0, 0(r18) #clearing timer
    
    movi r10, 0x0 #reset counter
	movia r21, 0x80000000 # Initial stack pointer
    br shift_read
    
normalize_down:
	movi r5, 239
	br draw_pixel

normalize_up:
	movi r5, 0
	br draw_pixel
    
# r4: colour
FillColour:
	subi sp, sp, 16
    stw r16, 0(sp)		# Save some registers
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw ra, 12(sp)
    
    mov r18, r4
    
    # Two loops to draw each pixel
    movi r16, WIDTH-1
    1:	movi r17, HEIGHT-1
        2:  mov r4, r16
            mov r5, r17
            mov r6, r18
            call WritePixel		# Draw one pixel
            subi r17, r17, 1
            bge r17, r0, 2b
        subi r16, r16, 1
        bge r16, r0, 1b
    
    ldw ra, 12(sp)
	ldw r18, 8(sp)
    ldw r17, 4(sp)
    ldw r16, 0(sp)    
    addi sp, sp, 16
    ret
    
    
# r4: colour
# r5: col

FillLine:
	subi sp, sp, 16
    stw r16, 0(sp)		# Save some registers
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw ra, 12(sp)
    
    mov r18, r4
    mov r16, r5
    # Two loops to draw each pixel
    1:	movi r17, HEIGHT-1
        2:  mov r4, r16
            mov r5, r17
            mov r6, r18
            call WritePixel		# Draw one pixel
            subi r17, r17, 1
            bge r17, r0, 2b
    
    ldw ra, 12(sp)
	ldw r18, 8(sp)
    ldw r17, 4(sp)
    ldw r16, 0(sp)    
    addi sp, sp, 16
    ret

# r4: col (x)
# r5: row (y)
# r6: colour value
WritePixel:
	movi r2, LOG2_BYTES_PER_ROW		# log2(bytes per row)
    movi r3, LOG2_BYTES_PER_PIXEL	# log2(bytes per pixel)
    
    sll r5, r5, r2
    sll r4, r4, r3
    add r5, r5, r4
    movia r4, PIXBUF
    add r5, r5, r4
    
    bne r3, r0, 1f		# 8bpp or 16bpp?
  	stbio r6, 0(r5)		# Write 8-bit pixel
    ret
    
1:	sthio r6, 0(r5)		# Write 16-bit pixel
	ret