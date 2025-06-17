evaluate_postfix:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Initialize evaluation variables
    la $s6, eval_stack      # Base address of evaluation stack
    li $t7, 0               # Evaluation stack pointer (counts in words, not bytes)
    li $t1, 0               # Index for reading postfix
    
    # Begin evaluating postfix expression
eval_loop:
    # Skip spaces
    add $t3, $s1, $t1       # Calculate address of current char
    lb $t0, 0($t3)          # Load current char
    beq $t0, 32, eval_skip_space  # Skip spaces
    
    # Check if we've reached end of postfix expression
    beq $t1, $s5, end_eval  # End if we've processed all chars
    beq $t0, 0, end_eval    # End if null terminator
    
    # Check if character is a digit (start of a number)
    blt $t0, 48, not_digit_eval  # If less than '0', not a digit
    bgt $t0, 57, not_digit_eval  # If greater than '9', not a digit
    
    # It's a digit - read the entire number and push to stack
    li $t4, 0  # Initialize number value
    
read_number_eval:
    # Convert ASCII to value and add to number
    addi $t9, $t0, -48      # Convert ASCII to value (subtract 48)
    mul $t4, $t4, 10        # Shift current value left (multiply by 10)
    add $t4, $t4, $t9       # Add new digit
    
    # Move to next character
    addi $t1, $t1, 1        # Increment postfix index
    add $t3, $s1, $t1       # Calculate address of next char
    lb $t0, 0($t3)          # Load next char
    
    # Check if next char is also a digit
    blt $t0, 48, push_number_eval  # If less than '0', not a digit
    bgt $t0, 57, push_number_eval  # If greater than '9', not a digit
    
    # If it is a digit, continue building the number
    j read_number_eval
    
push_number_eval:
    # Push the number onto the evaluation stack
    sll $t9, $t7, 2         # Calculate offset (stack_pointer * 4 bytes)
    add $t9, $s6, $t9       # Calculate address to store value
    sw $t4, 0($t9)          # Store value on stack
    addi $t7, $t7, 1        # Increment stack pointer
    j eval_loop
    
not_digit_eval:
    # Check if it's an operator
    jal is_operator
    beq $v0, 0, eval_skip_char  # If not operator, skip
    
    # It's an operator - perform operation
    # First, ensure we have at least 2 operands
    blt $t7, 2, eval_error  # Error if less than 2 values on stack
    
    # Pop two values from stack
    addi $t7, $t7, -1       # Decrement stack pointer
    sll $t9, $t7, 2         # Calculate offset (stack_pointer * 4)
    add $t9, $s6, $t9       # Calculate address of second operand
    lw $t4, 0($t9)          # Load second operand (right operand)
    
    addi $t7, $t7, -1       # Decrement stack pointer again
    sll $t9, $t7, 2         # Calculate offset for first operand
    add $t9, $s6, $t9       # Calculate address of first operand
    lw $t3, 0($t9)          # Load first operand (left operand)
    
    # Determine which operation to perform
    beq $t0, 43, op_add     # '+'
    beq $t0, 45, op_sub     # '-'
    beq $t0, 42, op_mul     # '*'
    beq $t0, 47, op_div     # '/'
    beq $t0, 36, op_exp     # '$' (exponent)
    j eval_error            # Unknown operator
    
op_add:
    add $t8, $t3, $t4       # Perform addition
    j push_result
    
op_sub:
    sub $t8, $t3, $t4       # Perform subtraction
    j push_result
    
op_mul:
    mul $t8, $t3, $t4       # Perform multiplication
    j push_result
    
op_div:
    beq $t4, 0, eval_error  # Check division by zero
    div $t8, $t3, $t4       # Perform division
    j push_result
    
op_exp:
    # Power operation (a^b) for integers
    li $t8, 1               # Initialize result to 1
    ble $t4, 0, push_result # If exponent <= 0, result is 1
    
exp_loop:
    mul $t8, $t8, $t3       # Multiply result by base
    addi $t4, $t4, -1       # Decrement exponent
    bgtz $t4, exp_loop      # Continue if exponent > 0
    
push_result:
    # Push result back onto stack
    sll $t9, $t7, 2         # Calculate offset (stack_pointer * 4)
    add $t9, $s6, $t9       # Calculate address to store result
    sw $t8, 0($t9)          # Store result on stack
    addi $t7, $t7, 1        # Increment stack pointer
    
eval_skip_char:
    # Move to next character in postfix expression
    addi $t1, $t1, 1        # Increment postfix index
    j eval_loop             # Process next character
    
eval_skip_space:
    # Skip space character
    addi $t1, $t1, 1        # Increment postfix index
    j eval_loop             # Process next character
    
eval_error:
    # Handle evaluation error (e.g., division by zero)
    li $v0, 4
    la $a0, error_msg
    syscall
    j eval_exit
    
end_eval:
    # Check if we have exactly one value on stack (the final result)
    bne $t7, 1, eval_error  # Error if not exactly one value
    
    # Get the final result from the evaluation stack
    li $t9, 0               # Index 0
    sll $t9, $t9, 2         # Convert to byte offset (0 * 4)
    add $t9, $s6, $t9       # Calculate address of result
    lw $t8, 0($t9)          # Load result
    
    # Print the result
    li $v0, 4
    la $a0, result_prompt
    syscall
    
    li $v0, 1
    move $a0, $t8           # Print result as integer
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
eval_exit:
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra