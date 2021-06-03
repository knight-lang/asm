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
# 
# .ifndef NDEBUG
# 	push %rdi
# 	lea definefn_name\@(%rip), %rdi
# 	call _puts
# 	pop %rdi
# 	.pushsection .data, ""
# 	definefn_name\@:
# 		.asciz "\name"
# 	.popsection
# .endif
.endm

/* ARITY ZERO */

define_fn prompt, 0, 'P'
	sub $8, %rsp
	call prompt_for_a_line
	or $KN_TAG_STRING, %al
	add $8, %rsp
	ret

define_fn random, 0, 'R'
	sub $8, %rsp
	call _rand
	KN_NEW_NUMBER %rax
	add $8, %rsp
	ret

/* ARITY ONE */

define_fn eval, 1, 'E'
	sub $8, %rsp
	# convert the argument to a string
	mov (%rdi), %rdi
	call kn_value_to_string

	# store the value so we can free it later, then run it.
	mov %rax, (%rsp)
	STRING_PTR %rax, %rdi
	call kn_run

	# only free if necessary
	pop %rdi
	decl (%rdi)
	jz 0f
	# dont gotta free, and we already popped, so we're good.
	ret
0:
	push %rax
	call kn_string_free
	pop %rax
	ret

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
	mov %rax, (%rsp)
	mov (%rsp), %rbx
	call kn_ast_free
	pop %rax
	ret

define_fn system, 1, '`'
	push %rbx
	mov (%rdi), %rdi
	call kn_value_to_string
	mov %rax, %rbx
	STRING_PTR %rax, %rdi
	call shell_command
	or $KN_TAG_STRING, %al
	decl (%rbx)
	jz 0f
	pop %rbx
	ret
0:
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_string_free
	mov %rbx, %rax
	pop %rbx
	ret

define_fn quit, 1, 'Q'
	sub $8, %rsp
	mov (%rdi), %rdi
	call kn_value_to_number
	mov %rax, %rdi
	call _exit

define_fn not, 1, '!'
	mov (%rdi), %rdi
	# it's unlikely to try to invert anything other than an AST, as that's just a constant operation.
	test $KN_TAG_AST, %dil
	jz .kn_func_not_nonast
	mov (-KN_TAG_AST + KN_AST_OFF_FN)(%rdi), %rax
	lea (-KN_TAG_AST + KN_AST_OFF_ARGS)(%rdi), %rdi
	sub $8, %rsp
	call *%rax
	add $8, %rsp
	# todo: assert that it must be idempotent
	mov %rax, %rdi
.kn_func_not_nonidempotent:
	xor %eax, %eax
	# If it's a falsey literal/constant, then return true.
	cmp $KN_NULL, %rdi
	ja 0f
	mov $KN_TRUE, %al
	ret
0:
	# If it's a nonstring, then it becomes falsey
	mov %dil, %cl
	and $0b111, %cl
	cmp $KN_TAG_STRING, %cl
	je 0f
	ret
0:	
	mov (-KN_TAG_STRING + KN_STR_OFF_LEN)(%rdi), %edi
	test %edi, %edi # only nonempty strings are true.
	setz %al
	shl $4, %al
	ret
.kn_func_not_nonast:
	mov %dil, %cl
	and $0b111, %cl
	cmp $KN_TAG_VARIABLE, %cl
	jne .kn_func_not_nonidempotent
	and $~0b111, %dil
	run_var %rdi
	jmp .kn_func_not_nonidempotent

#	# load the value to convert
#	mov (%rdi), %rdi
#	sub $8, %rsp
#	call kn_value_to_boolean
#	add $8, %rsp
#	# bit twiddle the return value.
#	xor $1, %al
#	shl $4, %al
#	ret

define_fn length, 1, 'L'
	push %rbx
	mov (%rdi), %rdi
	# TODO: preemptively check its type.
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
	mov KN_STR_OFF_LEN(%rax), %esi
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
	# diem "todo: print without trailing newline. (%esi is length, %rdi is pointer)"
	# jmp .kn_output_free_string
	call _puts
.kn_output_just_newline:
	# we don't need to free the string, as the string is the empty string.
	mov $'\n', %dil
	call _putchar
	pop %rbx
	mov $KN_NULL, %eax
	ret

