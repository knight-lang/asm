.macro _fix_stack
	test $$8, %rsp
	jz 0f
	add $$8, %rsp
0:
.endm

.macro unreachable
	.ifndef NDEBUG
		_fix_stack
		call _abort
	.endif
.endm