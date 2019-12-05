
/******************************************************************************
* file: subroutines.s
* author: Prakash Tiwari
* Guide: Prof. Madhumutyam IITM, PACE
******************************************************************************/


  @ BSS section
      .bss

  @ DATA SECTION
      .data
    buffer: .word 0
    input_num: .word 0
    fibonacci_out: .word 0
    InputNumberMsg:  .asciz   "\nEnter number to compute Fibonacci number:\n"
    OutputMsg:  .asciz   "\nFibonacci Output is:\n"
    InputAnotherNumber:  .asciz   "\nEnter 1 to compute Fibonacci again\n"
    InputExitMsg:  .asciz   "\nEnter 2 to exit the program\n"
  @ TEXT section
      .text
.globl _main

_main:

BEGIN_FIBONACCI:
@ get the element to calculate fibonacci
@Display message to ask for number for which fibonacci to be calculated
  mov r0,#1
  ldr r1,=InputNumberMsg
  swi 0x069

  @ get the input number
  mov r0,#0
  ldr r1,=input_num
  swi 0x6c
  str r0,[r1]

  @ calculate the fibonacci for given input
  mov     r3, #0
  str     r3, [sp, #-8]
  ldr     r3, =input_num
  @save the subroutine argument in r0
  ldr     r0,[r3]
  bl      FIBONACCI
  mov     r3, r0
  ldr     r1, =fibonacci_out
  str     r3,[r1]
  mov     r0,#1
  ldr r1,=OutputMsg
  swi 0x069
  ldr     r1,=fibonacci_out
  ldr r1,[r1]
  swi     0x6b
  b NEXT_ACTION

@Display next actions for the program and request user input
NEXT_ACTION:
  mov r0,#1
  ldr r1,=InputAnotherNumber
  swi 0x069

  ldr r1,=InputExitMsg
  swi 0x069

  mov r0,#0
  ldr r1,=buffer
  swi 0x6c
  str r0,[r1]

  cmp     r0, #1
  beq     BEGIN_FIBONACCI
  ldr r1,=buffer
  ldr r1,[r1]
  cmp     r1, #2
  beq     END_PROGRAM

END_PROGRAM:
   swi 0x11


@Subroutine
FIBONACCI:
        push    {r4, fp, lr}
        @move fp to perview of existing subroutine
        add     fp, sp, #8
        @ allocate stack space for this subroutine
        sub     sp, sp, #12
        @ save the function input to stack-frame
        str     r0, [fp, #-16]
        @read input to r3
        ldr     r3, [fp, #-16]
        @ compare if input is 0 => terminating condition1
        cmp     r3, #0
        bne     LIMIT_CHECK
        @ if input number is 0 => return 0
        mov     r3, #0
        b       END_FIB

LIMIT_CHECK:
        @ compare if input is 1 => terminating condition2
        ldr     r3, [fp, #-16]
        cmp     r3, #1
        bne     COMPUTE_FIB
        @if input is 1 => return 1
        mov     r3, #1
        b       END_FIB

COMPUTE_FIB:
        @read the number from stack-frame (number is greater than 1)
        ldr     r3, [fp, #-16]
        sub     r3, r3, #2
        @Execute FIBONACCI subroutine till 2nd last fibonacci
        mov     r0, r3
        bl      FIBONACCI
        @ subroutine terminates , save the result in r4
        mov     r4, r0
        @read the number from stack-frame (number is greater than 1)
        ldr     r3, [fp, #-16]
        @Execute FIBONACCI subroutine till last fibonacci
        sub     r3, r3, #1
        mov     r0, r3
        bl      FIBONACCI
        @ subroutine terminates , save the result in r3
        mov     r3, r0
        @ add the 2nd last and last fibonacci to get the current fibonacci for given input
        add     r3, r4, r3
END_FIB:
        @ Save the fibonacci for given input to r0
        mov     r0, r3
        @restore the stack pointer
        sub     sp, fp, #8
        @restore the stack-frame to calling function
        pop     {r4, fp, lr}
        bx      lr