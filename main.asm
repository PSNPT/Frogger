#####################################################################
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
#####################################################################

.data
displayAddress: .word 0x10008000
color_safe: .word 0x145A32
color_road: .word 0x515A5A
color_car: .word 0xE74C3C
color_river: .word 0x85C1E9
color_finish: .word 0xF4FF00
color_frog: .word 0x1CFF00
color_frog_eye: .word 0xFF00B5
color_log: .word 0x873600
cars: .word 0x1000A800, 0x1000A880, 0x1000B040,  0x1000B0C0
logs: .word 0x10009000, 0x10009080, 0x10009800,  0x10009880
frog: .word 0x1000BA88
frog_start: .word 0x1000BA88
frog_x: .word 5
frog_y: .word 1
frog_orientation: .word 0
lives: .word 3
color_finish1: .word 0xF4FF00
color_finish2: .word 0xF4FF00
color_finish3: .word 0xF4FF00
color_finished: .word 0x8D8D8D
size_car: .word 0
size_log: .word 0
speed: .word 17
powerup_time: .word 0
powerup_time_status: .word 0
.text


pregen: # Generate widths for log and cars
li $v0, 42 # Range random number
li $a0, 0 # I.d of RNG
li $a1, 9 # Upper bound
syscall # Store RNG number in $a0

addi $a0, $a0, 8 # Add 8 to generated width

sw $a0, size_car # Store size of car

li $v0, 42 # Range random number
li $a0, 0 # I.d of RNG
li $a1, 9 # Upper bound
syscall # Store RNG number in $a0

addi $a0, $a0, 8 # Add 8 to generated width

sw $a0, size_log # Store size of car

j process

#########################################################################

process: # Main process
lw $t9, lives # Load number of lives
beq $t9, 0, kill # End game once player has 0 lives

jal draw_start # Draw start tiles
jal draw_road # Draw road tiles
jal draw_middle # Draw middle tiles
jal draw_river # Draw river tiles
jal draw_end # Draw end tiles
jal draw_finish # Draw finish blocks

jal draw_cars # Draw cars
jal draw_logs # Draw logs
jal powerup_gen_time # Draw powerup

jal colision # Detects colisions
jal activate_powerup_time # Check for powerup activation
jal move_frog # Move frog

jal colision # Detects colisions
jal activate_powerup_time # Check for powerup activation
jal draw_frog # Draw frog

jal finish # Check if frog reached finish blocks

jal move_cars # Move cars
jal move_logs # Move logs
jal frog_on_log # Dynamic movement w/ colision detection

li $v0, 32 # Sleep
lw $a0, speed # load speed
	
syscall # Initiate sleep for 17ms

j process # Central process loop

############################################################

kill:
j Exit # Exit state
############################################################

activate_powerup_time:
# Set refresh to 10hz
lw $t0, frog # Load current pos of frog
lw $t1, powerup_time # Load current pos of powerup_time
addiu $t1, $t1, 512 # Calibrate pointer
addiu $t2, $t1, 32 # Shift to end of powerup header

activate_powerup_time_check_1:
bgeu $t0, $t1, activate_powerup_time_check_2 # Check upper bound for powerup
j activate_powerup_time_fail # Jump to end

activate_powerup_time_check_2:
bltu $t0, $t2, activate_powerup_time_success # Activate the powerup
j activate_powerup_time_fail # Jump to end

activate_powerup_time_success:
li $t1, 100 # 10hz
sw $t1, speed # Set speed
li $t1, 2 # Status
sw $t1, powerup_time_status # Set status to used
jr $ra # Return to caller

activate_powerup_time_fail:
jr $ra # Return to caller

############################################################
powerup_gen_time:
# Generate time powerup on field
lw $t0, powerup_time_status # Load status of powerup time
beq $t0, 1, draw_powerup # If powerup location is set
beq $t0, 2, end_powerup_gen_time # If powerup used, do not generate again

li $v0, 42 # Range random number
li $a0, 0 # I.d of RNG
li $a1, 57 # Upper bound
syscall # Store RNG number in $a0

