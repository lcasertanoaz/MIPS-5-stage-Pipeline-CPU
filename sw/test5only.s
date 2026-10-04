############################################################
# Test 5 only - Combined .data + .text for mips_helper
# Layout in data memory (word-addressed, base 0):
#   asize5  @ 0      (4 words, 16 bytes)
#   frame5  @ 16     (32*32 = 1024 words, 4096 bytes)
#   window5 @ 4112   (16 words, 64 bytes)
#
# Expected result for test 5:
#   $v0 = 17
#   $v1 = 16
############################################################

.data

# test 5 For the 32x32 frame and a 4x4 window size
# The result should be 17,16 since the updated SAD condition is SAD <= currentMinimum

asize5: 
    .word 32, 32, 4, 4     # i, j, k, l

frame5: 
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

window5:
    .word 10, 10, 10, 10
    .word 10, 10, 10, 10
    .word 10, 10, 10, 10
    .word 10, 10, 10, 10


############################################################
# TEXT SECTION
############################################################

.text
.globl main

main:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    # --- Test 5 only ---
    # asize5  @ 0
    # frame5  @ 16
    # window5 @ 4112
    addi    $a0, $zero, 0        # &asize5[0]
    addi    $a1, $zero, 16       # &frame5[0]
    addi    $a2, $zero, 4112     # &window5[0]

    jal     vbsme                # run VBSME once on test 5

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4

end_program:
    j       end_program          # infinite loop after finishing


############################################################
# vbsme implementation
############################################################

.globl  vbsme

vbsme:
    # Clear result registers
    addi      $v0, $zero, 0
    addi      $v1, $zero, 0

    # Set up stack frame (80 bytes)
    addi    $sp, $sp, -80
    sw      $ra, 0($sp)

    # Save frame & window base addresses
    sw      $a1, 20($sp)       # frame_base
    sw      $a2, 24($sp)       # window_base

    # Load dimensions from asize (a0)
    lw      $t0, 0($a0)        # i (frame rows)
    lw      $t1, 4($a0)        # j (frame cols)
    lw      $t2, 8($a0)        # k (window rows)
    lw      $t3,12($a0)        # l (window cols)

    # Save dimensions on stack
    sw      $t0,   4($sp)      # i
    sw      $t1,   8($sp)      # j
    sw      $t2,  12($sp)      # k
    sw      $t3,  16($sp)      # l

    # Initialize best_sad = large number (0x7fffffff), best_row, best_col = 0
    lui     $t4, 0x7fff
    ori     $t4, $t4, 0xffff
    sw      $t4, 44($sp)       # best_sad
    sw      $zero, 48($sp)     # best_row
    sw      $zero, 52($sp)     # best_col

    # H = i - k + 1
    sub     $t5, $t0, $t2
    addi    $t5, $t5, 1
    sw      $t5, 28($sp)       # H

    # W = j - l + 1
    sub     $t6, $t1, $t3
    addi    $t6, $t6, 1
    sw      $t6, 32($sp)       # W

    # s = 0; sMax = H + W - 2
    sw      $zero, 36($sp)     # s
    add     $t8, $t5, $t6
    addi    $t8, $t8, -2
    sw      $t8, 40($sp)       # sMax

ZZ_OUTER_S:
    lw      $t6, 36($sp)       # s
    lw      $t7, 40($sp)       # sMax

    # if (s > sMax) break
    slt     $t9, $t7, $t6      # t9=1 if sMax < s
    bne     $t9, $zero, ZZ_DONE

    lw      $t5, 28($sp)       # H
    lw      $t4, 32($sp)       # W

    # r_min = max(0, s - (W-1))
    addi    $t9, $t4, -1       # W - 1
    sub     $t2, $t6, $t9      # s - (W-1)
    slt     $t9, $t2, $zero
    beq     $t9, $zero, ZZ_RMIN_OK
    add     $t2, $zero, $zero  # r_min = 0 if negative

ZZ_RMIN_OK:
    # r_max = min(s, H-1)
    addi    $t9, $t5, -1       # H - 1
    add     $t3, $t6, $zero    # s
    slt     $t8, $t9, $t3      # (H-1) < s ?
    beq     $t8, $zero, ZZ_RMAX_OK
    add     $t3, $t9, $zero    # r_max = H-1

ZZ_RMAX_OK:
    sw      $t2, 72($sp)       # r_min
    sw      $t3, 76($sp)       # r_max

    # Even s: walk r = r_max..r_min (up-right)
    # Odd  s: walk r = r_min..r_max (down-left)
    andi    $t8, $t6, 1
    bne     $t8, $zero, ZZ_ODD

    # EVEN diagonal
    lw      $t8, 76($sp)       # r = r_max

