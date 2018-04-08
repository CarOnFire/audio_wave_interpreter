# 320x240, 1024 bytes/row, 2 bytes per pixel: DE1-SoC
.equ WIDTH, 320
.equ HEIGHT, 240
.equ LOG2_BYTES_PER_ROW, 10
.equ LOG2_BYTES_PER_PIXEL, 1
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ PIXBUF, 0x08000000 # Pixel buffer. Same on all boards.

.text
.global main

main:

movia sp, 0x80000000
/* allocate space on sp*/
subi sp, sp, 1280  #320*4=1280
movia r21, 0x80000000
movi r10 , 0x0

movi r4, 55
call FillColour
loop:
br loop


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
    stw r2, 0(r21) # Storing sample to stack
    addi r10, r10, 1 # Increase counter
    
    movia r18, WIDTH # Check if enough samples
    beq r10, r18, fft #draw screen is samples are enough
   	br check_fifo
    

# r4: colour
# r5: col
# r6: height (must be positive number)




fft:
movia r4, 0x80000000
movia r10, 320 #pass in the size of the int array
mov r5,r10
#call fft_func()
br main

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