define_fn dump, 1, 'D'
	sub $8, %rsp
	mov (%rdi), %rdi
	call kn_value_run
	mov %rax, (%rsp)
	mov %rax, %rdi
	call kn_value_dump
	mov $'\n', %edi
	call _putchar
	pop %rax
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
	jne .kn_func_add_numbers
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
	inc %edi
	call kn_string_malloc
	mov %rax, %r13

	# Concat concat the first string.
	STRING_PTR %rax, %rdi
	STRING_PTR %rbx, %rsi
	mov KN_STR_OFF_LEN(%rbx), %ebx
	mov %ebx, %edx
	call _memcpy

	# Cocnat the second string
	mov %rax, %rdi
	add %rbx, %rdi
	STRING_PTR %r12, %rsi
	mov KN_STR_OFF_LEN(%r12), %edx
	inc %edx # +1 so we copy trailing `\0
	call _memcpy

	# TODO: free the input strings...

	KN_NEW_STRING %r13, %rax
	pop %r13
	pop %r12
	pop %rbx
	ret
0:
	jmp _exit
	diem "oop"

.kn_func_add_numbers:
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
	push %rbx
	push %r12
	mov 8(%rdi), %rbx
	# Run the LHS
	mov (%rdi), %rdi
	call kn_value_run

	# see if the LHS is a string
	mov %al, %cl
	and $0b111, %cl
	cmp $KN_TAG_STRING, %cl
	jne .kn_func_lth_not_string
	and $~0b111, %al # delete string tag if it is.

	# it is, convert the rhs to a string
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_to_string
	mov %rax, %r12

	# now compare them
	STRING_PTR %rbx, %rdi
	STRING_PTR %rax, %rsi
	call _strcmp

	# free lhs and store old result
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	decl KN_STR_OFF_RC(%r12)
	jz 1f
	movsx %eax, %rbx

.kn_func_lth_done:
	xor %eax, %eax
	cmp $0, %rbx
	setl %al
	shl $4, %al
	pop %r12
	pop %rbx
	add $8, %rsp
	ret
0:
	# gotta free lhs, and possibly rhs. also gotta save %rax for later.
	mov %rbx, %rdi
	movsx %eax, %rbx
	call kn_string_free
	# do we have to free the rhs?
	decl KN_STR_OFF_RC(%r12)
	jnz .kn_func_lth_done
	# yup, fallthrough
	mov %rbx, %rax # just so the next line is a noop
1:
	# gotta free rhs and save %rax for later. lhs has already been dealt with.
	movsx %eax, %rbx # store the previous value
	mov %r12, %rdi
	call kn_string_free
	jmp .kn_func_lth_done

.kn_func_lth_not_string:
	# `cl` has the tag in it
	cmp $KN_TAG_NUMBER, %cl
	jne 0f

	# it's a number, convert the rhs to a number and compare.
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_to_number
	sar $3, %rbx # convert rbx back to a normal number
	sub %rax, %rbx
	jmp .kn_func_lth_done
0:
	# we're given a boolean.
	.ifndef KN_RECKLESS
		cmp $KN_TRUE, %rax
		je 0f
		cmp $KN_FALSE, %rax
		je 0f
		diem "can only compare numbers, booleans, and strings"
	0:
	.endif

	# it's a boolean, convert the rhs to a boolean and compare.
	mov %rbx, %rdi
	mov %eax, %ebx
	call kn_value_to_boolean
	shr $4, %bl # get rid of tag
	sub %rax, %rbx
	jmp .kn_func_lth_done

define_fn gth, 2, '>'
	sub $8, %rsp
	push %rbx
	push %r12
	mov 8(%rdi), %rbx
	# Run the LHS
	mov (%rdi), %rdi
	call kn_value_run

	# see if the LHS is a string
	mov %al, %cl
	and $0b111, %cl
	cmp $KN_TAG_STRING, %cl
	jne .kn_func_gth_not_string
	and $~0b111, %al # delete string tag if it is.

	# it is, convert the rhs to a string
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_to_string
	mov %rax, %r12

	# now compare them
	STRING_PTR %rbx, %rdi
	STRING_PTR %rax, %rsi
	call _strcmp

	# free lhs and store old result
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	decl KN_STR_OFF_RC(%r12)
	jz 1f
	movsx %eax, %rbx

.kn_func_gth_done:
	xor %eax, %eax
	cmp $0, %rbx
	setg %al
	shl $4, %al
	pop %r12
	pop %rbx
	add $8, %rsp
	ret
