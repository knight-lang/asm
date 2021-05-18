.include "debugh.s"
.include "valueh.s"

.globl kn_function_startup
kn_function_startup:
	# todo
	ret

.macro define_fn name:req, arity:req
	.align 8
	.zero 7
	.byte \arity
	.globl kn_func_\name
	kn_func_\name:
.endm

/* ARITY ZERO */

define_fn prompt, 0
	sub $8, %rsp
	diem "todo: function_prompt"

define_fn random, 0
	sub $8, %rsp
	diem "todo: function_random"

/* ARITY ONE */

define_fn eval, 1
	sub $8, %rsp
	diem "todo: function_eval"

define_fn block, 1
	sub $8, %rsp
	diem "todo: function_block"

define_fn call, 1
	sub $8, %rsp
	diem "todo: function_call"

define_fn system, 1
	sub $8, %rsp
	diem "todo: function_system"

define_fn quit, 1
	sub $8, %rsp
	diem "todo: function_quit"

define_fn not, 1
	sub $8, %rsp
	# load the value to convert
	mov (%rdi), %rdi
	call kn_value_to_boolean
	add $8, %rsp
	.ifndef NDEBUG
		mov %al, %cl
		xor %al, %al
		test %rax, %rax
		jz 0f
		diem "`kn_value_to_boolean` returned a non-single-byte value"
	0:
		mov %cl, %al
	.endif

	# bit twiddle the return value.
	test %al, %al
	setz %al
	shl $4, %al
	ret

define_fn length, 1
	sub $8, %rsp
	diem "todo: function_length"

define_fn output, 1
	sub $8, %rsp
	diem "todo: function_output"

define_fn debug, 1
	sub $8, %rsp
	diem "todo: function_debug"


/* ARITY TWO */

define_fn add, 2
	sub $8, %rsp
	diem "todo: function_add"

define_fn sub, 2
	sub $8, %rsp
	diem "todo: function_sub"

define_fn mul, 2
	sub $8, %rsp
	diem "todo: function_mul"

define_fn div, 2
	sub $8, %rsp
	diem "todo: function_div"

define_fn mod, 2
	sub $8, %rsp
	diem "todo: function_mod"

define_fn pow, 2
	sub $8, %rsp
	diem "todo: function_pow"

define_fn lth, 2
	sub $8, %rsp
	diem "todo: function_lth"

define_fn gth, 2
	sub $8, %rsp
	diem "todo: function_gth"

define_fn eql, 2
	sub $8, %rsp
	diem "todo: function_gth"

define_fn and, 2
	sub $8, %rsp
	diem "todo: function_and"

define_fn or, 2
	sub $8, %rsp
	diem "todo: function_or"

define_fn then, 2
	sub $8, %rsp
	diem "todo: function_then"

define_fn assign, 2
	sub $8, %rsp
	diem "todo: function_assign"

define_fn while, 2
	sub $8, %rsp
	diem "todo: function_while"


/* ARITY THREE */

define_fn get, 3
	sub $8, %rsp
	diem "todo: function_get"


define_fn if, 3
	sub $8, %rsp
	diem "todo: function_if"

/* ARITY FOUR */

define_fn set, 4
	sub $8, %rsp
	diem "todo: function_set"
