.include "debugh.s"
.include "valueh.s"
.include "stringh.s"
.include "asth.s"
.include "envh.s"

.macro _assert_one_of dst:req, reg:req, kind="", rest1:vararg
	.ifnb \kind
		cmp $\kind, \reg
		je \dst
		_assert_one_of \dst, \reg, \rest1
	.endif
.endm

.macro assert_is_one_of reg:req, rest:vararg
	.ifndef NDEBUG
		_assert_one_of .Lassert_kind_one_of_end_\@, \reg, \rest
		diem "oops: \reg is not one of: \rest"
	.endif
.Lassert_kind_one_of_end_\@:
.endm

.kn_value_to_number_run_var:
	run_var %rdi
	# fallthrough
.globl kn_value_to_number
kn_value_to_number:
	# Fetch the tag
	mov %dil, %cl
	and $0b111, %cl

	# Optimize for number->number conversions, as they're so likely.
	cmp $KN_TAG_NUMBER, %cl
	jne 0f
	sar $3, %rdi
	mov %rdi, %rax
	ret
0:
	and $~0b111, %dil
	# Check for variables next
	cmp $KN_TAG_VARIABLE, %cl
	je .kn_value_to_number_run_var

	# string conversions
	cmp $KN_TAG_STRING, %cl
	jne 0f
	STRING_PTR %rdi
	xor %esi, %esi
	mov $10, %edx
	jmp _strtoll
0:
	# ast conversions
	cmp $KN_TAG_AST, %cl
	jne 0f
	push %rbx
	run_ast %rdi, call
	mov %rax, %rbx
	mov %rax, %rdi
	call kn_value_to_number
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_free
	mov %rbx, %rax
	pop %rbx
	ret
0:
	xor %eax, %eax
#	assert_is_one_of %cl, $KN_TRUE, $KN_FALSE, $KN_NULL
	test $KN_TRUE, %dil
	setne %al
	ret

kn_value_to_string_run_var:

	run_var %rdi
	# fallthrough
.globl kn_value_to_string
kn_value_to_string:
	# Fetch the tag
	mov %dil, %cl
	mov %rdi, %rax
	and $0b111, %cl
	and $~0b111, %dil

	# If we're a string (most common case), then increment our refcount and retrn.
	cmp $KN_TAG_STRING, %cl
	jne 0f
	incl KN_STR_OFF_RC(%rdi)
	and $~0b111, %al
	ret # we're given a string so just return it.
0:
# If it's a variable, jump to just above the function and try again.
	cmp $KN_TAG_VARIABLE, %cl
	je kn_value_to_string_run_var
	# If it's an AST, we have to run it, then convert the result to a string.
	test $KN_TAG_AST, %cl
	jz .kn_value_to_string_number_builtin
	push %rbx
	run_ast %rdi, call

	# If the ast returns a string, just return that directly
	mov %al, %cl
	and $0b111, %cl
	cmp $KN_TAG_STRING, %cl
	jne 1f
	and $~0b111, %al
	pop %rbx
	ret
1:
	# The AST returned a non-string, so we have to run it the long way
	mov %rax, %rbx
	mov %rax, %rdi
	call kn_value_to_string
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_free
	mov %rbx, %rax
	pop %rbx
	ret
.kn_value_to_string_number_builtin: # either a number or a builtin.
	# If the value's small enough, we can use the special builtins.
	cmp $0b10001, %rax
	ja .kn_value_to_string_number
	movzb %al, %eax
	imul $KN_STR_SIZE, %rax # `mul` without imul?
	lea kn_value_string_reprs(%rip), %rdi
	add %rdi, %rax
	incl (%rax) # gotta increase refcount so we can free it later.
	ret
.kn_value_to_string_number:
	assert_is_one_of %cl, KN_TAG_NUMBER
	sar $3, %rdi
	push %rbx
	call number_to_string
	mov %rax, %rbx
	mov %rax, %rdi
	call _strlen
	mov %rbx, %rdi
	mov %rax, %rsi
	pop %rbx
	jmp kn_string_new_borrowed

