.include "debugh.s"
.include "envh.s"
.include "stringh.s"
.include "valueh.s"

.globl kn_function_startup
kn_function_startup:
	# todo
	ret

.macro define_fn name:req, arity:req, chr:req
	.align 8
	.zero 6
	.byte \chr
	.byte \arity
	.globl kn_func_\name
	kn_func_\name:
.endm

/* ARITY ZERO */

define_fn prompt, 0, 'P'
	sub $8, %rsp
	diem "todo: function_prompt"

define_fn random, 0, 'R'
	sub $8, %rsp
	diem "todo: function_random"

/* ARITY ONE */

define_fn eval, 1, 'E'
	sub $8, %rsp
	diem "todo: function_eval"

define_fn block, 1, 'B'
	sub $8, %rsp
	diem "todo: function_block"

define_fn call, 1, 'C'
	sub $8, %rsp
	diem "todo: function_call"

define_fn system, 1, '`'
	sub $8, %rsp
	diem "todo: function_system"

define_fn quit, 1, 'Q'
	sub $8, %rsp
	diem "todo: function_quit"

define_fn not, 1, '!'
	# load the value to convert
	mov (%rdi), %rdi
	sub $8, %rsp
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

define_fn length, 1, 'L'
	sub $8, %rsp
	diem "todo: function_length"

define_fn output, 1, 'O'
	push %rbx
	mov (%rdi), %rdi
	call kn_value_to_string
	mov %rax, %rdi
	mov %rax, %rbx
	STRING_PTR %rdi
	# TODO: check for trailing slash```
	call _puts
	mov %rbx, %rdi
	STRING_FREE %rdi
	mov $KN_NULL, %eax
	pop %rbx
	ret

define_fn dump, 1, 'D'
	push %rbx
	mov (%rdi), %rdi
	call kn_value_run
	mov %rax, %rdi
	mov %rax, %rbx
	call kn_value_dump
	mov $'\n', %dil
	call _putchar
	mov %rbx, %rax
	pop %rbx
	ret

/* ARITY TWO */

define_fn add, 2, '+'
	push %rbx
	mov (%rdi), %rdi
	call kn_value_to_number
	mov %rax, %rdi
	shl $3, %rdi
	or $1, %rdi
	call kn_value_dump
	pop %rbx
	ret
	sub $8, %rsp
	diem "todo: function_add"

define_fn sub, 2, '-'
	sub $8, %rsp
	diem "todo: function_sub"

define_fn mul, 2, '*'
	sub $8, %rsp
	diem "todo: function_mul"

define_fn div, 2, '/'
	sub $8, %rsp
	diem "todo: function_div"

define_fn mod, 2, '%'
	sub $8, %rsp
	diem "todo: function_mod"

define_fn pow, 2, '^'
	sub $8, %rsp
	diem "todo: function_pow"

define_fn lth, 2, '<'
	sub $8, %rsp
	diem "todo: function_lth"

define_fn gth, 2, '>'
	sub $8, %rsp
	diem "todo: function_gth"

define_fn eql, 2, '?'
	sub $8, %rsp
	diem "todo: function_gth"

define_fn and, 2, '&'
	sub $8, %rsp
	diem "todo: function_and"

define_fn or, 2, '|'
	sub $8, %rsp
	diem "todo: function_or"

define_fn then, 2, ';'
	push %rdi
	mov (%rdi), %rdi
	call kn_value_run
	mov %rax, %rdi
	call kn_value_free
	pop %rdi
	mov 8(%rdi), %rdi
	jmp kn_value_run

define_fn assign, 2, '='
	.ifndef KN_RECKLESS
		movq (%rdi), %rax
		and $0b111, %al
		cmp $KN_TAG_VARIABLE, %al
		je 1f
		diem "can only assign to variables"
	1:
	.endif

	# Store the variable
	mov (%rdi), %rcx
	push %rcx

	# Execute the rhs
	mov 8(%rdi), %rdi
	call kn_value_run

	# Store the new result, preserving the old one so we can free it.
	mov (%rsp), %rcx
	and $~0b111, %cl # delete its tag
	mov KN_VAR_OFF_VAL(%rcx), %rdi
	mov %rax, KN_VAR_OFF_VAL(%rcx)
	mov %rax, (%rsp)

	# Free the old result
	call kn_value_free

	# Clone the new result
	pop %rdi
	jmp kn_value_clone

define_fn while, 2, 'W'
	sub $8, %rsp
	diem "todo: function_while"


/* ARITY THREE */

define_fn get, 3, 'G'
	sub $8, %rsp
	diem "todo: function_get"


define_fn if, 3, 'I'
	sub $8, %rsp
	diem "todo: function_if"

/* ARITY FOUR */

define_fn set, 4, 'S'
	sub $8, %rsp
	diem "todo: function_set"
