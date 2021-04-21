.equ TAG_CONSTANT, 0
.equ TAG_STRING, 1
.equ TAG_VARIABLE, 2
.equ TAG_NUMBER, 3
.equ TAG_AST, 4

.equ FALSE, 0
.equ NULL, 8
.equ TRUE, 16

.macro NEW_NUMBER src:req dst=_none
	.ifc \dst, _none
		lea TAG_NUMBER(,\src,8), \src
	.else
		lea TAG_NUMBER(,\src,8), \dst
	.endif
.endm

.macro NEW_STRING src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		inc \src
	.else
		lea TAG_STRING(\src), \dst
	.endif
.endm

.macro NEW_VARIABLE src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		add $TAG_VARIABLE, \src
	.else
		lea TAG_VARIABLE(\src), \dst
	.endif
.endm

.macro NEW_AST src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		add $TAG_AST, \src
	.else
		lea TAG_AST(\src), \dst
	.endif
.endm

.macro VALUE_AS_NUMBER src:req
	sar \src, 3
.endm

.macro VALUE_AS_STRING src:req
	dec \src
.endm