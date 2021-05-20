.globl abort
abort:
	sub $8, %rsp
	call _printf
	add $8, %rsp
	# fallthrough

.globl die
die:
	mov $1, %rdi
	jmp _exit

.globl xmalloc
xmalloc:
	sub $8, %rsp
	call _malloc
	add $8, %rsp
	test %rax, %rax
	je 0f
	ret
0:
	mov $2, %rdi
	jmp die


.globl xrealloc
xrealloc:
	sub $8, %rsp
	call _realloc
	add $8, %rsp
	test %rax, %rax
	je 0f
	ret
0:
	mov $2, %rdi
	jmp die

.globl kn_hash
kn_hash:
	movq $525201411107845655, %rdx
	# fallthru
/* unsigned long kn_hash_acc(const char *str, size_t length, unsigned long hash) */
.globl kn_hash_acc
kn_hash_acc:
# shamelessly copied from clang
        movq    %rdx, %rax
        testq   %rsi, %rsi
        je      .LBB0_8
        movabsq $6616326155283851669, %r9       # imm = 0x5BD1E9955BD1E995
        leaq    -1(%rsi), %r8
        movq    %rsi, %r10
        andq    $3, %r10
        je      .LBB0_5
        xorl    %edx, %edx
.LBB0_3:
        movsbq  (%rdi,%rdx), %rcx
        xorq    %rax, %rcx
        imulq   %r9, %rcx
        movq    %rcx, %rax
        shrq    $47, %rax
        xorq    %rcx, %rax
        addq    $1, %rdx
        cmpq    %rdx, %r10
        jne     .LBB0_3
        subq    %rdx, %rsi
        addq    %rdx, %rdi
.LBB0_5:
        cmpq    $3, %r8
        jb      .LBB0_8
        xorl    %r8d, %r8d
.LBB0_7:
        movsbq  (%rdi,%r8), %rcx
        xorq    %rax, %rcx
        imulq   %r9, %rcx
        movsbq  1(%rdi,%r8), %rax
        xorq    %rcx, %rax
        shrq    $47, %rcx
        xorq    %rcx, %rax
        imulq   %r9, %rax
        movsbq  2(%rdi,%r8), %rcx
        xorq    %rax, %rcx
        shrq    $47, %rax
        xorq    %rax, %rcx
        imulq   %r9, %rcx
        movsbq  3(%rdi,%r8), %rdx
        xorq    %rcx, %rdx
        shrq    $47, %rcx
        xorq    %rcx, %rdx
        imulq   %r9, %rdx
        movq    %rdx, %rax
        shrq    $47, %rax
        xorq    %rdx, %rax
        addq    $4, %r8
        cmpq    %r8, %rsi
        jne     .LBB0_7
.LBB0_8:
        retq