addu $t0, $zero, $a0 # Store result for x deviation
li $t1, 4 # Load 4
multu $t1, $t0 # Multiply 4 x $t1
mflo $t0 # Store result of mult in $t0

li $v0, 42 # Range random number
li $a0, 0 # I.d of RNG
li $a1, 2 # Upper bound
syscall # Store RNG number in $a0

addu $t1, $zero, $a0 # Store result for multiple of y deviation

li $t2, 6144 # Load 6144 in $t2

multu $t1, $t2 # Multiply random y deviation x 6144

mflo $t1 # Move result of multiplication in $t1

add $t0, $t0, $t1 # Deviation

addiu $a0, $t0, 0x1000A000 # Store random location in the grid in $a0

sw $a0, powerup_time # Set powerup location

li $t0, 1 # Load 1 in $t0
sw $t0, powerup_time_status # Change status of powerup

draw_powerup: # Powerup location set
lw $a2, powerup_time # Set location
addi $a0, $zero, 8 # Width 
addi $a1, $zero, 8 # Height
li $a3, 0x001EFF # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack

jal draw_rectangle # Draw required rectangle
addi $a0, $zero, 6 # Width 
addi $a1, $zero, 6 # Height
addi $a2, $a2, 0x104 # Go to next corner
li $a3, 0x00C7FF # Color
jal draw_rectangle # Draw required rectangle
addi $a0, $zero, 4 # Width 
addi $a1, $zero, 4 # Height
addi $a2, $a2, 0x104 # Go to next corner
li $a3, 0x00FFF5 # Color
jal draw_rectangle # Draw required rectangle
addi $a0, $zero, 2 # Width 
addi $a1, $zero, 2 # Height
addi $a2, $a2, 0x104 # Go to next corner
li $a3, 0xFFFFFF # Color
jal draw_rectangle # Draw required rectangle

lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state

j end_powerup_gen_time # Jump to end

end_powerup_gen_time:
jr $ra
############################################################

finish:
# Check if frog at finish point
lw $t9, frog # Load frog current position
addi $t8, $zero, 0x10008A00 # Load start of row to check for frog pointer

finish1:
finish_1_check_1:
bgeu $t9, 0x10008A20, finish_1_check_2 # Check Upper bound for finish 1
j finish2 # Jump to finish 2 checks

finish_1_check_2:
bltu $t9, 0x10008A40, finish_1_done # Upper bound satisfied for finish 1
j finish2 # Jump to finish 2 checks

finish_1_done:
addi $t0, $zero, 0x8D8D8D # Set $t0 to gray
sw $t0, color_finish1 # Set finish1 to gray
j finish_end # Jump to end

finish2:
finish_2_check_1:
bgeu $t9, 0x10008A60, finish_2_check_2 # Check Upper bound for finish 2
j finish3 # Jump to finish 3 checks

finish_2_check_2:
bltu $t9, 0x10008AA0, finish_2_done # Upper bound satisfied for finish 2
j finish3 # Jump to finish 3 checks

finish_2_done:
addi $t0, $zero, 0x8D8D8D # Set $t0 to gray
sw $t0, color_finish2 # Set finish2 to gray
j finish_end # Jump to end

finish3:
finish_3_check_1:
bgeu $t9, 0x10008AC0, finish_3_check_2 # Check Upper bound for finish 3
j finish_end_fail # Jump to end

finish_3_check_2:
bltu $t9, 0x10008AE0, finish_3_done # Upper bound satisfied for finish 3
j finish_end_fail # Jump to end

finish_3_done:
addi $t0, $zero, 0x8D8D8D # Set $t0 to gray
sw $t0, color_finish3 # Set finish1 to gray
j finish_end # Jump to end


finish_end:
li $v0, 31 # MIDI
li $a0, 60 # Tone
li $a1, 1000 # Duration
li $a2, 17 # Instrument
li $a3, 80 # Volume
syscall # Make the sound

lw $t1, frog_start # Load start position of frog
sw $t1, frog # Reset frogs current position to start

li $t0, 17 #Speed
sw $t0, speed # Reset speed

li $t0, 0 # Powerup status
sw $t0, powerup_time_status # Reset status

j process # Go to start of process
jr $ra # Return to caller

