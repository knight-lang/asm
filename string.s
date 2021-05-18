.include "debugh.s"
.include "stringh.s"

# So for now, strings are literally just:
# struct kn_string { unsigned length, refcount; char *ptr; }
.globl kn_string_new_owned
kn_string_new_owned:
	sub $8, %rsp
	push %rbx
	push %r12

	mov %rdi, %rbx
	mov %rsi, %r12

	mov $16, %rdi
	call xmalloc

	mov %r12d, KN_STR_OFF_LEN(%rax) # length
	movl $1, KN_STR_OFF_RC(%rax) # refcount
	mov %rbx, KN_STR_OFF_PTR(%rax) # ptr
	pop %r12
	pop %rbx
	add $8, %rsp
	ret

.globl kn_string_new_borrowed
kn_string_new_borrowed:
	# todo: actually cache strings.
	push %rbx
	mov %rsi, %rbx # store the length
	call _strndup
	mov %rax, %rdi
	mov %rbx, %rsi
	pop %rbx
	jmp kn_string_new_owned


.globl kn_string_free
kn_string_free:
	push %rbx
	mov %rdi, %rbx

.ifndef NDEBUG
	cmpl $0, KN_STR_OFF_RC(%rdi)
	je 1f
	diem "`kn_string_free` called with nonzero refcount"
1:
.endif
	
	mov KN_STR_OFF_PTR(%rdi), %rdi
	call _free
	mov %rbx, %rdi
	pop %rbx
	jmp _free
