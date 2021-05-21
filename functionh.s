.macro KN_FN_ARITY src:req dst=_none
	.ifc \dst, _none
		KN_FN_ARITY \src, \src
		.exitm
	.endif

	movzb -1(\src), \dst
.endm