finish_end_fail:
jr $ra # Return to caller
############################################################

draw_finish:
# Draws finish zones
lw $a2, displayAddress # Load top left corner of screen
addi $a2, $a2, 0x820 # Go to start of next row of blocks + 1st block
addi $a0, $zero, 8 # Width 
addi $a1, $zero, 8 # Height
lw $a3, color_finish1 # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
addi $a2, $a2, 0x40 # 2 blocks right
lw $a3, color_finish2 # Color
jal draw_rectangle # Draw required rectangle
addi $a2, $a2, 0x20 # 1 blocks right
lw $a3, color_finish2 # Color
jal draw_rectangle # Draw required rectangle
addi $a2, $a2, 0x40 # 2 blocks right
lw $a3, color_finish3 # Color
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
jr $ra # Return to caller

############################################################

frog_on_log:
# Moves frog if on a log
lw $t8, frog # Loads current position of frog
lw $t7, frog # Loads current position of frog

upper:
fol_upper_1:
bltu $t8, 0x10009800, fol_upper_2 # Check 1 for upper row of logs
j lower # Jump to lower checks
fol_upper_2:
bgeu $t8, 0x10009000, fol_upper_update # Check 2 for upper row of logs
j lower # Jump to lower checks

fol_upper_update:
addi $t8, $t8, -4 # Move frog with log

addi $t6, $t8, 0 # Copy updated frog position
sll $t6, $t6, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t6, $t6, 28 # Shifts most significant digit to least significant digit
sll $t7, $t7, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t7, $t7, 28 # Shifts most significant digit to least significant digit
bne $t7, $t6, fol_out_of_bounds # If row is not the same, skip response


sw $t8, frog # Save updated frog position
jr $ra # Return to caller

lower:
fol_lower_1:
bltu $t8, 0x1000A000, fol_lower_2 # Check 1 for lower row of logs
j fol_end # Jump to end
fol_lower_2:
bgeu $t8, 0x10009800, fol_lower_update # Check 2 for lower row of logs
j fol_end # Jump to end

fol_lower_update:
addi $t8, $t8, -8 # Move frog with log

addi $t6, $t8, 0 # Copy updated frog position
sll $t6, $t6, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t6, $t6, 28 # Shifts most significant digit to least significant digit
sll $t7, $t7, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t7, $t7, 28 # Shifts most significant digit to least significant digit
bne $t7, $t6, fol_out_of_bounds # If row is not the same, skip response

sw $t8, frog # Save updated frog position
jr $ra # Return to caller

fol_out_of_bounds:
j colision_detected # Frog carried beyond scope
jr $ra # Return to caller 

fol_end:
jr $ra # Return to caller

############################################################
colision:
# Detects colision
add $t0, $zero, $zero # Initialize counter to 0
lw $t9, frog # Loads address of top left corner of frog
addi $t8, $t9, 0 # Copy $t9
lw $t7, color_river # Load color of river
lw $t6, color_car # Load color of car
lw $t4, color_finished # Load color of finished tile
start_colision_loop: # If no colisions detected
beq $t0, 4, end_colision_loop # Once 4 iterations have occured, jump to end
add $t1, $zero, $zero # Initialize counter to 0

start_colision_check: # Check for colisions in the row
beq $t1, 4, end_colision_check # Once 4 iterations have occured, jump to end
lw $t5, 0($t8) # Load color of pixel at $t8
beq $t5, $t7, colision_detected # Frog in river
beq $t5, $t6, colision_detected # Frog in car
beq $t5, $t4, colision_detected # Frog in finished tile
addi $t8, $t8, 4 # Set $t8 to address of next pixel to check
addi $t1, $t1, 1 # Increment inner counter
j start_colision_check # jump to start of loop

end_colision_check: # No colisions in the row
addi $t9, $t9, 0x100 # Shift to next row of pixels
addi $t8, $t9, 0 # Reset pixel pointer to start of new row
addi $t0, $t0, 1 # Increment outer counter
j start_colision_loop # Jump to start of loop

end_colision_loop: # If no colisions detected
jr $ra # Return to caller

