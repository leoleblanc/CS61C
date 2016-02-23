.data

lfsr:
        .align 4
        .half
        0x1
.text

# Implements a 16-bit lfsr
#
# Arguments: None
lfsr_random:

        la $t0 lfsr #load the address of lfsr into $t0
        lhu $v0 0($t0) #load the value of $t0 into $v0

        # YOUR CODE HERE #
        #problem with using .data var? yes
        
        li $t1 0 #set i to 0
        li $t2 16 #set something to 16
loop: #$t4 is highest
	bge $t1 $t2 end #if i >= 16, return
	srl $t3 $v0 0 #shift reg right by 0, put into $t3
	srl $t4 $v0 2 #shift reg right by 2, put into $t4
	xor $t4 $t4 $t3 #perform XOR on $t4 & $t3, put into $t4
	srl $t3 $v0 3 #shift reg right by 3, put into $t3
	xor $t4 $t4 $t3 #perform XOR on $t4 & $t3, put into $t4
	srl $t3 $v0 5 #shift reg right by 5, put into $t3
	xor $t4 $t4 $t3 #perform the final XOR, put into $t4
	#at this point, $t4 should contain "highest"
	srl $t3 $v0 1 #shift reg right by 1, put into $t3
	sll $t4 $t4 15 #shift highest left by 15, put into $t4
	or $t5 $t3 $t4 #put the result of using OR on $t3 & $t4 into $t5
	#sw $t5 0($t0) #store the value into the memory address $t0
	and $v0 $t5 0xFFFF #get only the first 16 bits
	#lhu $v0 0($t0) #get the (half-word of the) value I just stored, put into $v0
	addi $t1 $t1 1 #increment i by 1
	j loop #repeat the loop
end:
        la $t0 lfsr
        sh $v0 0($t0)
        jr $ra
