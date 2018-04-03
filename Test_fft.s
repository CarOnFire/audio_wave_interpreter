.global main
main:

movia r10, 0x03FFFFFF
subi sp, r10, 68
movia r2, 0x3FF00000
stw r2, 0(r10)
stw r0, 4(r10
stw r0, 8(r10)
stw r0, 12(r10)
stw r2, 16(r10)
stw r0, 20(r10)
stw r0, 24(r10)
stw r0, 28(r10)
mov r4, r10
call fft_func();

Loop:
	br Loop
