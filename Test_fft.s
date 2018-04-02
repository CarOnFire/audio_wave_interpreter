.global main
main:

movia r10, 0x03FFFFFF
subi sp, r10, 68
movia r2, 0x3FF00000

stw r0, 0(r10)
stw r2, 4(r10)

stw r0, 8(r10)
stw r0, 12(r10)

stw r0, 16(r10)
stw r0, 20(r10)

stw r0, 24(r10)
stw r0, 28(r10)

stw r0, 32(r10)
stw r2, 36(r10)

stw r0, 40(r10)
stw r0, 44(r10)

stw r0, 48(r10)
stw r0, 52(r10)

stw r0, 56(r10)
stw r0, 60(r10)

mov r4, r10

call fft_func();



Loop:
	br Loop
