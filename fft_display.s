# 320x240, 1024 bytes/row, 2 bytes per pixel: DE1-SoC
.equ WIDTH, 320
.equ HEIGHT, 240
.equ LOG2_BYTES_PER_ROW, 10
.equ LOG2_BYTES_PER_PIXEL, 1
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ ADDR_SLIDESWITCHES, 0xFF200040
.equ PIXBUF, 0x08000000 # Pixel buffer. Same on all boards.
.equ STACK, 0x04000000
.equ TIMER1, 0xFF202000
.equ AMP_START, 200
.equ SIZE, 2048

.data
DATA_IN:
    .skip 2052

.text
.global main

main:

movia sp, STACK
/* allocate space on sp*/
movi r4, 0x0
call FillColour

begin_read:
/* allocate space on sp*/
movia r21, DATA_IN
subi r21, r21, 2052
movi r10 , 0
#subi sp, sp, 2564  #512*4=2048

clear_fifo: movia r18, ADDR_AUDIODACFIFO
    ldwio r2,12(r18) # Load mic
    ldwio r2,8(r18)
    ldwio r2, 4(r18)      # Read fifospace register 
    andi  r2, r2, 0xff    # Extract # of samples in Input Right Channel FIFO 
    bne   r2, r0, clear_fifo  # If no samples in FIFO, go back to start 
    
    
check_fifo: 
    movia r18, ADDR_AUDIODACFIFO
    ldwio r2, 4(r18)      # Read fifospace register 
    andi  r2, r2, 0xff    # Extract # of samples in Input Right Channel FIFO 
    beq   r2, r0, check_fifo  # If no samples in FIFO, go back to start 
    
    ldwio r2,12(r18) # Load mic
    ldwio r2,8(r18) 
    
    subi r21, r21, 4
    #stw r2, 0(r21) # Storing sample to stack



    movia r3, ADDR_SLIDESWITCHES
    #movi r17, 1
    ldwio r3, 0(r3) #determine shift amount
    srl r2, r2, r3 # 2^(r2) 


    stw r2, 0(r21) # Storing sample to stack
      

    addi r10, r10, 1 # Increase counter
    
    movia r18, WIDTH-1 # Check if enough samples
    beq r10, r18, fft #draw screen is samples are enough


   	br check_fifo
    

# r4: colour
# r5: col
# r6: height (must be positive number)

fft:
mov r4 , r21

#movi r10, 16 #320 #pass in the size of the int array
#mov r5,r10
call fft_func()

mov r21, r2
movia r10, WIDTH-1

draw_freq:
subi r10, r10, 1
addi r21, r21, 4
movia r4, 0x0
mov r5, r10
call FillLine

movia r4, 0xffffffff
mov r5, r10
ldw r6, 0(r21)
call FillSegment
bne r10, r0, draw_freq

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

br begin_read






# r4: colour
# r5: col
# r6: height (must be positive number)

FillSegment:
    subi sp, sp, 20
    stw r15, 0(sp) # Save some registers
    stw r16, 4(sp)
    stw r17, 8(sp)
    stw r18, 12(sp)
    stw ra, 16(sp)
    
    mov r18, r4
    mov r16, r5
    movi r2, AMP_START #get row index for height
    sub r15, r2, r6
    bge r15, r0, start_segment #check if number is larger
        mov r15, r0
        
    # Two loops to draw each pixel
    start_segment:  movi r17, AMP_START
        1:  mov r4, r16
            mov r5, r17
            mov r6, r18
            call WritePixel     # Draw one pixel
            subi r17, r17, 1
            bge r17, r15, 1b
    
    ldw r15, 0(sp) # Save some registers
    ldw r16, 4(sp)
    ldw r17, 8(sp)
    ldw r18, 12(sp)
    ldw ra, 16(sp)
    addi sp, sp, 20
    ret


# r4: colour

FillColour:
    subi sp, sp, 16
    stw r16, 0(sp)      # Save some registers
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw ra, 12(sp)
    
    mov r18, r4
    
    # Two loops to draw each pixel
    movi r16, WIDTH-1
    1:  movi r17, HEIGHT-1
        2:  mov r4, r16
            mov r5, r17
            mov r6, r18
            call WritePixel     # Draw one pixel
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
    stw r16, 0(sp)      # Save some registers
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw ra, 12(sp)
    
    mov r18, r4
    mov r16, r5
    # Two loops to draw each pixel
    movi r17, HEIGHT-1
        1:  mov r4, r16
            mov r5, r17
            mov r6, r18
            call WritePixel     # Draw one pixel
            subi r17, r17, 1
            bge r17, r0, 1b
    
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
    movi r2, LOG2_BYTES_PER_ROW     # log2(bytes per row)
    movi r3, LOG2_BYTES_PER_PIXEL   # log2(bytes per pixel)
    
    sll r5, r5, r2
    sll r4, r4, r3
    add r5, r5, r4
    movia r4, PIXBUF
    add r5, r5, r4
    
    sthio r6, 0(r5)     # Write 16-bit pixel
    ret


