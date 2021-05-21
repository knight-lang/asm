# The ordering is chosen very carefully:
# - is the tag is <= 2, we don't need to free it
# - if the tag is <= 1, we can return it when running it.
# - if the tag has `0b100` set, we can know the tag is unique.
# - if the tag has `0b010` set, and the value's not a variable, it's a string.
.equ KN_TAG_CONSTANT,  0b000 # NUMBER OR CONSTANT.
.equ KN_TAG_NUMBER,    0b001
.equ KN_TAG_VARIABLE,  0b010
.equ KN_TAG_STRING,    0b011
.equ KN_TAG_AST,       0b100

.equ KN_SHIFT, 3
.equ KN_MASK, 7

.equ KN_FALSE,     0b00000
.equ KN_NULL,      0b01000
.equ KN_TRUE,      0b10000
.equ KN_UNDEFINED, 0b11000

.equ KN_VALUE_SIZE, 8

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
		add $KN_TAG_STRING, \src
	.else
		lea KN_TAG_STRING(\src), \dst
	.endif
.endm

.macro KN_NEW_VARIABLE src:req dst=_none
	# TODO: ensure that `src` is lower 8 bits
	.ifc \dst, _none
		add $2, \src
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

.macro run_ast ast:req, func:req, scratch=%r8
	mov KN_AST_OFF_FN(\ast), \scratch
	lea KN_AST_OFF_ARGS(\ast), %rdi
	\func *\scratch
.endm

.macro run_var var:req, dst=_none, scratch=%r8
	.ifc \dst, _none
		run_var \var, \var
		.exitm
	.endif

	movq KN_VAR_OFF_VAL(\var), \dst

	.ifndef KN_RECKLESS
		cmp $KN_UNDEFINED, \dst
		jne run_var_check_result_\@
		diem "undefined variable accessed"
	run_var_check_result_\@:
	.endif

	mov \dst, \scratch
	and $0b111, \scratch
	cmp $3, \scratch
	jb .run_var_no_incr_\@
	mov \dst ,\scratch
	and $~0b111, \scratch
	incl (\scratch)
.run_var_no_incr_\@:

.endm

