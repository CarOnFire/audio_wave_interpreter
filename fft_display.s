.equ WIDTH, 320
.equ HEIGHT, 240
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ ADDR_SLIDESWITCHES, 0xFF200040
.equ TIMER1, 0xFF202000
.equ AMP_START, 200
.equ SIZE, 2048

.data
DATA_IN:
    .skip 2052

.text

/*
 * Function for drawing the frequency spectrum.
 * Actual Fast Fourier Transform is being done by a C program.
 * This function stores samples into an array and 
 * passes it to the C program
 * If size is to be changed, both in this file as well as the 
 * C program will have to be changed.
 * No parameters or return values.
 */

.global drawFreq
drawFreq:
    subi sp, sp, 16
    stw ra, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw r21, 12(sp)

    /* Determine amount to attentuate signal by */
    movia r2, ADDR_SLIDESWITCHES
    movi r17, 1
    ldwio r2, 0(r2) #determine shift amount
    sll r17, r17, r2 # 2^(r2) 

    /* Getting data pointer to array*/
    movia r21, DATA_IN
    subi r21, r21, 2052 #start on a lower address rather than larger
    mov r10, r0

    /*
     * We clear the fifo, so that we can start with fresh data,
     * rather than old data which we are unsure about the 
     * ordering of
     */

    clear_fifo: 
    movia r18, ADDR_AUDIODACFIFO
    ldwio r2,12(r18) # Load mic
    ldwio r2,8(r18)
    ldwio r2, 4(r18)      # Read fifospace register 
    andi  r2, r2, 0xff    # Extract # of samples in Input Right Channel FIFO 
    bne   r2, r0, clear_fifo  # If no samples in FIFO, go back to start 
    
    /*
     * Loading data into the array
     * signal is being normalized
     */
    
    check_fifo: 
    movia r18, ADDR_AUDIODACFIFO
    ldwio r2, 4(r18)      # Read fifospace register 
    andi  r2, r2, 0xff    # Extract # of samples in Input Right Channel FIFO 
    beq   r2, r0, check_fifo  # If no samples in FIFO, go back to start 
    
    ldwio r2,12(r18) # Load mic
    ldwio r2,8(r18) 
    
    subi r21, r21, 4 # move to next array location
    div r2, r2, r17 # 2^(r2) normalization
    stw r2, 0(r21) # Storing sample to stack

    addi r10, r10, 1 # Increase counter
    movia r18, WIDTH-1 # Check if enough samples

    beq r10, r18, fft #draw screen if samples are enough
    br check_fifo
    

fft:
    mov r4 , r21 #pointer to array
    call fft_func()

    mov r21, r2 
    movia r10, WIDTH-32

    draw_freq:
    subi r10, r10, 1
    addi r21, r21, 4

    mov r4, r0
    mov r5, r10
    call FillLine

    movia r4, 0xffffffff
    mov r5, r10
    ldw r6, 0(r21)
    call FillSegment

    subi r10, r10, 1

    mov r4, r0
    mov r5, r10
    call FillLine

    movia r4, 0xffffffff
    mov r5, r10
    ldw r6, 0(r21)
    call FillSegment

    movi r2, 32
    bne r10, r2, draw_freq

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
    br freq_exit

freq_exit:
    ldw ra, 0(sp)
    ldw r17, 4(sp)
    ldw r18, 8(sp)
    ldw r21, 12(sp)
    addi sp, sp, 16
    ret