ZZ_EVEN_LOOP:
    lw      $t2, 72($sp)       # r_min

    # if (r < r_min) go to next diagonal
    slt     $t9, $t8, $t2
    bne     $t9, $zero, ZZ_AFTER_DIAG

    lw      $t6, 36($sp)       # s
    sub     $t9, $t6, $t8      # c = s - r

    sw      $t6, 36($sp)       # s
    sw      $t8, 56($sp)       # curr_r
    sw      $t9, 60($sp)       # curr_c

    jal FIND_ADDRESS
    jal CALC_SAD
    jal UPDATE_MIN

    lw      $t8, 56($sp)       # r
    addi    $t8, $t8, -1       # r--
    j       ZZ_EVEN_LOOP

ZZ_ODD:
    # ODD diagonal
    lw      $t8, 72($sp)       # r = r_min

ZZ_ODD_LOOP:
    lw      $t3, 76($sp)       # r_max

    # if (r > r_max) go to next diagonal
    slt     $t9, $t3, $t8      # r_max < r ?
    bne     $t9, $zero, ZZ_AFTER_DIAG

    lw      $t6, 36($sp)       # s
    sub     $t9, $t6, $t8      # c = s - r

    sw      $t6, 36($sp)
    sw      $t8, 56($sp)       # curr_r
    sw      $t9, 60($sp)       # curr_c

    jal FIND_ADDRESS
    jal CALC_SAD
    jal UPDATE_MIN

    lw      $t8, 56($sp)       # r
    addi    $t8, $t8, 1        # r++
    j       ZZ_ODD_LOOP

ZZ_AFTER_DIAG:
    lw      $t6, 36($sp)       # s
    addi    $t6, $t6, 1        # s++
    sw      $t6, 36($sp)
    j       ZZ_OUTER_S

ZZ_DONE:
    # Return best (row, col) in v0, v1
    lw      $v0, 48($sp)
    lw      $v1, 52($sp)

    lw      $ra, 0($sp)
    addi    $sp, $sp, 80
    jr      $ra


############################################################
# Helper subroutines: FIND_ADDRESS, CALC_SAD, UPDATE_MIN
############################################################

FIND_ADDRESS:
    # frame_base, j, r, c
    lw   $t2, 20($sp)          # frame_base
    lw   $t1,  8($sp)          # j (frame cols)
    lw   $t8, 56($sp)          # r
    lw   $t9, 60($sp)          # c

    mul  $t0, $t8, $t1         # r * j
    add  $t0, $t0, $t9         # r*j + c
    sll  $t0, $t0, 2           # *4 bytes
    add  $t0, $t2, $t0         # &frame[r][c]

    sw   $t0, 64($sp)          # curr_addr
    jr   $ra


UPDATE_MIN:
    lw   $t0, 44($sp)          # best_sad
    lw   $t1, 68($sp)          # curr_sad

    # if (best_sad < curr_sad) -> skip (we want curr <= best to update)
    slt  $t2, $t0, $t1
    bne  $t2, $zero, UPDATE_DONE

    # Update best_sad, best_row, best_col
    sw   $t1, 44($sp)
    lw   $t3, 56($sp)          # r
    sw   $t3, 48($sp)
    lw   $t4, 60($sp)          # c
    sw   $t4, 52($sp)

    add  $v0, $t3, $zero
    add  $v1, $t4, $zero

UPDATE_DONE:
    jr   $ra


CALC_SAD:
    lw   $t0, 64($sp)          # frame_block_base (&frame[r][c])
    lw   $t5, 24($sp)          # window_base
    lw   $t4,  8($sp)          # j (frame cols)
    lw   $t9, 12($sp)          # k (window rows)
    lw   $t3, 16($sp)          # l (window cols)

    addi $t1, $zero, 0         # sum = 0
    addi $t6, $zero, 0         # i = 0

row_loop:
    slt  $t2, $t6, $t9         # i < k ?
    beq  $t2, $zero, done

    # frame row base: frame_block_base + i*j*4
    lw   $t4,  8($sp)          # j
    mul  $t7, $t6, $t4         # i * j
    sll  $t7, $t7, 2           # *4
    add  $t2, $t0, $t7         # frame_row_ptr

    # window row base: window_base + i*l*4
    mul  $t7, $t6, $t3         # i * l
    sll  $t7, $t7, 2           # *4
    lw   $t8, 24($sp)          # window_base
    add  $t5, $t8, $t7         # win_row_ptr

    addi $t8, $zero, 0         # col = 0

col_loop:
    slt  $t7, $t8, $t3         # col < l ?
    beq  $t7, $zero, next_row

    lw   $t7, 0($t2)           # frame[i][col]
    lw   $t4, 0($t5)           # window[i][col]

    sub  $t7, $t7, $t4         # diff
    bltz $t7, make_positive
    j    add_diff

make_positive:
    sub  $t7, $zero, $t7       # diff = -diff

add_diff:
    add  $t1, $t1, $t7         # sum += |diff|

    addi $t2, $t2, 4           # frame_ptr++
    addi $t5, $t5, 4           # win_ptr++
    addi $t8, $t8, 1           # col++
    j    col_loop

next_row:
    addi $t6, $t6, 1           # i++
    j    row_loop

done:
    sw   $t1, 68($sp)          # curr_sad
    jr   $ra