0:
	# gotta free lhs, and possibly rhs. also gotta save %rax for later.
	mov %rbx, %rdi
	movsx %eax, %rbx
	call kn_string_free
	# do we have to free the rhs?
	decl KN_STR_OFF_RC(%r12)
	jnz .kn_func_gth_done
	# yup, fallthrough
	mov %rbx, %rax # just so the next line is a noop
1:
	# gotta free rhs and save %al for later. lhs has already been dealt with.
	movsx %eax, %rbx # store the previous value
	mov %r12, %rdi
	call kn_string_free
	jmp .kn_func_gth_done

.kn_func_gth_not_string:
	# `cl` has the tag in it
	cmp $KN_TAG_NUMBER, %cl
	jne 0f

	# it's a number, convert the rhs to a number and compare.
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_to_number
	sar $3, %rbx # convert rbx back to a normal number
	sub %rax, %rbx
	jmp .kn_func_gth_done
0:
	# we're given a boolean.
	.ifndef KN_RECKLESS
		cmp $KN_TRUE, %rax
		je 0f
		cmp $KN_FALSE, %rax
		je 0f
		diem "can only compare numbers, booleans, and strings"
	0:
	.endif

	# it's a boolean, convert the rhs to a boolean and compare.
	mov %rbx, %rdi
	mov %eax, %ebx
	call kn_value_to_boolean
	shr $4, %bl # get rid of the tag.
	sub %rax, %rbx
	jmp .kn_func_gth_done


define_fn eql, 2, '?'
	push %rbx
	mov 8(%rdi), %rbx

	# Run LHS then RHS.
	mov (%rdi), %rdi
	call kn_value_run
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_run

	# If they're identical, then they're equal.
	cmp %rax, %rbx
	je .kn_func_eql_identical

	# ensure they are both strings.
	mov $0b111, %cl
	and %al, %cl
	and %bl, %cl
	cmp $KN_TAG_STRING, %cl
	jne .kn_func_eql_nonstring

	# now we know they're both strings, we compare them.
	# Make sure they have the same length.
	mov (-KN_TAG_STRING + KN_STR_OFF_LEN)(%rax), %ecx
	mov (-KN_TAG_STRING + KN_STR_OFF_LEN)(%rbx), %edx
	cmp %ecx, %edx
	sete %cl
	jne .kn_func_eql_free_strings

	# TODO: remove these
	and $~0b111, %al
	and $~0b111, %bl

	# Now that we actually have to compare them, we need to preserve rax.
	sub $16, %rsp
	mov %rax, (%rsp)

	# now actually memcmp then
	STRING_PTR %rax, %rsi
	STRING_PTR %rbx, %rdi
	# rdx is already the length from when we checked lengths.
	call _memcmp
	test %eax, %eax
	setz %cl

	# restore the old rhs value so we can free it.
	mov (%rsp), %rax
	add $16, %rsp

	# fallthrough

.kn_func_eql_free_strings:
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	decl KN_STR_OFF_RC(%rax)
	jz 1f
	# otherwise, fallthrough
.kn_func_eql_done_strings:
	movzb %cl, %eax
	shl $4, %al
	pop %rbx
	ret
0: # ok, gotta free rbx (and possibly rax)
	# we have to preserve %cl too as it contains the return value.
	push %rcx
	push %rax
	mov %rbx, %rdi
	call kn_string_free
	# now check to see if we have to free  rax.
	mov (%rsp), %rdi
	decl KN_STR_OFF_RC(%rdi)
	pop %rax
	pop %rcx
	jnz .kn_func_eql_done_strings
	# whelp, we gotta free rbx. fallthrough
1: # gotta free rhs
	# we dont have to keep track of `%rbx`, as we already checked for that before.
	mov %cl, %bl
	mov %rax, %rdi
	call kn_string_free
	mov %bl, %cl
	jmp .kn_func_eql_done_strings

.kn_func_eql_identical:
	mov %rax, %rdi
	call kn_value_free
	mov %rbx, %rdi
	call kn_value_free
	mov $KN_TRUE, %eax
	pop %rbx
	ret
.kn_func_eql_nonstring:
	mov %rax, %rdi
	call kn_value_free
	mov %rbx, %rdi
	call kn_value_free
	xor %eax, %eax
	pop %rbx
	ret

