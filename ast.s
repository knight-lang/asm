.include "asth.s"
.include "valueh.s"
.include "functionh.s"
.include "debugh.s"

.equ KN_AST_FREE_CACHE_LEN, 32

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
	KN_FN_ARITY %rdi, %eax

	.ifndef NDEBUG
		cmp $KN_MAX_ARGC, %eax
		jl 0f
		diem "arity is above max arity?"
	0:
	.endif

	# Ok, let's see if we can find a cached ast.
	lea freed_asts(%rip), %rdx
	mov (%rdx, %rax, 8), %rdx

.kn_ast_alloc_find_occupied:
	mov (%rdx), %rcx
	add $8, %rdx

	# If we have nothing in this cache slot, try again.
	jrcxz .kn_ast_alloc_find_occupied

	# If we're at the end and haven't found a cached thing, we have to allocate ourselves.
	# note that allocated asts have an alignment of 1.
	cmp $1, %cl
	je .kn_ast_alloc_nocache

	# at this point we've found an occupied slot. let's populate it, zero the old slot and return it.
	movq $0, -8(%rdx) # -8 because we already added beforehand.
	mov %rcx, %rax
	incl KN_AST_OFF_RC(%rcx) # add one to the refcount so further uses can just yoink it.

	# note that `free` sets the rc to 1.
	mov %rdi, KN_AST_OFF_FN(%rcx)
	ret

.kn_ast_alloc_nocache:
	# whelp, we couldn't find a populated slot, gotta make our own.
	# note that %rax contains the arity.

	push %rdi # store the fn pointer so it'll persist.
	lea 16(,%rax,8), %rdi # 8 is value size. 4 for refcont, 4 for padding, 8 for fn pointer size.
	call xmalloc

	pop %rdi
	movl $1, KN_AST_OFF_RC(%rax)
	mov %rdi, KN_AST_OFF_FN(%rax)
	ret

.globl kn_ast_free
kn_ast_free:
	.ifndef NDEBUG
		cmpl $0, KN_AST_OFF_RC(%rdi)
		je 0f
		diem "`kn_ast_free` called with nonzero refcount"
	0:
	.endif

	push %rbx # 
	push %r12 # the ast itself
	push %r13 # pointer to the ast block

	mov %rdi, %r12

	# fetch the arity
	mov KN_AST_OFF_FN(%rdi), %rax
	KN_FN_ARITY %rax, %ebx

	# load the ast cache whilst we still have the full arity
	lea freed_asts(%rip), %rcx
	mov (%rcx, %rbx, 8), %r13

	# free all arguments
.kn_ast_free_args:
	dec %ebx
	js .kn_ast_free_find_cache_slot
	mov KN_AST_OFF_ARGS(%r12, %rbx, 8), %rdi
	call kn_value_free
	jmp .kn_ast_free_args

.kn_ast_free_find_cache_slot:
	# free all the stuff required for `kn_ast_free_args`, as we're going to just jump when done.
	mov %r12, %rdi
	mov %r13, %rax
	pop %r13
	pop %r12
	pop %rbx
0:
	# fetch the next slot
	mov (%rax), %rcx
	add $8, %rax

	# If the slot's empty, populate it.
	jrcxz .kn_ast_free_populate_slot

	# If we're not at the end, try again. (`1` is set in kn_ast_startup.)
	cmp $1, %rcx
	jne 0b
	jmp _free # we already prepopulated %rdi, so all we gotta do is call free.

.kn_ast_free_populate_slot:
	# looks like we found a slot, nice. Insert it into the slot and return
	mov %rdi, -8(%rax) # note that it's -8 as we increased earlier
	ret

.globl kn_ast_startup
kn_ast_startup:
	# Simply set the end of each AST thing to one, so we can check for it being just one.
	# it's `byte` because it starts as 1
	incb (freed_asts0 + 8 * KN_AST_FREE_CACHE_LEN)(%rip)
	incb (freed_asts1 + 8 * KN_AST_FREE_CACHE_LEN)(%rip)
	incb (freed_asts2 + 8 * KN_AST_FREE_CACHE_LEN)(%rip)
	incb (freed_asts3 + 8 * KN_AST_FREE_CACHE_LEN)(%rip)
	incb (freed_asts4 + 8 * KN_AST_FREE_CACHE_LEN)(%rip)
	ret

.bss
freed_asts0: .zero 8 * (KN_AST_FREE_CACHE_LEN + 1) # last one is set to 1 in kn_ast_startup
freed_asts1: .zero 8 * (KN_AST_FREE_CACHE_LEN + 1) # last one is set to 1 in kn_ast_startup
freed_asts2: .zero 8 * (KN_AST_FREE_CACHE_LEN + 1) # last one is set to 1 in kn_ast_startup
freed_asts3: .zero 8 * (KN_AST_FREE_CACHE_LEN + 1) # last one is set to 1 in kn_ast_startup
freed_asts4: .zero 8 * (KN_AST_FREE_CACHE_LEN + 1) # last one is set to 1 in kn_ast_startup

.data
freed_asts:
	.quad freed_asts0
	.quad freed_asts1
	.quad freed_asts2
	.quad freed_asts3
	.quad freed_asts4
