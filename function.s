.include "debugh.s"
.include "asth.s"
.include "envh.s"
.include "stringh.s"
.include "valueh.s"

.globl kn_function_startup
kn_function_startup:
	sub $8, %rsp
	xor %edi, %edi
	call _time
	mov %rax, %rdi
	add $8, %rsp
	jmp _srand

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
	call _rand
	add $8, %rsp
	KN_NEW_NUMBER %rax
	ret

/* ARITY ONE */

define_fn eval, 1, 'E'
	sub $8, %rsp
	diem "todo: function_eval"

define_fn noop, 1, ':' # this is never actually parsed, but is used by `BLOCK`
	mov (%rdi), %rdi
	jmp kn_value_run

define_fn block, 1, 'B'
# Optimization: the vast majority of the time, `BLOCK` is called with an AST already.
# So, if it's not called with an AST, we just convert its value into an AST. That way, `CALL` has
# an easier time running stuff.
	mov (%rdi), %rax

	test $KN_TAG_AST, %al
	jz 0f
	incl (-KN_TAG_AST + KN_AST_OFF_RC)(%rax) # TODO: Do we _need_ to clone the ast? (or free it in CALL)
	ret
0:
	# we're not an AST.
	push %rdi
	lea kn_func_noop(%rip), %rdi
	call kn_ast_alloc
	pop %rdi
	mov (%rdi), %rcx
	mov %rcx, KN_AST_OFF_ARGS(%rax)
	mov %rax, (%rdi) # make it so any further calls to this will give us this block
	incl KN_AST_OFF_RC(%rax) # TODO: Do we _need_ to clone the ast? (or free it in CALL)
	or $4, %al
	ret

define_fn call, 1, 'C'
	# execute the first value.
	mov (%rdi), %rdi
	push %rbx
	call kn_value_run

	.ifndef KN_RECKLESS
		test $KN_TAG_AST, %al
		jnz 0f
		diem "can only CALL 'BLOCK' return values."
	0:
	.endif

	# since we can only run `BLOCK` return values, which always returns ASTs, we can assume we're given an AST.
	lea (-KN_TAG_AST)(%rax), %rbx
	mov %rbx, %rdi
	run_ast %rdi, call

	# Next, decrease the refcount on the AST, freeing it if necessary.
	decl (%rbx)
	jz 0f
	# whelp, we don't need to free it, we're return the new value.
	pop %rbx
	ret
0:
	# looks like we gotta free the ast before returning
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_ast_free
	mov %rbx, %rax
	pop %rbx
	ret

define_fn system, 1, '`'
	sub $8, %rsp
	diem "todo: function_system"

define_fn quit, 1, 'Q'
	sub $8, %rsp
	mov (%rdi), %rdi
	call kn_value_to_number
	mov %rax, %rdi
	call _exit

define_fn not, 1, '!'
	# load the value to convert
	mov (%rdi), %rdi
	sub $8, %rsp
	call kn_value_to_boolean
	add $8, %rsp
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
	push %rdi
	# run the value
	mov (%rdi), %rdi
	call kn_value_run

	# check to see if we have a string
	mov %al, %cl
	and $0b111, %cl
	cmp $2, %cl
	jne 0f

	# We have a string, add the strings together.
	call ddebug
0:
	# Swap the previous value and the new one.
	mov (%rsp), %rdi
	mov %rax, (%rsp)
	mov 8(%rdi), %rdi

	# convert the RHS to a number
	call kn_value_to_number
	pop %rdi
	sar $3, %rdi

	add %rdi, %rax
	shl $3, %rax
	or $KN_TAG_NUMBER, %al
	ret

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