define_fn and, 2, '&'
	push 8(%rdi)
	mov (%rdi), %rdi
	call kn_value_run
	pop %rdi

	# it's quite likely for `&` to have the first field be a boolean.
	test %rax, %rax
	jnz 0f # Inf it's false just return that.
	ret
0:
	cmp $KN_TRUE, %rax
	je kn_value_run # If it's true, just run the rhs
# We're dealing with a non-boolean for the first value, so we have a bit more to do, eg freeing it.
	push %rdi
	push %rax
	sub $8, %rsp
	mov %rax, %rdi
	# convert the evaluated lhs to a boolean
	call kn_value_to_boolean
	# If it's truthy, then return the rhs
	test %al, %al
	jnz 0f
	# it's truthy, so return it
	mov 8(%rsp), %rax
	add $24, %rsp
	ret
0:
	# it's falsey, so free the lhs and then execute the rhs.
	mov 8(%rsp), %rdi
	call kn_value_free
	mov 16(%rsp), %rdi
	add $24, %rsp
	jmp kn_value_run

define_fn or, 2, '|'
	push 8(%rdi)
	mov (%rdi), %rdi
	call kn_value_run
	pop %rdi

	# it's quite likely for `|` to have the first field be a boolean.
	test %rax, %rax
	jz kn_value_run
	cmp $KN_TRUE, %rax
	jnz 0f
	ret

# We're dealing with a non-boolean for the first value, so we have a bit more to do, eg freeing it.
0:
	push %rdi
	push %rax
	sub $8, %rsp
	mov %rax, %rdi
	# convert the evaluated lhs to a boolean
	call kn_value_to_boolean
	# If it's falsey, then return the rhs
	test %al, %al
	jz 0f
	# it's falsey, so return it
	mov 8(%rsp), %rax
	add $24, %rsp
	ret
0:
	# it's truthy, so free the lhs and then execute the rhs.
	mov 8(%rsp), %rdi
	call kn_value_free
	mov 16(%rsp), %rdi
	add $24, %rsp
	jmp kn_value_run

define_fn then, 2, ';'
	push 8(%rdi)
	mov (%rdi), %rdi

	# The only value kind that makes sense to run on the LHS is an AST. Running undefined
	# variables is UB, and all other types are idempotent. So just ignore other types.
	test $KN_TAG_AST, %rdi
	jz 0f
	mov (-KN_TAG_AST + KN_AST_OFF_FN)(%rdi), %rax
	lea (-KN_TAG_AST + KN_AST_OFF_ARGS)(%rdi), %rdi
	call *%rax
	mov %rax, %rdi
	call kn_value_free
0:
	pop %rdi
	# It's likely to have an AST on the RHS of an AST, second only by a variable.
	test $KN_TAG_AST, %dil
	jz 0f
	mov (-KN_TAG_AST + KN_AST_OFF_FN)(%rdi), %rax
	lea (-KN_TAG_AST + KN_AST_OFF_ARGS)(%rdi), %rdi
	jmp *%rax
0:
	# Check to see if it's a variable.
	mov %dil, %cl
	and $0b111, %cl
	cmp $KN_TAG_VARIABLE, %cl
	jne 0f
	and $~0b111, %dil
	run_var %rdi, %rax
	ret
0:
	# If it's not a string, just return the literal value.
	mov %rdi, %rax
	cmp $KN_TAG_STRING, %cl
	jne 0f
	incl (-KN_TAG_STRING + KN_STR_OFF_RC)(%rdi) # ok it's a string, increment the refcount.
0:
	ret

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
	push (%rdi)

	# Execute the rhs
	mov 8(%rdi), %rdi
	call kn_value_run

	mov (%rsp), %rcx

	# Store the new result, preserving the old one so we can free it.
	mov (-KN_TAG_VARIABLE + KN_VAR_OFF_VAL)(%rcx), %rdi
	mov %rax, (-KN_TAG_VARIABLE + KN_VAR_OFF_VAL)(%rcx)
	mov %rax, (%rsp)

	# Free the old result
	call kn_value_free

	# Clone the new result
	pop %rdi
	jmp kn_value_clone

define_fn while, 2, 'W'
	push %rbx
	push %r12
	push %r13
	mov (%rdi), %rbx
	mov 8(%rdi), %r12

	# optimize for the case where both the cond and body are while ASTs.
	mov $0b111, %cl
	and %bl, %cl
	and %r12b, %cl
	cmp $KN_TAG_AST, %cl
	jne .kn_func_while_nonasts

