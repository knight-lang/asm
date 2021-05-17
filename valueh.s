.equ KN_TAG_CONSTANT, 0
.equ KN_TAG_VARIABLE, 1
.equ KN_TAG_NUMBER, 2
.equ KN_TAG_STRING, 3
.equ KN_TAG_AST, 4

.equ KN_SHIFT, 3
.equ KN_MASK, 7

.equ KN_FALSE, 0
.equ KN_NULL, 8
.equ KN_TRUE, 16
.equ KN_UNDEFINED, 24

.macro KN_NEW_NUMBER src:req dst=_none
	.ifc \dst, _none
		lea KN_TAG_NUMBER(,\src,8), \src
	.else
		lea KN_TAG_NUMBER(,\src,8), \dst
	.endif
.endm

.macro KN_NEW_STRING src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		or $KN_TAG_STRING, \src
	.else
		lea KN_TAG_STRING(\src), \dst
	.endif
.endm

.macro KN_NEW_VARIABLE src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		inc \src
	.else
		lea KN_TAG_VARIABLE(\src), \dst
	.endif
.endm

.macro KN_NEW_AST src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		add $KN_TAG_AST, \src
	.else
		lea KN_TAG_AST(\src), \dst
	.endif
.endm

.macro VALUE_AS_NUMBER src:req
	sar \src, $KN_SHIFT
.endm

.macro VALUE_AS_STRING src:req
	dec \src
.endm