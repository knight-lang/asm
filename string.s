.include "debugh.s"
.include "stringh.s"

# So for now, strings are literally just:
# struct kn_string { unsigned length, refcount; char *ptr; }
.globl kn_string_malloc
kn_string_malloc:
	push %rdi
	inc %rdi
	mov $1, %esi
	call _calloc
	mov %rax, %rdi
	pop %rsi
	# fallthrough

.globl kn_string_new_owned
kn_string_new_owned:
	# If a zero length is given, just load the empty string.
	sub $8, %rsp
	test %esi, %esi
	jz 0f

	# Allocate the string data
	push %rdi
	push %rsi
	mov $KN_STR_SIZE, %rdi
	call xmalloc
	pop %rsi
	pop %rcx
	add $8, %rsp

	# populate it.
	movl %esi, KN_STR_OFF_LEN(%rax) # length
	movl $1, KN_STR_OFF_RC(%rax) # refcount
	movl $KN_STR_FL_STRUCT_ALLOC, KN_STR_OFF_FLAGS(%rax) # no flags for now
	movq %rcx, KN_STR_OFF_ALLOC_PTR(%rax) # ptr
	ret
0:
	# We own the string so we need to free it.
	call _free
	add $8, %rsp
	lea kn_string_empty(%rip), %rax
	ret

.globl kn_string_new_borrowed
kn_string_new_borrowed:
	# todo: actually cache strings.
	cmp $KN_STR_EMBED_MAXLEN, %esi
	jle 0f
	# Too large to be embedded, so allocate one on the heap.
	push %rsi
	call _strndup
	mov %rax, %rdi
	pop %rsi
	jmp kn_string_new_owned

# embedded string.
0:
	sub $8, %rsp
	push %rdi
	push %rsi
	mov $KN_STR_SIZE, %rdi
	call xmalloc
	pop %rdx
	pop %rsi

	# populate it.
	movl %edx, KN_STR_OFF_LEN(%rax) # length
	movl $1, KN_STR_OFF_RC(%rax) # refcount
	movl $(KN_STR_FL_STRUCT_ALLOC + KN_STR_FL_EMBED), KN_STR_OFF_FLAGS(%rax)

	lea KN_STR_OFF_EMBED_START(%rax), %rdi
	movb $0, 1(%rdi, %rdx) # Set the trailing `\0`. +1 for the offset.
	mov %rax, (%rsp)
	call _memcpy
	pop %rax
	ret

.globl kn_string_free
kn_string_free:
	.ifndef NDEBUG
		cmpl $0, KN_STR_OFF_RC(%rdi)
		je 1f
		diem "`kn_string_free` called with nonzero refcount"
	1:
	.endif

	# Check to see if the struct is even allocated.
	mov KN_STR_OFF_FLAGS(%rdi), %ecx
	test $KN_STR_FL_STRUCT_ALLOC, %ecx
	jz 0f

	# If it's embedded, only free the string itself.
	test $KN_STR_FL_EMBED, %ecx
	jnz _free

	# free both the string and the pointer.
	push %rdi
	mov KN_STR_OFF_ALLOC_PTR(%rdi), %rdi
	call _free
	pop %rdi
	jmp _free
0:
	ret


.data
.align 16
.globl kn_string_empty
kn_string_empty:
	STATIC_STRING "", 0