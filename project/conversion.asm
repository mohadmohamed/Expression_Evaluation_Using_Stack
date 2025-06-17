infix_to_postfix:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Initialize variables
    la $s0, input_buffer    # Input string address
    la $s1, postfix_result  # Output string address
    la $s2, op_stack        # Stack address for operators
    li $t2, 0               # Stack pointer (empty)
    li $t1, 0               # Input string index
    li $t5, 0               # Postfix string index
    li $s4, 0               # Length of input string
    
    # Get length of input string (find null terminator)
    move $t3, $s0
string_length_loop:
    lb $t4, 0($t3)
    beq $t4, 10, end_string_length    # Check for newline (enter key)
    beq $t4, 0, end_string_length     # Check for null terminator
    addi $t3, $t3, 1
    addi $s4, $s4, 1
    j string_length_loop
end_string_length:
    
    # Begin conversion algorithm
process_loop:
    # Get current character
    add $t3, $s0, $t1       # Calculate address of current char
    lb $t0, 0($t3)          # Load current char
    
    # Check if we've reached end of string
    beq $t0, 10, end_process_loop    # Newline
    beq $t0, 0, end_process_loop     # Null terminator
    
    # Skip spaces and commas
    beq $t0, 32, skip_char  # Space
    beq $t0, 44, skip_char  # Comma
    
    # Check if character is a digit (0-9)
    blt $t0, 48, not_digit_check  # If less than '0', not a digit
    bgt $t0, 57, not_digit_check  # If greater than '9', not a digit
    
    # It's a digit - handle multi-digit numbers
    j handle_number
    
not_digit_check:
    # Check if character is another operand (A-Z, a-z)
    jal is_operand
    beq $v0, 1, handle_operand
    
    # Check if it's an operator
    jal is_operator
    beq $v0, 1, handle_operator
    
    # Check if it's an open parenthesis
    beq $t0, 40, handle_open_paren  # '('
    
    # Check if it's a close parenthesis
    beq $t0, 41, handle_close_paren  # ')'
    
    # If none of the above, go to next character
    j skip_char

# Handle multi-digit numbers by reading consecutive digits
handle_number:
    # Start building a number
    li $t8, 0  # Number accumulator
    
number_loop:
    # Add the current digit to the number
    addi $t9, $t0, -48      # Convert ASCII to value (subtract 48)
    mul $t8, $t8, 10        # Shift current value left (multiply by 10)
    add $t8, $t8, $t9       # Add new digit
    
    # Look ahead to see if next char is also a digit
    addi $t1, $t1, 1        # Move to next character
    add $t3, $s0, $t1       # Calculate address of next char
    lb $t0, 0($t3)          # Load next char
    
    # Check if next char is also a digit
    blt $t0, 48, end_number # If less than '0', not a digit
    bgt $t0, 57, end_number # If greater than '9', not a digit
    
    # If it is a digit, continue building the number
    j number_loop
    
end_number:
    # Add the multi-digit number to the postfix result
    # We'll convert the number back to ASCII digits
    
    # First add a space for separation
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 32              # Space character
    sb $t7, 0($t6)          # Store space in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    # Now convert the number and add it
    move $t7, $t8           # Copy the number to $t7
    
    # Special case for 0
    bgtz $t7, not_zero_number
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 48              # ASCII '0'
    sb $t7, 0($t6)          # Store '0' in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    j number_to_postfix_done
    
not_zero_number:
    # Get number of digits first (for reversing)
    move $t9, $t8           # Copy the number to $t9
    li $t7, 0               # Digit counter
    
count_digits:
    beqz $t9, count_digits_done
    div $t9, $t9, 10        # Divide by 10
    addi $t7, $t7, 1        # Count another digit
    j count_digits
    
count_digits_done:
    # Now add each digit to postfix
    # We add them in reverse order to match the number representation
    move $t9, $t8           # Copy the number to $t9
    move $t4, $t5           # Start address for number in postfix
    add $t4, $t4, $t7       # End address for number in postfix
    addi $t4, $t4, -1       # Adjust for 0-indexing
    
    # Add digits from right to left
    move $t3, $t4           # Current position in postfix buffer
    
digit_to_postfix:
    rem $t6, $t9, 10        # Get rightmost digit
    div $t9, $t9, 10        # Remove rightmost digit
    
    addi $t6, $t6, 48       # Convert to ASCII
    add $t7, $s1, $t3       # Calculate address to store the digit
    sb $t6, 0($t7)          # Store digit in postfix buffer
    addi $t3, $t3, -1       # Move to next position (left)
    
    bgtz $t9, digit_to_postfix  # Continue if more digits
    
    # Update postfix index
    addi $t5, $t4, 1        # Update postfix index
    
