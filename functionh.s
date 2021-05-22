.equ KN_FN_MAXARGC, 4
.equ KN_FN_OFF_ARITY, -1

.macro KN_FN_ARITY src:req dst=_none
	.ifc \dst, _none
		KN_FN_ARITY \src, \src
		.exitm
	.endif

	movzb KN_FN_OFF_ARITY(\src), \dst
.endm
