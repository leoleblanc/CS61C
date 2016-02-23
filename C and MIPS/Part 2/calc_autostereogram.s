.text

# Generates an autostereogram inside of buffer
#
# Arguments:
#     autostereogram (unsigned char*)
#     depth_map (unsigned char*)
#     width
#     height
#     strip_size
calc_autostereogram:

        # Allocate 5 spaces for $s0-$s5
        # (add more if necessary)
        #addiu $sp $sp -20 #move the stack pointer down by 20, to make space
        addiu $sp $sp -32
        sw $s0 0($sp)  #put whatever is in $s0 into the first spot
        sw $s1 4($sp)  #put whatever is in $s1 into the second spot
        sw $s2 8($sp)  #put whatever is in $s2 into the third spot
        sw $s3 12($sp) #put whatever is in $s3 into the fourth spot
        sw $s4 16($sp) #put whatever is in $s4 into the fifth spot
        
        sw $s5 20($sp) #want this register
        sw $s6 24($sp) #want this register
        sw $s7 28($sp) #want this register


        # autostereogram
        lw $s0 32($sp)
        # depth_map
        lw $s1 36($sp)
        # width
        lw $s2 40($sp)
        # height
        lw $s3 44($sp)
        # strip_size
        lw $s4 48($sp)
        # YOUR CODE HERE #

        li $s5 0 #initialize i to 0
width_loop:
	bge $s5 $s2 return #this is the return case, if i >= M
        li $s6 0 #initialize j to 0
        
height_loop:
	bge $s6 $s3 increment_i #if j >= N, go to increment i
	#find address of I(i, j)
	mul $t1 $s6 $s2 #multiply j by width($s2), put into $t1
	add $t0 $s5 $t1 #add i and j*width, this is now displacement
	#add $t0 $t0 $t1 #add i*4 and j*4*width, this is now the displacement, put into $t0
	add $s7 $s0 $t0 #now, $s7 has the memory address of I(i, j)
	
	blt $s5 $s4 if_case #if i < S, jump to if case
	j else_case
	
if_case:
	#set I(i, j) to some random number from 0 to 255
	addiu $sp $sp -4 #move stack back for $ra
	sw $ra 0($sp) #store $ra
	jal lfsr_random #call lfsr_random, put value in $v0
	#jal debug_random1
	lw $ra 0($sp) #reload $ra
	addiu $sp $sp 4 #move stack back to where it was
	andi $t0 $v0 0xFF #take the first 8 bits of the result, put into $t0
	sb $t0 0($s7) #store $t0 into I(i,j)
	j increment_j #jump to the increment zone

else_case:
	#set I(i, j) to I((i+depth(i, j) - S), j)
	#this part is to get depth(i, j)
	#sll $t0 $s5 2 #multiply i by 4
	#sll $t1 $s6 2 #multiply j by 4
	mul $t1 $s6 $s2 #multiply j by width
	#mul $t1 $t1 $s2 #multiply j*4 by width ($s2), put into $t1
	add $t0 $s5 $t1 #add i and j*width, this is now the displacement, put into $t0
	add $t7 $s1 $t0 #now, $t7 has address of depth(i, j)
	lb $t7 0($t7) #now, $t7 has value of depth(i, j), the byte

	add $t0 $t7 $s5 #$t0 has i + depth(i, j)
	sub $t6 $t0 $s4 #$t6 has i + depth(i, j) - S
	
	#sll $t0 $t6 2 #multiply (i+depth(i,j)-S) by 4
	#sll $t1 $s6 2 #multiply j by 4
	#need to multiply j by width
	mul $t0 $s2 $s6 #j * width
	add $t1 $t6 $t0 #add (i+depth(i, j) - S) and j*width, this is displacement
	add $t1 $t1 $s0 #add displacement and address of autostereogram
	lb $t1 0($t1) #put value of the above address into $t1
	sb $t1 0($s7) #put value of $t1 into I(i,j)
	j increment_j
	
increment_j:
	addi $s6 $s6 1 #increment j by 1
	j height_loop #return to height_loop

increment_i:
	addi $s5 $s5 1 #increment i by 1
	j width_loop #return to width_loop
	
return:
	#this happens at the end, to bring everything back
	#A.K.A: DO NOT MESS WITH THIS
	#need to restore the s registers
	#restored the s registers
        lw $s0 0($sp)
        lw $s1 4($sp)
        lw $s2 8($sp)
        lw $s3 12($sp)
        lw $s4 16($sp)
        
        lw $s5 20($sp)
        lw $s6 24($sp)
        lw $s7 28($sp)
        #addiu $sp $sp 20
        addiu $sp $sp 32
        jr $ra
        
