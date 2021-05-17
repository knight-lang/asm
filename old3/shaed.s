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
