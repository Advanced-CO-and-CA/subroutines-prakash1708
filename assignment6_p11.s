
/******************************************************************************
* file: subroutines.s
* author: Prakash Tiwari
* Guide: Prof. Madhumutyam IITM, PACE
******************************************************************************/


  @ BSS section
      .bss

  @ DATA SECTION
    .data
    num_int: .word 0
    buffer: .word 0
    input: .word 0,0,0,0,0,0,0,0,0,0,0
    search_elem: .word 0
    output_pos: .word 0

    @ Constant Strings to display

    InputSizeEntryMsg:  .asciz   "\nEnter number of inputs in the array(max-limit 10)\n"
    InputEntryMsg:  .asciz   "\nEnter numbers in random order:\n"
    InputSearchKeyMsg:  .asciz   "\nEnter key to search:\n"
    InputSearchAnotherKeyMsg:  .asciz   "\nEnter 1 to search another key:\n"
    InputNewArrayMsg:  .asciz   "\nEnter 2 to enter new input array\n"
    InputExitMsg:  .asciz   "\nEnter 3 to exit the program\n"
    PosMsg:  .asciz   "\nSearch Element Pos is:\n"

  @ TEXT section
      .text
.globl _main

_main:
    @ register init to initialize buffer content
    mov r4,#0

ARRAY_ENTRY:
    @variable to save the input integers in array form
    mov r5, #0

    @take user input for number of elements in array
    mov r0,#1
    ldr r1,=InputSizeEntryMsg
    swi 0x069

    mov r0,#0
    ldr r1,=num_int
    swi 0x6c

    @save variable to stack for iteration
    str r0,[r1]
    ldr r1,[r1]
    str r1,[sp,#-8]

    @take user input for elements in input array
    mov r0,#1
    ldr r1,=InputEntryMsg
    swi 0x069

  @read user inputs in loop for array
  num_read_loop:
    ldr r1, =buffer        @ load address of the buffer in which we get stdin input is r1
    str r4,[r1]            @ initilialize buffer to 0
    ldr r3,[sp,#-8]
    @check if more inputs expected
    cmp r3,r4
    beq exit_read_loop
  
    mov r0,#0
    ldr r1,=buffer
    swi 0x6c
    str r0,[r1]

    @save the user input integer array 
    ldr     r1, =input
    mov     r3, r5
    ldr     r2, =buffer
    ldr     r2, [r2]
    str     r2, [r1, r3, lsl #2]
    add     r5, r5, #1

    @ read next number from user input
    ldr     r3,[sp,#-8]
    subs    r3,r3,#1
    str     r3,[sp,#-8]
    b num_read_loop

  exit_read_loop:

SEARCH_KEY:
  @Display message to ask for search element
  mov r0,#1
  ldr r1,=InputSearchKeyMsg
  swi 0x069

  @ get the element to search
  mov r0,#0
  ldr r1,=search_elem
  swi 0x6c
  str r0,[r1]

  @ search the key in input array
  ldr     r2, = input
  ldr     r3, =num_int
  ldr     r3,[r3]
  str     r3, [sp, #-8]
  ldr     r3, =search_elem
  ldr     r3,[r3]
  str     r3, [sp, #-12]

  @initalize position for search key as -1
  mvn     r3, #0
  str     r3, [sp, #-16]

  @ save function parameters to registers r0,r1,r2
  ldr     r2, [sp, #-12]
  ldr     r1, [sp, #-8]
  ldr     r0, =input
  bl      LINEAR_SEARCH
  str     r0, [sp, #-16]
  ldr     r1,=output_pos
  str     r0,[r1]
  mov     r0,#1
  ldr r1,=PosMsg
  swi 0x069
  ldr     r1,=output_pos
  ldr r1,[r1]
  swi     0x6b
  b NEXT_ACTION

@Display next actions for the program and request user input
NEXT_ACTION:
  mov r0,#1
  ldr r1,=InputSearchAnotherKeyMsg
  swi 0x069

  ldr r1,=InputNewArrayMsg
  swi 0x069
  
  ldr r1,=InputExitMsg
  swi 0x069

  mov r0,#0
  ldr r1,=buffer
  swi 0x6c
  str r0,[r1]
  cmp     r0, #1
  beq     SEARCH_KEY
  ldr r1,=buffer
  ldr r1,[r1]
  cmp     r1, #2
  beq     ARRAY_ENTRY

END_PROGRAM:
   swi 0x11


@subroutine for searching given key in array of numbers
@3 argumets
@ r0 = array base address
@ r1 = number of elements in array
@ r2 = search key
@ position is returned in r0

LINEAR_SEARCH:
        str     fp, [sp, #-4]!
        add     fp, sp, #0
        sub     sp, sp, #28
        @save the function arguments to stack of this sub-routine
        str     r0, [fp, #-16]
        str     r1, [fp, #-20]
        str     r2, [fp, #-24]
        @take variable to iterate
        mov     r3, #0
        str     r3, [fp, #-8]

SEARCH_LOOP:
        ldr     r2, [fp, #-8]
        ldr     r3, [fp, #-20]
        cmp     r2, r3
        bge     KEY_NOT_FOUND
        ldr     r3, [fp, #-8]
        lsl     r3, r3, #2
        ldr     r2, [fp, #-16]
        add     r3, r2, r3
        ldr     r2, [r3]
        ldr     r3, [fp, #-24]
        cmp     r2, r3
        bne     SEARCH_NEXT
        ldr     r3, [fp, #-8]
        add     r3, r3, #1
        b       END_SEARCH
SEARCH_NEXT:
        ldr     r3, [fp, #-8]
        add     r3, r3, #1
        str     r3, [fp, #-8]
        b       SEARCH_LOOP
KEY_NOT_FOUND:
        mvn     r3, #0
END_SEARCH:
        mov     r0, r3
        add     sp, fp, #0
        ldr     fp, [sp], #4
        bx      lr
