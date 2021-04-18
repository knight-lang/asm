.equ KN_TAG_CONSTANT, 0
.equ KN_TAG_STRING, 1
.equ KN_TAG_VARIABLE, 2
.equ KN_TAG_NUMBER, 3
.equ KN_TAG_AST, 4

.macro KN_NEW_NUMBER src:req dst=_none
	.ifc \dst, _none
		lea KN_TAG_NUMBER(,\src,8), \src
	.else
		lea KN_TAG_NUMBER(,\src,8), \dst
	.endm
.endm

.macro KN_NEW_STRING src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		inc \src
	.else
		lea KN_TAG_STRING(\src), \dst
	.endm
.endm

.macro KN_NEW_VARIABLE src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		add $KN_TAG_VARIABLE, \src
	.else
		lea KN_TAG_VARIABLE(\src), \dst
	.endm
.endm

.macro KN_NEW_AST src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		add $KN_TAG_AST, \src
	.else
		lea KN_TAG_AST(\src), \dst
	.endm
.endm

.macro KN_AS_NUMBER src:req
	sar \src, 3
.endm
