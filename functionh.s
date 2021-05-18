.macro KN_FN_ARITY src:req dst=_none
	.ifc dst, _none
		movzb -1(\src), \src
	.else
		movzb -1(\src), \dst
	.endif
.endm