.kn_func_while_ast_top:
	mov (-KN_TAG_AST + KN_AST_OFF_FN)(%rbx), %rax
	lea (-KN_TAG_AST + KN_AST_OFF_ARGS)(%rbx), %rdi
	call *%rax
	test %rax, %rax
	jz .kn_func_while_done
	cmp $KN_TRUE, %eax
	jne .kn_func_while_ast_check_cond

.kn_func_while_ast_body:
	mov (-KN_TAG_AST + KN_AST_OFF_FN)(%r12), %rax
	lea (-KN_TAG_AST + KN_AST_OFF_ARGS)(%r12), %rdi
	call *%rax
	mov %rax, %rdi
	call kn_value_free
	jmp .kn_func_while_ast_top

.kn_func_while_done:
	pop %r13
	pop %r12
	pop %rbx
	mov $KN_NULL, %eax
	ret
.kn_func_while_ast_check_cond:
	mov %rax, %rdi
	mov %rax, %r13
	call kn_value_to_boolean
	mov %r13, %rdi
	mov %rax, %r13
	call kn_value_free
	test %r13, %r13
	jnz .kn_func_while_ast_body
	jmp .kn_func_while_done

.kn_func_while_nonasts:
	mov %rbx, %rdi
	call kn_value_to_boolean
	test %rax, %rax
	jz .kn_func_while_done
	mov %r12, %rdi
	call kn_value_run
	mov %rax, %rdi
	call kn_value_free
	jmp .kn_func_while_nonasts

/* ARITY THREE */

define_fn get, 3, 'G' # 1761478
	push %rbx
	push %r12
	push %r13
	mov (%rdi), %rbx
	mov 8(%rdi), %r12
	mov 16(%rdi), %r13

	# convert all operands.
	mov %rbx, %rdi
	call kn_value_to_string
	mov %rax, %rbx

	mov %r12, %rdi
	call kn_value_to_number
	mov %rax, %r12

	mov %r13, %rdi
	call kn_value_to_number
	mov %rax, %r13

	# perform the offset and create a new string
	STRING_PTR %rbx, %rdi
	add %r12, %rdi
	mov %r13, %rsi
	call kn_string_new_borrowed
	or $KN_TAG_STRING, %al

	# decrement the old string refcount
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	pop %r13
	pop %r12
	pop %rbx
	ret
0:
	# free the original string
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_string_free
	mov %rbx, %rax
	pop %r13
	pop %r12
	pop %rbx
	ret

define_fn if, 3, 'I'
	push %rdi
	mov (%rdi), %rdi
	call kn_value_to_boolean
	pop %rdi
	neg %al
	inc %al
	mov 8(%rdi,%rax,8), %rdi
	jmp kn_value_run

/* ARITY FOUR */

define_fn set, 4, 'S'
	push %rbx
	mov (%rdi), %rdi
	call kn_value_to_string
	mov %rax, %rbx

# TODO: actually perform `set`
	STRING_PTR %rax, %rdi
	inc %rdi

	mov KN_STR_OFF_LEN(%rax), %esi
	test %esi, %esi
	jz 0f
	dec %esi
0:
	call kn_string_new_borrowed
	or $KN_TAG_STRING, %al

	# decrement the old string refcount
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	pop %rbx
	ret
0:
	# free the original string
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_string_free
	mov %rbx, %rax
	pop %rbx
	ret


/*
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	mov (%rdi), %rbx
	mov 8(%rdi), %r12
	mov 16(%rdi), %r13
	mov 24(%rdi), %r14

	# convert all operands.
	mov %rbx, %rdi
	call kn_value_to_string
	mov %rax, %rbx

	mov %r12, %rdi
	call kn_value_to_number
	mov %rax, %r12

	mov %r13, %rdi
	call kn_value_to_number
	mov %rax, %r13

	mov %r13, %rdi
	call kn_value_to_string
	mov %rax, %r14

	# TODO: DO something other than just reading the first index.
	STRING_PTR %rbx, %rdi
	inc %rdi

	STRING_LEN %rbx, %esi
	dec %rsi
	call kn_string_new_borrowed
	or $KN_TAG_STRING, %al

	# decrement the old string refcount
	decl KN_STR_OFF_RC(%rbx)
	jz 0f
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	ret
0:
	# free the original string
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_string_free
	mov %rbx, %rax
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	ret*/