.pushsection .data, ""
kn_value_string_sprintf:        .asciz "%lld"
.align 16
kn_value_string_reprs:
	STATIC_STRING "false", 5
	STATIC_STRING "0", 1
	.zero KN_STR_SIZE*6
	STATIC_STRING "null", 4
	STATIC_STRING "1", 1
	.zero KN_STR_SIZE*6
	STATIC_STRING "true", 4
	STATIC_STRING "2", 1
.popsection

.globl kn_value_to_boolean
kn_value_to_boolean:
	# small hack: Anything less than or equal to KN_NULL is false:
	# FALSE is `0b0000`, zero is `0b0001`, and NULL is `0b0000`

	xor %eax, %eax

	# First, check to see if it's a falsey literal/constant. if so, return that.
	cmp $KN_NULL, %rdi
	ja 0f
	assert_is_one_of %dil, KN_NULL, KN_FALSE, KN_TAG_NUMBER
	ret # eax is already xor'd
0:
	# Next to see if it's an Ast. If it is, then run it, then convert it.
	test $KN_TAG_AST, %dil
	jz 0f
	push %rbx
	and $~0b111, %dil
	run_ast %rdi, call
	mov %rax, %rdi
	mov %rax, %rbx
	call kn_value_to_boolean
	# gotta make sure we free the result.
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_free
	mov %rbx, %rax
	pop %rbx
	ret
0:
	# Now, check to see if it's a number or TRUE. Since we already checked for NULL, FALSE, and 0,
	# the return value is just true. `0b10` is only ever set for Var/String, so not being set indicates
	# that we're a constnat or number
	test $0b10, %dil
	jnz 0f
	.ifndef NDEBUG
		and $0b111, %dil
		assert_is_one_of %dil, KN_TAG_CONSTANT, KN_TAG_NUMBER
	.endif
	inc %eax
	ret
0:
	mov %dil, %cl
	and $~0b111, %dil
	# Now we see if we're a variable, and execute it if we are. 
	.ifndef NDEBUG
		and $0b111, %cl
		assert_is_one_of %cl, KN_TAG_VARIABLE, KN_TAG_STRING
	.endif
	test $0b01, %cl
	jnz 0f

	# It's a variable! run it and call the function again.
	push %rbx
	
	run_var %rdi
	mov %rdi, %rbx
	call kn_value_to_boolean
	# gotta make sure we free the result.
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_free
	mov %rbx, %rax
	pop %rbx
	ret	
0:
	# It's a string! this is simply the value at its pointer
	STRING_PTR %rdi
	cmpb $0, (%rdi)
	setne %al
	ret

# This is such a hack, and is just here for shiggles
.globl kn_value_dump
kn_value_dump:
	push %rbx
	mov %rsp, %rbx
	# Store the passed argument so we can return it later.
	mov %rdi, %rbx

	# Load the name
	cmp $KN_NULL, %rdi
	jne 0f
	lea kn_value_dump_null(%rip), %rdi
	jmp 1f
0:
	cmp $KN_TRUE, %rdi
	jne 0f
	lea kn_value_dump_true(%rip), %rdi
	jmp 1f
0:
	cmp $KN_FALSE, %rdi
	jne 0f
	lea kn_value_dump_false(%rip), %rdi
	jmp 1f
0:
	mov %dil, %al
	and $0b111, %al
	cmp $KN_TAG_NUMBER, %al
	jne 0f
	mov %rdi, %rsi
	sar $3, %rsi
	lea kn_value_dump_number(%rip), %rdi
	jmp 1f
0:
	cmp $KN_TAG_STRING, %al
	jne 0f
	mov %rdi, %rsi
	and $~0b111, %sil
	STRING_PTR %rsi
	lea kn_value_dump_string(%rip), %rdi
	jmp 1f
0:
	cmp $KN_TAG_VARIABLE, %al
	jne 0f
	mov %rdi, %rsi
	and $~0b111, %sil
	mov KN_VAR_OFF_NAME(%rsi), %rsi
	lea kn_value_dump_variable(%rip), %rdi
	jmp 1f
0:
	cmp $KN_TAG_AST, %al
	je 0f
	diem "unknown type to dump"