colision_detected: # Frog colided with object
li $v0, 31 # MIDI
li $a0, 60 # Tone
li $a1, 1000 # Duration
li $a2, 81 # Instrument
li $a3, 64 # Volume
syscall # Make the sound

li $v0, 32 # Sleep
li $a0, 200 #200ms
syscall # Initiate sleep for 200ms

lw $a2, frog # Load top left corner frog
addi $a0, $zero, 4 # Width 
addi $a1, $zero, 4 # Height
li $a3, 0xFF0909 # Red
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle

li $v0, 32 # Sleep
li $a0, 200 # 100
syscall # Initiate sleep for 100ms

addi $a2, $a2, 0x104 # Go to next corner 
addi $a0, $zero, 2 # Width 
addi $a1, $zero, 2 # Height
li $a3, 0xFF7F00 # Orange
jal draw_rectangle # Draw required rectangle

li $v0, 32 # Sleep
li $a0, 200 # 100
syscall # Initiate sleep for 100ms

addi $a0, $zero, 2 # Width 
addi $a1, $zero, 2 # Height
li $a3, 0xFFFFFF # White
jal draw_rectangle # Draw required rectangle

lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state

lw $t9, frog_start # Load start position of frog
sw $t9, frog # Reset frogs current position to start
lw $t8, lives # Load number of remaining lives
subu $t8, $t8, 1 # Reduce lives by 1
sw $t8, lives # Save new number of lives

li $t0, 17 #Speed
sw $t0, speed # Reset speed

li $t0, 0 # Powerup status
sw $t0, powerup_time_status # Reset status

j process # Return to start of process
jr $ra # Return to caller

############################################################

draw_frog:
#Draws the frog
lw $a2, frog # Load top left corner frog
addi $a0, $zero, 4 # Width 
addi $a1, $zero, 4 # Height
lw $a3, color_frog # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state

lw $t3, frog_orientation # Loads frogs orientation in $t3

beq $t3, 0, orientation_up
beq $t3, 3, orientation_right
beq $t3, 6, orientation_down
beq $t3, 9, orientation_left

orientation_up:
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack

addi $a2, $a2, 0x0 # Left eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

addi $a2, $a2, 0xC # Right eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
j finish_frog

orientation_left:
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack

addi $a2, $a2, 0x0 # Right eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

addi $a2, $a2, 0x300 # Left eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
j finish_frog

orientation_right:
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack

addi $a2, $a2, 0xC # Left eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

addi $a2, $a2, 0x300 # Right eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
j finish_frog

orientation_down:
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack

addi $a2, $a2, 0x300 # Right eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

addi $a2, $a2, 0xC # Right eye
addi $a0, $zero, 1 # Width 
addi $a1, $zero, 1 # Height
lw $a3, color_frog_eye # Color
jal draw_rectangle # Draw required rectangle

lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
j finish_frog

finish_frog:
jr $ra # Return to caller

############################################################

move_frog:
#Moves frog according to keyboard input
lw $t0, 0xffff0000 # Check for keypress
beq $t0, 1, keyboard_input # If key is pressed
jr $ra # Return to caller

keyboard_input:
lw $t1, 0xffff0004 # Loads the ASCII value of keypress in $t1
lw $t8, frog_orientation # Loads frogs orientation

beq $t1, 0x77, respond_to_W # If keypress is w
beq $t1, 0x61, respond_to_A # If keypress is a
beq $t1, 0x73, respond_to_S # If keypress if s
beq $t1, 0x64, respond_to_D  # If keypress is d

jr $ra

respond_to_W:
li $v0, 31 # MIDI
li $a0, 60 # Tone
li $a1, 250 # Duration
li $a2, 33 # Instrument
li $a3, 64 # Volume
syscall # Make the sound

lw $t9, frog # Loads current frog position
subu $t9, $t9, 0x800 # Shifts frog position 1 block up
blt $t9, 0x10008000, skip_response # If shift is out of bounds
sw $t9, frog # Saves changed position to frog current position
addi $t8, $zero, 0 # Points frog north
sw $t8, frog_orientation # Updates orientation
jr $ra # Return to caller

