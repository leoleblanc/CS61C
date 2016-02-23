.text

# Decodes a quadtree to the original matrix
#
# Arguments:
#     quadtree (qNode*)
#     matrix (void*)
#     matrix_width (int)
#
# Recall that quadtree representation uses the following format:
#     struct qNode {
#         int leaf;
#         int size;
#         int x;
#         int y;
#         int gray_value;
#         qNode *child_NW, *child_NE, *child_SE, *child_SW;
#     }

quad2matrix:

        # YOUR CODE HERE #
        
        #maybe for this I don't need to shift left by 2 too?
        
        #first, store what's in the saved registers onto the stack
        
        addiu $sp $sp -32
        sw $s0 0($sp)
        sw $s1 4($sp)
        sw $s2 8($sp)
        sw $s3 12($sp)
        sw $s4 16($sp)
        sw $s5 20($sp)
        sw $s6 24($sp)
        sw $s7 28($sp)
        
        #then, load the arguments
        #are they already in $a0-$a3?
        
        #quadtree (qNode*)
        #lw $s0 32($sp)
	#matrix
	#lw $s1 36($sp)
	#matrix_width
	#lw $s2 40($sp)
	
	#first, determine if the node is a leaf; if it is, can go on to filling matrix
	lw $t0 0($a0) #get whether value is a leaf or not
	bne $t0 $0 is_leaf #if it is a leaf, jump to is_leaf
	j not_leaf #else, jump to not_leaf
is_leaf: #so it's a leaf, time to start filling the matrix
	lw $t0 4($a0) #get its size
	lw $t2 8($a0) #get the y-coordinate
	lw $t1 12($a0) #get the x-coordinate
	lw $t3 16($a0) #get its gray_value
	add $t4 $t1 $t0 #get y + size
	add $t5 $t2 $t0 #get x + size
	#curr_y will ALWAYS be less than curr_y + y
	add $t6 $t1 $0 #set curr_y = y
curr_y_loop:
	beq $t6 $t4 return #if curr_y == y + size, jump to return
	add $t7 $t2 $0 #set curr_x = x
curr_x_loop:
	beq $t7 $t5 increment_curr_y #if curr_x == x + size, time to increment curr_y
	
	#need to find address of matrix[curr_x + curr_y * matrix_width], can only use $t8, #t9
	mul $t8 $t6 $a2 #get curr_y * matrix_width
	add $t8 $t8 $t7 #now has curr_y * matrix_width + curr_x, the offset (multiply by 4?)
	add $t8 $t8 $a1 #add the offset by the memory address of matrix, now has address of matrix[curr_x+curr_y*matrix_width]
	sb $t3 0($t8) #do matrix[curr_x+curr_y*matrix_width] = gray value
	j increment_curr_x #jump to increment curr_x at the end
increment_curr_x:
	addi $t7 $t7 1 #curr_x++
	j curr_x_loop
increment_curr_y:
	addi $t6 $t6 1 #curr_y++
	j curr_y_loop
not_leaf:
	#the value is not a leaf, so... need to gather address of children nodes, set to equal recursive calls
	#put address $a0 into $s0, for recursion
	add $s0 $a0 $0 #now, $s0 has address from $a0
	
	lw $a0 20($s0) #get address of child_NW
	addiu $sp $sp -4
	sw $ra 0($sp)
	jal quad2matrix #do the recursive call, on the child_NW
	lw $ra 0($sp)
	addiu $sp $sp 4
	
	lw $a0 24($s0) #get address of child_NE
	addiu $sp $sp -4
	sw $ra 0($sp)
	jal quad2matrix
	lw $ra 0($sp)
	addiu $sp $sp 4
	
	lw $a0 28($s0) #get address of child_SE
	addiu $sp $sp -4
	sw $ra 0($sp)
	jal quad2matrix
	lw $ra 0($sp)
	addiu $sp $sp 4
	
	lw $a0 32($s0) #get address of child_SW
	addiu $sp $sp -4
	sw $ra 0($sp)
	jal quad2matrix
	lw $ra 0($sp)
	addiu $sp $sp 4

return:
	#for the *very* end, when i need to recover variables
	lw $s0 0($sp)
        lw $s1 4($sp)
        lw $s2 8($sp)
        lw $s3 12($sp)
        lw $s4 16($sp)
        lw $s5 20($sp)
        lw $s6 24($sp)
        lw $s7 28($sp)
        addiu $sp $sp 32
        jr $ra
