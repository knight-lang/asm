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
	diem "xmalloc failure"

.globl xrealloc
xrealloc:
	sub $8, %rsp
	call _realloc
	add $8, %rsp
	test %rax, %rax
	je 0f
	ret
0:
	diem "xrealloc failure"

.globl kn_hash
kn_hash:
	movq $525201411107845655, %rdx
	# fallthru
.globl kn_hash_acc
kn_hash_acc:
        jmp hash_it
