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