0:
	and $~0b111, %rdi
	call dump_ast
	jmp 0f
1:
	call _printf
0:
	mov %rbx, %rax
	mov %rsp, %rcx
	pop %rbx
	ret

dump_ast:
        pushq   %rbp
        movq    %rdi, %rbp
        pushq   %rbx
        subq    $8, %rsp
        movq    8(%rdi), %rax
        lea      kn_value_dump_ast(%rip), %rdi
        movsbl  -2(%rax), %esi
        xorl    %eax, %eax
        call    _printf
        movq    8(%rbp), %rax
        cmpb    $0, -1(%rax)
        je      .L2
        xorl    %ebx, %ebx
.L3:
        movl    $44, %edi
        xorl    %eax, %eax
        call    _putchar
        movl    $32, %edi
        xorl    %eax, %eax
        call    _putchar
        movl    %ebx, %eax
        addl    $1, %ebx
        movq    16(%rbp,%rax,8), %rdi
        xorl    %eax, %eax
        call    kn_value_dump
        movq    8(%rbp), %rax
        movsbl  -1(%rax), %eax
        cmpl    %ebx, %eax
        ja      .L3
.L2:
        addq    $8, %rsp
        movl    $41, %edi
        xorl    %eax, %eax
        popq    %rbx
        popq    %rbp
        jmp     _putchar

.pushsection .data, ""
kn_value_dump_null:
	.asciz "Null()"
kn_value_dump_number:
	.asciz "Number(%lld)"
kn_value_dump_string:
	.asciz "String(%s)"
kn_value_dump_true:
	.asciz "Boolean(true)"
kn_value_dump_false:
	.asciz "Boolean(false)"
kn_value_dump_variable:
	.asciz "Variable(%s)"
kn_value_dump_ast:
	.asciz "Ast(%c"
.popsection

.globl kn_value_run
kn_value_run:
	# Store the argument as the return value. this also allows us to just directly return it if
	# we have a number or constant.
	mov %rdi, %rax
	mov %dil, %cl

	# Fetch the type we're given
	and $~0b111, %dil

	# First check to see if it's an Ast. If it is, then run it.
	test $KN_TAG_AST, %al
	jz 0f
	run_ast %rdi, jmp
0:
	# Now, check if it's a variable. If it is, then simply load its value.
	and $0b111, %cl
	cmp $KN_TAG_VARIABLE, %cl
	jne 0f
	
	run_var %rdi, %rax
	ret
0:
	# Now we know it's a constant, string or number, all of which are returned themselves.
	assert_is_one_of %cl, KN_TAG_CONSTANT, KN_TAG_STRING, KN_TAG_NUMBER

	# If it's a string, increment its refcount.
	# technically the string tag is `0b011`, but since we've already take care of `0b010` above,
	# we know if `0b10` is set, then it's a string.
	test $0b010, %cl
	jz 0f
	incl (%rdi)
0:
	ret

.globl kn_value_free
kn_value_free:
	# Find the tag
	mov %dil, %al
	and $0b111, %al

	# If it's a constant, number, or variable, just ignore it.
	cmp $2, %al
	jbe 1f
0:
	assert_is_one_of %al, KN_TAG_STRING, KN_TAG_AST
	# Remove the tag for when we call functions.
	and $~0b111, %dil

	# ensure we don't have a zero refcount
	.ifndef NDEBUG
		cmpl $0, (%rdi)
		jnz 2f
		ret # TODO: THIS
		diem "attempted to free a string/ast with zero refcount?"
	2:
	.endif

	# Both strings and asts have the refcount in the same position, so freeing is just
	# decrementing the pointer and then checking to see if its zero
	decl (%rdi)
	jz 0f # if it's zero, then we need to actually free it.
	ret
0:
	# Free the string if we have a string; if not, free the ast.
	cmp $KN_TAG_STRING, %al
	je kn_string_free
	jmp kn_ast_free
1:
	assert_is_one_of %al, KN_TAG_CONSTANT, KN_TAG_VARIABLE, KN_TAG_NUMBER
	ret