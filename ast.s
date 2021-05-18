.include "asth.s"
.include "valueh.s"
.include "functionh.s"

# AST LAYOUT:
#
# struct Ast {
# 	int refcount;
# 	int _padding;
# 	function_pointer fn;
# 	kn_value args[]
# }

# Allocates memory for a new ast with the given length.
# it takes one argument, which is the function pointer.
.globl kn_ast_alloc
kn_ast_alloc:
	push %rbx
	mov %rdi, %rbx

	KN_FN_ARITY %rdi, %rax
	imul $KN_VALUE_SIZE, %rax # this and the folowing one can probably be reduced to a single lea
	add $16, %rax # 4 for refcount, 4 for padding, 8 for size of a function pointer

	call xmalloc

	movl $1, KN_AST_OFF_RC(%rax)
	mov %rbx, KN_AST_OFF_FN(%rax)
	mov KN_AST_OFF_FN(%rax), %rbx
	pop %rbx
	ret

.globl kn_ast_free
kn_ast_free:
	// todo free asts
	ret