respond_to_A:
li $v0, 31 # MIDI
li $a0, 60 # Tone
li $a1, 250 # Duration
li $a2, 33 # Instrument
li $a3, 64 # Volume
syscall # Make the sound

lw $t9, frog # Loads current frog position
addi $t7, $t9, 0 # Copy current frog position
subu $t9, $t9, 0x20 # Shifts frog position 1 block left
addi $t6, $t9, 0 # Copy updated frog position
sll $t7, $t7, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t7, $t7, 28 # Shifts most significant digit to least significant digit
sll $t6, $t6, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t6, $t6, 28 # Shifts most significant digit to least significant digit
bne $t7, $t6, skip_response # If row is not the same, skip response
sw $t9, frog # Saves changed position to frog current position
addi $t8, $zero, 9 # Points frog west
sw $t8, frog_orientation # Updates orientation
jr $ra # Return to caller

respond_to_S:
li $v0, 31 # MIDI
li $a0, 60 # Tone
li $a1, 250 # Duration
li $a2, 33 # Instrument
li $a3, 64 # Volume
syscall # Make the sound

lw $t9, frog # Loads current frog position
addu $t9, $t9, 0x800 # Shifts frog position 1 block down
bgeu $t9, 0x1000C000, skip_response # If shift is out of bounds
sw $t9, frog # Saves changed position to frog current position
addi $t8, $zero, 6 # Points frog south
sw $t8, frog_orientation # Updates orientation
jr $ra # Return to caller

respond_to_D:
li $v0, 31 # MIDI
li $a0, 60 # Tone
li $a1, 250 # Duration
li $a2, 33 # Instrument
li $a3, 64 # Volume
syscall # Make the sound

lw $t9, frog # Loads current frog position

addi $t7, $t9, 0 # Copy current frog position
addu $t9, $t9, 0x20 # Shifts frog position 1 block right
addi $t6, $t9, 0 # Copy updated frog position
sll $t7, $t7, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t7, $t7, 28 # Shifts most significant digit to least significant digit
sll $t6, $t6, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t6, $t6, 28 # Shifts most significant digit to least significant digit
bne $t7, $t6, skip_response # If row is not the same, skip response

addi $t7, $t9, 0 # Copy current frog position
addiu $t2, $t9, 0xC # Stores position of last block
addi $t6, $t2, 0 # Copy updated frog position
sll $t7, $t7, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t7, $t7, 28 # Shifts most significant digit to least significant digit
sll $t6, $t6, 20 # Shift shift 3rd hex digit to most signifigant digit
srl $t6, $t6, 28 # Shifts most significant digit to least significant digit
bne $t7, $t6, skip_response # If row is not the same, skip response

sw $t9, frog # Saves changed position to frog current position
addi $t8, $zero, 3 # Points frog east
sw $t8, frog_orientation # Updates orientation
jr $ra # Return to caller

skip_response:
jr $ra # Return to caller

############################################################

draw_cars:
#Draw cars on road
add $t5, $zero, $zero # Initialize counter $t5 to 0

lw $a0, size_car # Load size of car
addi $a1, $zero, 8 # Height
lw $a3, color_car # Color
la $t4, cars # Load address of first element of cars

start_car_loop:
beq $t5, 4, end_car_loop # After painting 4 cars and shifting position, jump to end
lw  $a2, 0($t4) # Set parameter $a2 to position of the car in current iteration
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $t0, $zero, 2 # Set $t0 to 2
addi $sp, $sp, 4 # Return stack to original state
addi $t4, $t4, 4 # Make $t4 point to address of next car
addi $t5, $t5, 1 # Increment counter
j start_car_loop # Jump back to start of loop

end_car_loop:
jr $ra # Return to caller

############################################################

move_cars:
addi $t0, $zero,0x1000A800 # Start of First row of cars
addi $t1, $zero,0x1000B000 # Start of Second row of cars
addi $t2, $zero,0x1000A900 # Start of row after First row
addi $t3, $zero,0x1000B100 # Start of row after Second row
la $t5, cars # Load address of first element of cars
add $t9, $zero, $zero # Set counter $t9 to 0

