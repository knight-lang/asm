.include "debugh.s"
.include "valueh.s"
.include "envh.s"

.globl kn_env_startup
kn_env_startup:
	# todo
	ret

.globl kn_env_fetch
kn_env_fetch:
	# todo
	lea var(%rip), %rax
	movq $-1 ^ 0b0110, KN_VAR_OFF_VAL(%rax)
	movq %rdi, KN_VAR_OFF_NAME(%rax)
	or $2, %al
	ret

.bss
.align 16
var:
	.quad 0
	.quad 0