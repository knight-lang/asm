.macro diem msg:req
	test $8, %rax
	je kn_diem_nooffset_\@
	sub $8, %rsp
kn_diem_nooffset_\@:
	lea kn_die_message\@(%rip), %rdi
	call _puts
	mov $1, %edi
	call _exit
.pushsection .data, ""
kn_die_message\@:
	.asciz "\msg"
.popsection
.endm

.macro unreachable
	.ifndef NDEBUG
		_fix_stack
		call _abort
	.endif
.endm
