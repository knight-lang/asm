.equ KN_STR_OFF_RC, 0
.equ KN_STR_OFF_LEN, 4
.equ KN_STR_OFF_PTR, 8


.macro STRING_PTR src:req, dst=_none
	.ifc \dst, _none
		movq KN_STR_OFF_PTR(\src), \src
	.else
		movq KN_STR_OFF_PTR(\src), \dst
	.endif
.endm

.macro STRING_LEN src:req, dst=\src
	movl KN_STR_OFF_LEN(\src), \dst
.endm
