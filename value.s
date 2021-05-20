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
		_assert_one_of assert_kind_one_of_end_\@, \reg, \rest
		diem "oops: \reg is not one of: \rest"
	.endif
assert_kind_one_of_end_\@:
.endm

// # #include "env.h"    /* kn_variable, kn_variable_run */
// # #include "ast.h"    /* kn_ast, kn_ast_free, kn_ast_clone, kn_ast_run */
// # #include "value.h"  /* prototypes, bool, uint64_t, int64_t, kn_value, kn_number,
// #                        kn_boolean, KN_UNDEFINED, KN_NULL, KN_TRUE, KN_FALSE */
// # #include "string.h" /* kn_string, kn_string_clone, kn_string_free,
// #                        kn_string_deref, kn_string_length, KN_STRING_FL_STATIC,
// #                        KN_STRING_NEW_EMBED */
// # #include "custom.h" /* kn_custom, kn_custom_free, kn_custom_clone */
// # #include "shared.h" /* die */
// # 
// # #include <inttypes.h> /* PRId64 */
// # #include <stdlib.h>   /* free, NULL */
// # #include <assert.h>   /* assert */
// # #include <stdio.h>    /* printf */
// # #include <ctype.h>    /* isspace */
// # 
// # /*
// #  * The layout of `kn_value`:
// #  * 0...00000 - FALSE
// #  * 0...01000 - NULL
// #  * 0...10000 - TRUE
// #  * 0...11000 - undefined.
// #  * X...XX001 - 61-bit signed integer
// #  * X...XX010 - variable
// #  * X...XX011 - string
// #  * X...XX100 - function
// #  * X...XX110 - custom (only with `KN_CUSTOM`)
// #  * note all pointers are 8-bit-aligned.
// #  */
// # #define KN_SHIFT 3
// # #define KN_TAG_CONSTANT 0
// # #define KN_TAG_NUMBER 1
// # #define KN_TAG_VARIABLE 2
// # #define KN_TAG_STRING 3
// # #define KN_TAG_AST 4
// # 
// # #ifdef KN_CUSTOM
// # # define KN_TAG_CUSTOM 5
// # #endif /* KN_CUSTOM */
// # 
// # #define KN_TAG_MASK ((1 << KN_SHIFT) - 1)
// # #define KN_TAG(x) ((x) & KN_TAG_MASK)
// # #define KN_UNMASK(x) ((x) & ~KN_TAG_MASK)
// # 
// # kn_value kn_value_new_number(kn_number number) {
// # 	assert(number == (((kn_number) ((kn_value) number << KN_SHIFT)) >> KN_SHIFT));
// # 
// # 	return (((uint64_t) number) << KN_SHIFT) | KN_TAG_NUMBER;
// # }
// # 
// # kn_value kn_value_new_boolean(kn_boolean boolean) {
// # 	return ((uint64_t) boolean) << 4; // micro-optimizations hooray!
// # }
// # 
// # kn_value kn_value_new_string(struct kn_string *string) {
// # 	assert(string != NULL);
// # 
// # 	// a nonzero tag indicates a misaligned pointer
// # 	assert(KN_TAG((uint64_t) string) == 0);
// # 
// # 	return ((uint64_t) string) | KN_TAG_STRING;
// # }
// # 
// # kn_value kn_value_new_variable(struct kn_variable *value) {
// # 	assert(value != NULL);
// # 
// # 	// a nonzero tag indicates a misaligned pointer
// # 	assert(KN_TAG((uint64_t) value) == 0);
// # 
// # 	return ((uint64_t) value) | KN_TAG_VARIABLE;
// # }
// # 
// # kn_value kn_value_new_ast(struct kn_ast *ast) {
// # 	assert(ast != NULL);
// # 
// # 	// a nonzero tag indicates a misaligned pointer
// # 	assert(KN_TAG((uint64_t) ast) == 0);
// # 
// # 	return ((uint64_t) ast) | KN_TAG_AST;
// # }
// # 
// # #ifdef KN_CUSTOM
// # kn_value kn_value_new_custom(struct kn_custom *custom) {
// # 	assert(custom != NULL);
// # 	assert(custom->vtable != NULL);
// # 
// # 	// a nonzero tag indicates a misaligned pointer
// # 	assert(KN_TAG((uint64_t) custom) == 0);
// # 
// # 	return ((uint64_t) custom) | KN_TAG_CUSTOM;
// # }
// # #endif /* KN_CUSTOM */
// # 
// # bool kn_value_is_number(kn_value value) {
// # 	return (value & KN_TAG_NUMBER) == KN_TAG_NUMBER;
// # }
// # 
// # bool kn_value_is_boolean(kn_value value) {
// # 	return value == KN_FALSE || value == KN_TRUE;
// # }
// # 
// # bool kn_value_is_string(kn_value value) {
// # 	return (value & KN_TAG_STRING) == KN_TAG_STRING;
// # }
// # 
// # bool kn_value_is_variable(kn_value value) {
// # 	return (value & KN_TAG_VARIABLE) == KN_TAG_VARIABLE;
// # }
// # 
// # bool kn_value_is_ast(kn_value value) {
// # 	return (value & KN_TAG_AST) == KN_TAG_AST;
// # }
// # 
// # #ifdef KN_CUSTOM
// # bool kn_value_is_custom(kn_value value) {
// # 	return (value & KN_TAG_CUSTOM) == KN_TAG_CUSTOM;
// # }
// # #endif /* KN_CUSTOM */
// # 
// # kn_number kn_value_as_number(kn_value value) {
// # 	assert(kn_value_is_number(value));
// # 
// # 	return ((int64_t) value) >> KN_SHIFT;
// # }
// # 
// # kn_boolean kn_value_as_boolean(kn_value value) {
// # 	assert(kn_value_is_boolean(value));
// # 
// # 	return value != KN_FALSE;
// # }
// # 
// # struct kn_string *kn_value_as_string(kn_value value) {
// # 	assert(kn_value_is_string(value));
// # 
// # 	return (struct kn_string *) KN_UNMASK(value);
// # }
// # 
// # struct kn_variable *kn_value_as_variable(kn_value value) {
// # 	assert(kn_value_is_variable(value));
// # 
// # 	return (struct kn_variable *) KN_UNMASK(value);
// # }
// # 
// # struct kn_ast *kn_value_as_ast(kn_value value) {
// # 	assert(kn_value_is_ast(value));
// # 
// # 	return (struct kn_ast *) KN_UNMASK(value);
// # }
// # 
// # #ifdef KN_CUSTOM
// # struct kn_custom *kn_value_as_custom(kn_value value) {
// # 	assert(kn_value_is_custom(value));
// # 
// # 	return (struct kn_custom *) KN_UNMASK(value);
// # }
// # #endif /* KN_CUSTOM */
// # 
// # /*
// #  * Convert a string to a number, as per the knight specs.
// #  *
// #  * This means we strip all leading whitespace, and then an optional `-` or `+`
// #  * may appear (`+` is ignored, `-` indicates a negative number). Then as many
// #  * digits as possible are read.
// #  *
// #  * Note that we can't use `strtoll`, as we can't be positive that `kn_number`
// #  * is actually a `long long`.
// #  */
// # static kn_number string_to_number(struct kn_string *string) {
// # 	kn_number ret = 0;
// # 	const char *ptr = kn_string_deref(string);
// # 
// # 	// strip leading whitespace.
// # 	while (KN_UNLIKELY(isspace(*ptr)))
// # 		ptr++;
// # 
// # 	bool is_neg = *ptr == '-';
// # 
// # 	// remove leading `-` or `+`s, if they exist.
// # 	#if (is_neg || *ptr == '+')
// # 		++ptr;
// # 
// # 	// only digits are `<= 9` when a literal `0` char is subtracted from them.
// # 	unsigned char cur; // be explicit about wraparound.
// # 	while ((cur = *ptr++ - '0') <= 9)
// # 		ret = ret * 10 + cur;
// # 
// # 	return is_neg ? -ret : ret;
// # }
// # 

