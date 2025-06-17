is_operand:
    li $v0, 0               # Default: not an operand
    blt $t0, 48, end_is_operand
    ble $t0, 57, is_operand_true
    blt $t0, 65, end_is_operand
    ble $t0, 90, is_operand_true
    blt $t0, 97, end_is_operand
    ble $t0, 122, is_operand_true
    j end_is_operand
is_operand_true:
    li $v0, 1               # It is an operand
end_is_operand:
    jr $ra                  # Return to caller

# Function: is_operator
# Determines if a character is an operator (+, -, *, /, $)
# Input: $t0 - character to check
# Output: $v0 - 1 if operator, 0 if not
is_operator:
    li $v0, 0               # Default: not an operator
    beq $t0, 43, is_operator_true  # '+'
    beq $t0, 45, is_operator_true  # '-'
    beq $t0, 42, is_operator_true  # '*'
    beq $t0, 47, is_operator_true  # '/'
    beq $t0, 36, is_operator_true  # '$'
    j end_is_operator
is_operator_true:
    li $v0, 1               # It is an operator
end_is_operator:
    jr $ra                  # Return to caller

# Function: get_operator_weight
# Gets the precedence weight of an operator
# Input: $a0 - operator character
# Output: $v0 - weight (higher = higher precedence)
get_operator_weight:
    li $v0, -1              # Default weight
    beq $a0, 43, weight_1   # '+'
    beq $a0, 45, weight_1   # '-'
    beq $a0, 42, weight_2   # '*'
    beq $a0, 47, weight_2   # '/'
    beq $a0, 36, weight_3   # '$'
    j end_get_weight
weight_1:
    li $v0, 1               # Weight 1 (lowest)
    j end_get_weight
weight_2:
    li $v0, 2               # Weight 2 (medium)
    j end_get_weight
weight_3:
    li $v0, 3               # Weight 3 (highest)
end_get_weight:
    jr $ra                  # Return to caller

# Function: is_right_associative
# Determines if an operator is right associative
# Input: $a0 - operator character
# Output: $v0 - 1 if right associative, 0 if not
is_right_associative:
    li $v0, 0               # Default: not right associative
    beq $a0, 36, right_assoc_true  # '$' is right associative
    j end_is_right_assoc
right_assoc_true:
    li $v0, 1               # It is right associative
end_is_right_assoc:
    jr $ra                  # Return to caller

# Function: has_higher_precedence
# Determines if operator1 has higher precedence than operator2
# Input: $a0 - operator1, $a1 - operator2
# Output: $v0 - 1 if op1 has higher precedence, 0 if not
has_higher_precedence:
    addi $sp, $sp, -4       # Allocate space on stack
    sw $ra, 0($sp)          # Save return address
    move $t7, $a0           # Save operator1
    move $t8, $a1           # Save operator2
    move $a0, $t7           # Set argument for get_operator_weight
    jal get_operator_weight # Get weight of operator1
    move $t7, $v0           # op1_weight
    move $a0, $t8           # Set argument for get_operator_weight
    jal get_operator_weight # Get weight of operator2
    move $t8, $v0           # op2_weight
    bne $t7, $t8, compare_weights
    move $a0, $t7           # Set argument for is_right_associative
    jal is_right_associative # Check if right associative
    beq $v0, 1, not_higher_prec
    j higher_prec
compare_weights:
    bgt $t7, $t8, higher_prec
not_higher_prec:
    li $v0, 0               # Not higher precedence
    j end_has_higher_prec
higher_prec:
    li $v0, 1               # Higher precedence
end_has_higher_prec:
    lw $ra, 0($sp)          # Restore return address
    addi $sp, $sp, 4        # Deallocate space on stack
    jr $ra                  # Return to caller