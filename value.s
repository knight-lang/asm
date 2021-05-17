.include "debugh.s"
.include "valueh.s"

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
// # kn_number kn_value_to_number(kn_value value) {
// # 	assert(value != KN_UNDEFINED);
// # 
// # 	switch (KN_EXPECT(KN_TAG(value), KN_TAG_NUMBER)) {
// # 	case KN_TAG_NUMBER:
// # 		return kn_value_as_number(value);
// # 
// # 	case KN_TAG_CONSTANT:
// # 		return value == KN_TRUE;
// # 
// # 	case KN_TAG_STRING:
// # 		return string_to_number(kn_value_as_string(value));
// # 
// # #ifdef KN_CUSTOM
// # 	case KN_TAG_CUSTOM: {
// # 		struct kn_custom *custom = kn_value_as_custom(value);
// # 
// # 		#if (custom->vtable->to_number != NULL)
// # 			return custom->vtable->to_number(custom->data);
// # 		// otherwise, fallthrough
// # 	}
// # #endif /* KN_CUSTOM */
// # 
// # 	case KN_TAG_VARIABLE:
// # 	case KN_TAG_AST: {
// # 		// simply execute the value and call this function again.
// # 		kn_value ran = kn_value_run(value);
// # 		kn_number ret = kn_value_to_number(ran);
// # 		kn_value_free(ran);
// # 		return ret;
// # 	}
// # 
// # 	default:
// # 		KN_UNREACHABLE();
// # 	}
// # }
// # 
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

.globl kn_value_dump
kn_value_dump:
	push %rbx
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

	lea kn_value_dump_string(%rip), %rdi
	jmp 1f
0:
	call ddebug
	diem "unknown type to dump"
1:
	call _printf
	mov %rbx, %rax
	pop %rbx
	ret
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

.popsection

// # void kn_value_dump(kn_value value) {
// # 	switch (KN_TAG(value)) {
// # 	case KN_TAG_CONSTANT:
// # 		switch (value) {
// # 		case KN_TRUE:  printf("Boolean(true)"); return;
// # 		case KN_FALSE: printf("Boolean(false)"); return;
// # 		case KN_NULL:  printf("Null()"); return;
// # #ifndef NDEBUG // we dump undefined only for debugging.
// # 		case KN_UNDEFINED: printf("<KN_UNDEFINED>"); return;
// # #endif /* !NDEBUG */
// # 
// # 		default:
// # 			KN_UNREACHABLE();
// # 		}
// # 
// # 	case KN_TAG_NUMBER:
// # 		printf("Number(%" PRId64 ")", kn_value_as_number(value));
// # 		return;
// # 
// # 	case KN_TAG_STRING:
// # 		printf("String(%s)", kn_string_deref(kn_value_as_string(value)));
// # 		return;
// # 
// # 	case KN_TAG_VARIABLE:
// # 		printf("Identifier(%s)", kn_value_as_variable(value)->name);
// # 		return;
// # 
// # #ifdef KN_CUSTOM
// # 	case KN_TAG_CUSTOM: {
// # 		struct kn_custom *custom = kn_value_as_custom(value);
// # 
// # 		#if (custom->vtable->dump != NULL) {
// # 			custom->vtable->dump(custom->data);
// # 		} else {
// # 			printf(
// # 				"Custom(%p, %p)", (void *) custom->data, (void *) custom->vtable
// # 			);
// # 		}
// # 
// # 		return;
// # 	}
// # #endif /* KN_CUSTOM */
// # 
// # 	case KN_TAG_AST: {
// # 		struct kn_ast *ast = kn_value_as_ast(value);
// # 
// # 		printf("Function(%s", ast->func->name);
// # 
// # 		for (size_t i = 0; i < ast->func->arity; ++i) {
// # 			printf(", ");
// # 			kn_value_dump(ast->args[i]);
// # 		}
// # 
// # 		printf(")");
// # 		return;
// # 	}
// # 
// # 	default:
// # 		KN_UNREACHABLE();
// # 	}
// # }
// # 
// # kn_value kn_value_run(kn_value value) {
// # 	assert(value != KN_UNDEFINED);
// # 
// # 	switch (KN_EXPECT(KN_TAG(value), KN_TAG_AST)) {
// # 	case KN_TAG_AST:
// # 		return kn_ast_run(kn_value_as_ast(value));
// # 
// # 	case KN_TAG_VARIABLE:
// # 		return kn_variable_run(kn_value_as_variable(value));
// # 
// # 	case KN_TAG_STRING:
// # 		return kn_value_new_string(kn_string_clone(kn_value_as_string(value)));
// # 
// # 	case KN_TAG_NUMBER:
// # 	case KN_TAG_CONSTANT:
// # 		return value;
// # 
// # #ifdef KN_CUSTOM
// # 	case KN_TAG_CUSTOM: {
// # 		struct kn_custom *custom = kn_value_as_custom(value);
// # 
// # 		#if (custom->vtable->run != NULL) {
// # 			return custom->vtable->run(custom->data);
// # 		} else {
// # 			return kn_value_clone(value);
// # 		}
// # 	}
// # #endif /* KN_CUSTOM */
// # 
// # 	default:
// # 		KN_UNREACHABLE();
// # 	}
// # }
// # 

.globl kn_value_run
kn_value_run:
	jmp ddebug

.macro _assert_one_of dst:req, reg:req, kind="", rest1:vararg
    .ifnb \kind
	cmp $\kind, \reg
	je \dst
	_assert_one_of \dst, \reg, \rest1
    .endif
.endm

.macro assert_kind_one_of reg:req, rest:vararg
    .ifdef NDEBUG
	.exitm
    .endif 

	_assert_one_of assert_kind_one_of_end_\@, \reg, \rest
	diem "oops: \reg is not one of: \rest"
assert_kind_one_of_end_\@:
.endm


.globl kn_value_clone
kn_value_clone:
	# Find the tag, as well as prepare for returning the passed value.
	mov %rdi, %rax
	mov %dil, %cl
	and $0b111, %cl

	# If it's a constant, number, or variable, just return it as is.
	cmp $2, %cl
	jg 0f

	# Make sure it's actually a const, number, or variable
	assert_kind_one_of %cl, KN_TAG_CONSTANT, KN_TAG_VARIABLE, KN_TAG_NUMBER

	# return the passed value.
	ret

	# Both strings and asts have the refcount in the same position, so cloning them
	# is simply incrementing a memory index
0:
	assert_kind_one_of %cl, KN_TAG_STRING, KN_TAG_AST

	# Increment the `int` at offset four.
	and $~0b111, %dil
	incl 4(%rdi)
	ret

.globl kn_value_free
kn_value_free:
	# Find the tag
	mov %dil, %al
	and $0b111, %al

	# If it's a constant, number, or variable, just ignore it.
	cmp $2, %al
	jg 0f
	assert_kind_one_of %al, KN_TAG_CONSTANT, KN_TAG_VARIABLE, KN_TAG_NUMBER
	ret

	# either free a string or ast.
0:
	assert_kind_one_of %al, KN_TAG_STRING, KN_TAG_AST
	# Remove the tag for when we call the child functions.
	and $~0b111, %dil

	# Free the string if we have a string; if not, free the ast.
	cmp $KN_TAG_STRING, %al
	je kn_string_free
	jmp kn_ast_free