number_to_postfix_done:
    # Add a space after the number
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 32              # Space character
    sb $t7, 0($t6)          # Store space in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    # Continue with the next character
    j process_loop

handle_operand:
    # Add operand directly to postfix result
    add $t6, $s1, $t5       # Calculate address to store the character
    sb $t0, 0($t6)          # Store character in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    # Add a space after the operand
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 32              # Space character
    sb $t7, 0($t6)          # Store space in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    j skip_char

handle_operator:
    # Process operators according to precedence
    # While stack not empty and top has higher precedence, pop to output
operator_loop:
    beq $t2, 0, push_op     # If stack empty, push operator
    
    # Get top of stack
    addi $t3, $t2, -1       # Calculate index of top element
    add $t3, $s2, $t3       # Calculate address of top element
    lb $s3, 0($t3)          # Load top element
    
    # If top is '(', push new operator
    beq $s3, 40, push_op    # If top is '(', push operator
    
    # Check if top has higher precedence
    move $a0, $s3           # First arg: top of stack
    move $a1, $t0           # Second arg: current operator
    jal has_higher_precedence
    beq $v0, 0, push_op     # If not higher precedence, push new operator
    
    # Pop the operator to output
    add $t6, $s1, $t5       # Calculate address to store the popped operator
    sb $s3, 0($t6)          # Store operator in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    # Add a space after the operator
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 32              # Space character
    sb $t7, 0($t6)          # Store space in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    addi $t2, $t2, -1       # Decrement stack pointer (pop)
    j operator_loop         # Continue checking stack
    
push_op:
    # Push current operator to stack
    add $t3, $s2, $t2       # Calculate address to push operator
    sb $t0, 0($t3)          # Push operator to stack
    addi $t2, $t2, 1        # Increment stack pointer
    j skip_char

handle_open_paren:
    # Push '(' to stack
    add $t3, $s2, $t2       # Calculate address to push '('
    sb $t0, 0($t3)          # Push '(' to stack
    addi $t2, $t2, 1        # Increment stack pointer
    j skip_char

handle_close_paren:
    # Pop all operators until matching '('
close_paren_loop:
    beq $t2, 0, skip_char   # Error if stack empty (mismatched parentheses)
    
    # Get top of stack
    addi $t3, $t2, -1       # Calculate index of top element
    add $t3, $s2, $t3       # Calculate address of top element
    lb $s3, 0($t3)          # Load top element
    addi $t2, $t2, -1       # Pop from stack
    
    # If '(', we're done with this closing parenthesis
    beq $s3, 40, skip_char  # If '(', exit this loop
    
    # Otherwise, add operator to output
    add $t6, $s1, $t5       # Calculate address to store the popped operator
    sb $s3, 0($t6)          # Store operator in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    # Add a space after the operator
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 32              # Space character
    sb $t7, 0($t6)          # Store space in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    j close_paren_loop      # Continue popping until '('

skip_char:
    # Move to next character
    addi $t1, $t1, 1        # Increment input index
    j process_loop          # Process next character

end_process_loop:
    # After processing all characters, pop remaining operators from stack
empty_stack_loop:
    beq $t2, 0, finish_conversion   # If stack empty, we're done
    
    # Get top of stack
    addi $t3, $t2, -1       # Calculate index of top element
    add $t3, $s2, $t3       # Calculate address of top element
    lb $s3, 0($t3)          # Load top element
    addi $t2, $t2, -1       # Pop from stack
    
    # Skip '(' if any left (should not happen with balanced parentheses)
    beq $s3, 40, empty_stack_loop  # Skip '(' if any
    
    # Add operator to output
    add $t6, $s1, $t5       # Calculate address to store the popped operator
    sb $s3, 0($t6)          # Store operator in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    # Add a space after the operator
    add $t6, $s1, $t5       # Calculate address to store the character
    li $t7, 32              # Space character
    sb $t7, 0($t6)          # Store space in postfix buffer
    addi $t5, $t5, 1        # Increment postfix index
    
    j empty_stack_loop      # Continue popping until stack is empty

finish_conversion:
    # Null-terminate the postfix result
    add $t6, $s1, $t5       # Calculate address for null terminator
    sb $zero, 0($t6)        # Add null terminator
    
    # Store final length of postfix expression
    move $s5, $t5           # Save length for later use
    
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra