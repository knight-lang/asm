.equ KN_STR_OFF_RC, 0
.equ KN_STR_OFF_LEN, 4
.equ KN_STR_OFF_PTR, 8
.equ KN_STR_SIZE, 16


.macro STRING_PTR src:req, dst=_none
	.ifc \dst, _none
		STRING_PTR \src, \src
		.exitm
	.endif

	movq KN_STR_OFF_PTR(\src), \dst
.endm

.macro STRING_LEN src:req, dst=_none
	.ifc \dst, _none
		STRING_LEN \src, \src
		.exitm
	.endif

	movl KN_STR_OFF_LEN(\src), \dst
.endm

.macro STRING_FREE src:req
	decl (\src)
	jne kn_string_free_\@
	.ifnc \src, %rdi
		mov \src, %rdi
	.endif
	call kn_string_free
kn_string_free_\@:
.endm