kn_value_to_number_run_var:
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
	je kn_value_to_number_run_var

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
	imul $KN_STR_SIZE, %rax
	lea kn_value_string_reprs(%rip), %rdi
	add %rdi, %rax
	incl (%rax) # gotta increase refcount so we can free it later.
	ret
.kn_value_to_string_number:
	assert_is_one_of %cl, KN_TAG_NUMBER
	sar $3, %rdi
	push %rbx
	mov %rdi, %rbx
	# TODO optimize this more
	mov $22, %rdi
	call xmalloc
	mov %rbx, %rdx
	mov %rax, %rdi
	mov %rax, %rbx
	lea kn_value_string_sprintf(%rip), %rsi
	call _sprintf
	mov %rbx, %rdi
	call _strlen
	mov %rax, %rsi
	mov %rbx, %rdi
	pop %rbx
	jmp kn_string_new_owned

.pushsection .data, ""
kn_value_string_sprintf:        .asciz "%lld"
kn_value_string_reprs_true:     .asciz "true"
kn_value_string_reprs_false:    .asciz "false"
kn_value_string_reprs_null:     .asciz "null"
kn_value_string_reprs_zero:     .asciz "0"
kn_value_string_reprs_one:      .asciz "1"
kn_value_string_reprs_two:      .asciz "2"
kn_value_string_reprs:
	.long -2147483648
	.long 5
	.quad kn_value_string_reprs_false
	.long -2147483648
	.long 1
	.quad kn_value_string_reprs_zero
	.zero KN_STR_SIZE*6
	.long -2147483648
	.long 4
	.quad kn_value_string_reprs_null
	.long -2147483648
	.long 1
	.quad kn_value_string_reprs_one
	.zero KN_STR_SIZE*6
	.long -2147483648
	.long 4
	.quad kn_value_string_reprs_true
	.long -2147483648
	.long 1
	.quad kn_value_string_reprs_two
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
	ret
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

