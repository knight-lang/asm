.include "valueh.s"

.globl kn_value_run
kn_value_run:
	mov %rdi, %r15
	sub $8, %rsp
	call debug
	xor %edi, %edi
	call _exit


.globl kn_value_free
kn_value_free:
	jmp ddebug