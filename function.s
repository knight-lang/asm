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
	push %rbx
	mov (%rdi), %rdi
	call kn_value_to_string
	mov KN_STR_OFF_LEN(%rax), %ebx
	decl KN_STR_OFF_RC(%rax)
	jnz 0f
	mov %rax, %rdi
	call kn_string_free
0:
	KN_NEW_NUMBER %rbx, %rax
	pop %rbx
	ret

define_fn output, 1, 'O'
	push %rbx
	# convert the input to a string
	mov (%rdi), %rdi
	call kn_value_to_string
	# Store the return value so we can free it later.
	mov %rax, %rbx

	# If the length is zero, we just put a newline and are done.
	STRING_LEN %rax, %esi
	test %rsi, %rsi
	jz .kn_output_just_newline

	# Otherwise, now check for the trailing newline.
	STRING_PTR %rax, %rdi
	dec %rsi
	mov (%rdi, %rsi), %cl
	cmp $'\\', %cl
	je .kn_output_no_slash

	# we don't have a trailing newline, just `puts` it.
	call _puts
.kn_output_free_string:
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	# it's not zero, we're done.
	pop %rbx
	mov $KN_NULL, %eax
	ret
0:
	# it's zero, we gotta free it
	mov %rbx, %rdi
	call kn_string_free
	pop %rbx
	mov $KN_NULL, %EAX
	ret
.kn_output_no_slash:
	# Ok, now we gotta print it without the trailing newline.
	diem "todo: print without trailing newline. (%esi is length, %rdi is pointer)"
	jmp .kn_output_free_string
.kn_output_just_newline:
	# we don't need to free the string, as the string is the empty string.
	mov $'\n', %dil
	call _putchar
	pop %rbx
	mov $KN_NULL, %eax
	ret
/*
     size_t
     fwrite(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream);
*/


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
	mov 8(%rdi), %rbx

	# run the value
	mov (%rdi), %rdi
	call kn_value_run

	# Swap the previous value and the new one.
	mov %rbx, %rdi
	mov %rax, %rbx

	# check to see if we have a string
	mov %al, %cl
	and $0b111, %cl
	cmp $KN_TAG_STRING, %cl
	jne .kn_func_add_numebrs
	and $~0b111, %bl

	# We have a string, convert rhs to a string.
	call kn_value_to_string
	push %r12
	push %r13
	mov %rax, %r12

	# (In the future, we could look up the hashed value.)
	# Compute the new length and malloc it.
	mov KN_STR_OFF_LEN(%rbx), %edi
	add KN_STR_OFF_LEN(%rax), %edi
	call kn_string_malloc
	mov %rax, %r13

	# Concat concat the first string.
	STRING_PTR %rax, %rdi
	STRING_PTR %rbx, %rsi
	mov KN_STR_OFF_LEN(%rbx), %ebx # note it's not `+1`, so we omit railing newline
	mov %ebx, %edx
	call _memcpy

	# Cocnat the second string
	mov %rax, %rdi
	add %rbx, %rdi
	STRING_PTR %r12, %rsi
	mov KN_STR_OFF_LEN(%r12), %edx
	inc %edx # +1 so we copy trailing `\0`
	call _memcpy

	# TODO: free the input strings...

	KN_NEW_STRING %r13, %rax
	pop %r13
	pop %r12
	pop %rbx
	ret

.kn_func_add_numebrs:
	# we convert rhs to a number and perform the operation
	call kn_value_to_number
	mov %rbx, %rdi
	pop %rbx
	sar $3, %rdi
	add %rdi, %rax
	KN_NEW_NUMBER %rax
	ret

define_fn sub, 2, '-'
	push 8(%rdi)
	# run the value
	mov (%rdi), %rdi
	# jmp ddebug
	call kn_value_to_number

	# Swap the previous value and the new one.
	mov (%rsp), %rdi
	mov %rax, (%rsp)

	# we convert rhs to a number and perform the operation
	call kn_value_to_number
	pop %rdi
	sub %rax, %rdi
	KN_NEW_NUMBER %rdi, %rax
	ret


define_fn mul, 2, '*'
	push 8(%rdi)
	# run the value
	mov (%rdi), %rdi
	call kn_value_to_number

	# Swap the previous value and the new one.
	mov (%rsp), %rdi
	mov %rax, (%rsp)

	# we convert rhs to a number and perform the operation
	call kn_value_to_number
	pop %rdi
	imul %rax, %rdi
	KN_NEW_NUMBER %rdi, %rax
	ret

define_fn div, 2, '/'
	push 8(%rdi)
	# run the value
	mov (%rdi), %rdi
	call kn_value_to_number

	# Swap the previous value and the new one.
	mov (%rsp), %rdi
	mov %rax, (%rsp)

	# we convert rhs to a number and perform the operation
	call kn_value_to_number
	mov %rax, %rsi
	pop %rax
	cqto
	idiv %rsi
	KN_NEW_NUMBER %rax
	ret

define_fn mod, 2, '%'
	push 8(%rdi)
	# run the value
	mov (%rdi), %rdi
	call kn_value_to_number

	# Swap the previous value and the new one.
	mov (%rsp), %rdi
	mov %rax, (%rsp)

	# we convert rhs to a number and perform the operation
	call kn_value_to_number
	mov %rax, %rsi
	pop %rax
	cltd
	idiv %rsi
	KN_NEW_NUMBER %rdx, %rax # %rdx is the div output.
	ret

define_fn pow, 2, '^'
	push 8(%rdi)
	# run the value
	mov (%rdi), %rdi
	call kn_value_to_number

	# Swap the previous value and the new one.
	mov (%rsp), %rdi
	mov %rax, (%rsp)

	# we don't have a string, convert rhs to a number and add.
	call kn_value_to_number
        pxor %xmm0, %xmm0
        pxor %xmm1, %xmm1
        cvtsi2sdq (%rsp), %xmm0
        cvtsi2sdq %rax, %xmm1
        call _pow
        cvttsd2siq %xmm0, %rax
	KN_NEW_NUMBER %rax
	pop %rcx
        ret

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
	push 8(%rdi)
	mov (%rdi), %rdi
	call kn_value_run
	mov %rax, %rdi
	call kn_value_free
	pop %rdi
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
#	sub $8, %rsp
#	push (%rdi)
#	push 8(%rdi)
#0:
#	# Covnert the first argument to 
#	mov (%rsp), %rdi
#	call kn_value_to_boolean
#	test %al, %al
#	jz 0f
#
#	mov 
#0:
#	mov $KN_NULL, %rax
	sub $8, %rsp
	diem "todo: function_while"


/* ARITY THREE */

define_fn get, 3, 'G'
	sub $8, %rsp
	diem "todo: function_get"


define_fn if, 3, 'I'
	push %rdi
	mov (%rdi), %rdi
	call kn_value_to_boolean
	pop %rdi
	mov 8(%rdi,%rax,8), %rdi
	jmp kn_value_run

/* ARITY FOUR */

define_fn set, 4, 'S'
	sub $8, %rsp
	diem "todo: function_set"
