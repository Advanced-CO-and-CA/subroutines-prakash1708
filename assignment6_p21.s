
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
    sorted_input: .word 0,0,0,0,0,0,0,0,0,0,0
    search_elem: .word 0
    output_pos: .word 0

    @ Constant Strings to display

    InputSizeEntryMsg:  .asciz   "\nEnter number of inputs in the array(max-limit 10)\n"
    InputEntryMsg:  .asciz   "\nEnter numbers in sorted increasing order:\n"
    InputSearchKeyMsg:  .asciz   "\nEnter key to search:\n"
    InputSearchAnotherKeyMsg:  .asciz   "\nEnter 1 to search another key\n"
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
    ldr     r1, =sorted_input
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
  ldr     r2, = sorted_input
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
  ldr     r0, =sorted_input
  bl      FAST_SEARCH
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
@ applied binary search logic
@ took lower, upper bound and middle value variable on stack
@ saved 3 input arguments to stack
@ search is always divided in half the list with every iteration, so for 5 elements- maximum search will be 3 times

FAST_SEARCH:
        str     fp, [sp, #-4]!
        add     fp, sp, #0
        @move sp to a safer range and work with fp
        sub     sp, sp, #36

        @restore function arguments from registers r0-r2 ro frame-pointer locations
        str     r0, [fp, #-24]    @array
        str     r1, [fp, #-28]    @number of inputs in array
        str     r2, [fp, #-32]    @search-key
        @initialize lower bound for the list
        mov     r3, #0
        str     r3, [fp, #-8]   @ This will be updated based on the search
        @upper bound for the list : equal to number of inputs
        ldr     r3, [fp, #-28]
        str     r3, [fp, #-12]  @store upper bound - this will be updated based on the search
SEARCH_LOOP:
        ldr     r2, [fp, #-12] @ read upper bound
        ldr     r3, [fp, #-8]  @ read lower bound
        cmp     r2, r3         @ if upper < lower , this is end of list
        blt     KEY_NOT_FOUND
        ldr     r2, [fp, #-8]  @ read lower bound
        ldr     r3, [fp, #-12] @ read upper bound
        add     r3, r2, r3     @ lower + upper
        lsr     r2, r3, #31    @ r2 <- upper >> 31
        add     r3, r2, r3     @ r3 <- r2 + upper
        asr     r3, r3, #1     @ r3 <- r3/2 (lower + upper)/2
        str     r3, [fp, #-16] @ store the value on stack
        ldr     r3, [fp, #-16] @ read the middle index
        lsl     r3, r3, #2     @ read middle element from array
        ldr     r2, [fp, #-24]
        add     r3, r2, r3     
        ldr     r2, [r3]
        ldr     r3, [fp, #-32]
        cmp     r2, r3         @ compare the middle value with search-key
        bne     KEY_NOT_MATCH
        ldr     r3, [fp, #-16] @ match found : read the index
        add     r3, r3, #1     @ update position +1
        b       END_SEARCH     @ end search
KEY_NOT_MATCH:
        ldr     r3, [fp, #-16] @ read the middle element
        lsl     r3, r3, #2
        ldr     r2, [fp, #-24]
        add     r3, r2, r3
        ldr     r2, [r3]
        ldr     r3, [fp, #-32]  @ read search key
        cmp     r2, r3
        bge     DIVITE_INPUT_LIST  @ if middle value is greater than search key
        ldr     r3, [fp, #-16] @ read the current middle position
        add     r3, r3, #1
        str     r3, [fp, #-8] @ update lower bound to middle position +1
        b       SEARCH_LOOP
DIVITE_INPUT_LIST:
        ldr     r3, [fp, #-16]    @ read the current middle position
        sub     r3, r3, #1
        str     r3, [fp, #-12]    @ update upper bound to middle position -1
        b       SEARCH_LOOP
KEY_NOT_FOUND:
        mvn     r3, #0      @ update return position to -1
END_SEARCH:
        mov     r0, r3      @ update return position in r0
        add     sp, fp, #0
        ldr     fp, [sp], #4
        bx      lr