start_move_cars_loop:
beq $t9, 4, end_move_cars_loop
lw $t6, 0($t5) # Load address of current car pointer

top_row:
bgeu $t9, 2, car_bottom_row # If moving last 2 cars, jump to bottom row section
addi $t6, $t6, 4 # Shift car location 1 unit right
subu $t4, $t6, $t2 # How far away from next row the car is
bgez $t4, reset_car_position_top # If next position is beyond scope of row
sw $t6, 0($t5) # Store shifted position of car
addi $t5, $t5, 4 # Point to next car
addi $t9, $t9, 1 # Increment counter
j start_move_cars_loop # Jump to start of loop

reset_car_position_top:
add $t6, $t0, $t4 # Set car position to row overflow + address of original row
sw $t6, 0($t5) # Store shifted position of car
addi $t5, $t5, 4 # Point to next car
addi $t9, $t9, 1 # Increment counter
j start_move_cars_loop # Jump to start of loop

car_bottom_row:
addi $t6, $t6, 8 # Shift car location 2 units right
subu $t4, $t6, $t3 # How far away from next row the car is
bgez $t4, reset_car_position_bottom # If next position is beyond scope of row
sw $t6, 0($t5) # Store shifted position of car
addi $t5, $t5, 4 # Point to next car
addi $t9, $t9, 1 # Increment counter
j start_move_cars_loop # Jump to start of loop

reset_car_position_bottom:
add $t6, $t1, $t4 # Set car position to row overflow + address of original row
sw $t6, 0($t5) # Store shifted position of car
addi $t5, $t5, 4 # Point to next car
addi $t9, $t9, 1 # Increment counter
j start_move_cars_loop # Jump to start of loop

end_move_cars_loop:
jr $ra # Return to caller

############################################################

draw_logs:
#Draw logs on road
add $t5, $zero, $zero # Initialize counter $t5 to 0
lw $a0, size_log # Load size of log
addi $a1, $zero, 8 # Height
lw $a3, color_log # Color
la $t4, logs # Load address of first element of logs

start_log_loop:
beq $t5, 4, end_log_loop # After painting 4 cars and shifting position, jump to end
lw  $a2, 0($t4) # Set parameter $a2 to position of the log in current iteration
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $t0, $zero, 2 # Set $t0 to 2
addi $sp, $sp, 4 # Return stack to original state
addi $t4, $t4, 4 # Make $t4 point to address of next car
addi $t5, $t5, 1 # Increment counter
j start_log_loop # Jump back to start of loop

end_log_loop:
jr $ra # Return to caller

############################################################

move_logs:
addi $t0, $zero,0x100090FC # End of First row of logs
addi $t1, $zero,0x100098FC # End of Second row of logs
addi $t2, $zero,0x10008FFC # End of row before First row
addi $t3, $zero,0x100097FC # End of row before Second row
la $t5, logs # Load address of first element of logs
add $t9, $zero, $zero # Set counter $t9 to 0

start_move_logs_loop:
beq $t9, 4, end_move_logs_loop
lw $t6, 0($t5) # Load address of current log pointer

log_top_row:
bgeu $t9, 2, log_bottom_row # If moving last 2 logs, jump to bottom row section
addi $t6, $t6, -4 # Shift log location 1 unit left
subu $t4, $t2, $t6 # How far away from prev row the log is
bgez $t4, reset_log_position_top # If next position is beyond scope of row
sw $t6, 0($t5) # Store shifted position of log
addi $t5, $t5, 4 # Point to next log
addi $t9, $t9, 1 # Increment counter
j start_move_logs_loop # Jump to start of loop

reset_log_position_top:
subu $t6, $t0, $t4 # Set log position to row overflow + address of original row
sw $t6, 0($t5) # Store shifted position of log
addi $t5, $t5, 4 # Point to next log
addi $t9, $t9, 1 # Increment counter
j start_move_logs_loop # Jump to start of loop

log_bottom_row:
addi $t6, $t6, -8 # Shift log location 2 units left
subu $t4, $t3, $t6 # How far away from prev row the log is
bgez $t4, reset_log_position_bottom # If next position is beyond scope of row
sw $t6, 0($t5) # Store shifted position of log
addi $t5, $t5, 4 # Point to next log
addi $t9, $t9, 1 # Increment counter
j start_move_logs_loop # Jump to start of loop

