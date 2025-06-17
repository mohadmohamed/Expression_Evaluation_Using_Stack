# data.asm - Data segment definitions for Postfix Expression Calculator

.data
# Ensure alignment of all data by adding .align directives
.align 2              # Align on word boundary (2^2 = 4 bytes)
input_prompt:    .asciiz "Enter infix expression: "
.align 2
postfix_prompt:  .asciiz "Postfix expression: "
.align 2
result_prompt:   .asciiz "Result: "
.align 2
continue_prompt: .asciiz "Continue? (y/n): "
.align 2
exit_msg:        .asciiz "Exiting program.\n"
.align 2
newline:         .asciiz "\n"
.align 2
error_msg:       .asciiz "Error in evaluation\n"
.align 2
input_buffer:    .space 100     # Buffer for infix expression
.align 2
postfix_result:  .space 100     # Buffer for postfix result
.align 2
op_stack:        .space 100     # Stack for operators during conversion
.align 2
eval_stack:      .space 400     # Stack for evaluation (stores integers, 4 bytes each)
.align 2
space:           .asciiz " "    # Space character for postfix output separation

.text
.globl main

main:
    li $v0, 4
    la $a0, input_prompt
    syscall
    
    li $v0, 8
    la $a0, input_buffer
    li $a1, 100
    syscall
    
    jal infix_to_postfix
    
    li $v0, 4
    la $a0, postfix_prompt
    syscall
    
    li $v0, 4
    la $a0, postfix_result
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall

    jal evaluate_postfix
    
    li $v0, 4
    la $a0, continue_prompt
    syscall
    
    li $v0, 12
    syscall
    
    move $t0, $v0
    
    li $v0, 12
    syscall
    
    li $t1, 121
    beq $t0, $t1, main
    
    li $v0, 4
    la $a0, exit_msg
    syscall
    
    li $v0, 10
    syscall



.include "conversion.asm"
.include "evaluation.asm"
.include "utils.asm"