// # kn_boolean kn_value_to_boolean(kn_value value) {
// # 	assert(value != KN_UNDEFINED);
// # 
// # 	switch (KN_TAG(value)) {
// # 	case KN_TAG_CONSTANT:
// # 		return value == KN_TRUE;
// # 
// # 	case KN_TAG_NUMBER:
// # 		return value != KN_TAG_NUMBER;
// # 
// # 	case KN_TAG_STRING:
// # 		return kn_string_length(kn_value_as_string(value)) != 0;
// # 
// # #ifdef KN_CUSTOM
// # 	case KN_TAG_CUSTOM: {
// # 		struct kn_custom *custom = kn_value_as_custom(value);
// # 
// # 		#if (custom->vtable->to_boolean != NULL)
// # 			return custom->vtable->to_boolean(custom->data);
// # 		// otherwise, fallthrough
// # 	}
// # #endif /* KN_CUSTOM */
// # 
// # 	case KN_TAG_AST:
// # 	case KN_TAG_VARIABLE: {
// # 		// simply execute the value and call this function again.
// # 		kn_value ran = kn_value_run(value);
// # 		kn_boolean ret = kn_value_to_boolean(ran);
// # 		kn_value_free(ran);
// # 
// # 		return ret;
// # 	}
// # 
// # 	default:
// # 		KN_UNREACHABLE();
// # 	}
// # }
// # 
// # static struct kn_string *number_to_string(kn_number num) {
// # 	// note that `22` is the length of `-UINT64_MIN`, which is 21 characters
// # 	// long + the trailing `\0`.
// # 	static char buf[22];
// # 	static struct kn_string number_string = { .flags = KN_STRING_FL_STATIC };
// # 
// # 	// should have been checked earlier.
// # 	assert(num != 0 && num != 1);
// # 
// # 	// initialize ptr to the end of the buffer minus one, as the last is
// # 	// the nul terminator.
// # 	char *ptr = &buf[sizeof(buf) - 1];
// # 	bool is_neg = num < 0;
// # 
// # 	#if (is_neg)
// # 		num *= -1;
// # 
// # 	do {
// # 		*--ptr = '0' + (num % 10);
// # 	} while (num /= 10);
// # 
// # 	#if (is_neg)
// # 		*--ptr = '-';
// # 
// # 	number_string.alloc.str = ptr;
// # 	number_string.alloc.length = &buf[sizeof(buf) - 1] - ptr;
// # 
// # 	return &number_string;
// # }
// # 
// # struct kn_string *kn_value_to_string(kn_value value) {
// # 	// static, embedded strings so we don't have to allocate for known strings.
// # 	static struct kn_string builtin_strings[KN_TRUE + 1] = {
// # 		[KN_FALSE] = KN_STRING_NEW_EMBED("false"),
// # 		[KN_TAG_NUMBER] = KN_STRING_NEW_EMBED("0"),
// # 		[KN_NULL] = KN_STRING_NEW_EMBED("null"),
// # 		[KN_TRUE] = KN_STRING_NEW_EMBED("true"),
// # 		[(((uint64_t) 1) << KN_SHIFT) | KN_TAG_NUMBER] = KN_STRING_NEW_EMBED("1"),
// # 	};
// # 
// # 	assert(value != KN_UNDEFINED);
// # 
// # 	#if (KN_UNLIKELY(value <= KN_TRUE))
// # 		return &builtin_strings[value];
// # 
// # 	switch (KN_EXPECT(KN_TAG(value), KN_TAG_STRING)) {
// # 	case KN_TAG_NUMBER:
// # 		return number_to_string(kn_value_as_number(value));
// # 
// # 	case KN_TAG_STRING:
// # 		return kn_string_clone(kn_value_as_string(value));
// # 
// # #ifdef KN_CUSTOM
// # 	case KN_TAG_CUSTOM: {
// # 		struct kn_custom *custom = kn_value_as_custom(value);
// # 
// # 		#if (custom->vtable->to_string != NULL)
// # 			return custom->vtable->to_string(custom->data);
// # 		// otherwise, fallthrough
// # 	}
// # #endif /* KN_CUSTOM */
// # 
// # 	case KN_TAG_AST:
// # 	case KN_TAG_VARIABLE: {
// # 		// simply execute the value and call this function again.
// # 		kn_value ran = kn_value_run(value);
// # 		struct kn_string *ret = kn_value_to_string(ran);
// # 		kn_value_free(ran);
// # 
// # 		return ret;
// # 	}
// # 
// # 	case KN_TAG_CONSTANT:
// # 	default:
// # 		KN_UNREACHABLE();
// # 	}
// # }
// # 

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

.globl kn_value_clone
kn_value_clone:
	# Find the tag, as well as prepare for returning the passed value.
	mov %rdi, %rax
	mov %dil, %cl
	and $0b111, %cl

	# If it's a constant, number, or variable, just return it as is.
	cmp $2, %cl
	jbe 0f

	# Both strings and asts have the refcount in the same position, so cloning them
	# is simply incrementing a memory index
	assert_is_one_of %cl, KN_TAG_STRING, KN_TAG_AST
	and $~0b111, %dil
	incl (%rdi)
	.ifndef NDEBUG
		ret # simply return so we don't fall into the assertion down below
	.endif
0:
	# Make sure it's actually a const, number, or variable
	assert_is_one_of %cl, KN_TAG_CONSTANT, KN_TAG_VARIABLE, KN_TAG_NUMBER

	# return the passed value.
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