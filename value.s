.include "valueh.s"

.globl value_run
value_run:
	mov %rdi, %r15
	sub $8, %rsp
	call debug
	xor %edi, %edi
	call _exit


.globl value_free
value_free:
	jmp ddebug