reset_log_position_bottom:
subu $t6, $t1, $t4 # Set log position to row overflow + address of original row
sw $t6, 0($t5) # Store shifted position of log
addi $t5, $t5, 4 # Point to next log
addi $t9, $t9, 1 # Increment counter
j start_move_logs_loop # Jump to start of loop

end_move_logs_loop:
jr $ra # Return to caller

############################################################

draw_end:
#Draw the starting tiles
lw $a2, displayAddress # Load top left corner of screen
addi $a0, $zero, 64 # Width 
addi $a1, $zero, 16 # Height
lw $a3, color_safe # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
jr $ra # Return to caller

############################################################

draw_start:
#Draw the starting tiles
lw $a2, displayAddress # Load top left corner of screen
addi $a2, $a2, 14336 # Store memory address of starting corner
addi $a0, $zero, 64 # Width 
addi $a1, $zero, 8 # Height
lw $a3, color_safe # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
jr $ra # Return to caller

############################################################

draw_road:
#Draw the starting tiles
lw $a2, displayAddress # Load top left corner of screen
addi $a2, $a2, 10240 # Store memory address of starting corner
addi $a0, $zero, 64 # Width 
addi $a1, $zero, 16 # Height
lw $a3, color_road # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
jr $ra # Return to caller

############################################################

draw_middle:
#Draw the starting tiles
lw $a2, displayAddress # Load top left corner of screen
addi $a2, $a2, 8192 # Store memory address of starting corner
addi $a0, $zero, 64 # Width 
addi $a1, $zero, 8 # Height
lw $a3, color_safe # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
jr $ra # Return to caller

############################################################

draw_river:
#Draw the starting tiles
lw $a2, displayAddress # Load top left corner of screen
addi $a2, $a2, 4096 # Store memory address of starting corner
addi $a0, $zero, 64 # Width 
addi $a1, $zero, 16 # Height
lw $a3, color_river # Color
addi $sp, $sp, -4 # Prime the stack pointer
sw $ra, 0($sp) # Store old return address on stack
jal draw_rectangle # Draw required rectangle
lw $ra, 0($sp) # Load original return address from stack
addi $sp, $sp, 4 # Return stack to original state
jr $ra # Return to caller

############################################################

draw_rectangle:
# Draw a rectangle with dimensions $a0 (width) x $a1 (height) and colour ($a3) starting top left at address $a2
add $t9, $a2, $zero # Copy of origin address
add $t8, $a2, $zero # Copy of origin address
add $t6, $zero, $zero # Set index $t6 to 0

start_rect_loop: 
beq $t6, $a1, end_rect_loop # If $t6 == height, jump to end
add $t7, $zero, $zero # Set index $t7 to 0

start_line_loop:
beq $t7, $a0, end_line_loop # If $t7 == width, jump to end
sw $a3, 0($t9) # Fill pixel at $t9 with color $a3
addi $t9, $t9, 4 # Set $t9 to point to pixel to its right
addi $t7, $t7, 1 # Increment index $t7

lw $t0, displayAddress # Copy origin to $t0
subu $t0, $t9, $t0 # Calculate deviation of $t9 from origin
addi $t1, $zero, 256  # Initialize $t1 to 256
divu $t0, $t1 # Divide $t0 by 256
mfhi $t2 # Set $t2 to remainder of $t0 / 256
start_wrap_check: # Check to see if line overflows to next row
bgtz $t2, end_wrap_check # If no overflow, ignore line below
addi $t9, $t9, -256 # If overflow, reset $t9 to start of row above current
end_wrap_check: # End of wrap check

j start_line_loop

end_line_loop:
addi $t6, $t6, 1 # Increment index $t6
addi $t9, $t8, 256 # Store address of start of next row in $t9
addi $t8, $t8, 256 # Set $t8 to point to start of next row
j start_rect_loop

end_rect_loop:
jr $ra # Return to caller

############################################################

Exit:
li $v0, 10 # terminate the program gracefully
syscall


