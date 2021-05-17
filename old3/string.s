.include "stringh.s"


.macro allocate_string flags=$STR_FL_STRUCT_ALLOC
	mov $STR_SIZE, %rdi
	call xmalloc
	movw $1, STR_OFFSET_refcount(%rax)
	movb \flags, STR_OFFSET_flags(%rax)
.endm

.globl string_alloc
string_alloc:
	push %rbx
	# allocate string
	mov %rdi, %rbx # store length
	mov $STR_SIZE, %rdi
	call xmalloc
	# populate refcount
	movw $1, STR_OFFSET_refcount(%rax) # we always start with 1 refcount
	# check to see if we're embeddable
	cmp $STR_MAX_EMBED_LENGTH, %rsi
	jg 0f
	# populate embedded string
	movb $(STR_FL_STRUCT_ALLOC | STR_FL_EMBED), STR_OFFSET_flags(%rax)
	movb %bl, STR_OFFSET_embedded_length(%rax)
	pop %rbx
	ret
0:
	# populate heap alloacted string
	movb $STR_FL_STRUCT_ALLOC, STR_OFFSET_flags(%rax)
	movq %rbx, STR_OFFSET_allocated_length(%rax)
	pop %rbx
	ret

.globl string_cache
string_cache:
	jmp die

.globl string_new_owned
string_new_owned:
	jmp die

.globl string_new_borrowed
string_new_borrowed:
	# TODO: in the future, we should actually cache
	sub $8, %rsp
	push %rbx
	push %r12
	mov %rdi, %rbx # store string
	mov %rsi, %r12 # store length
	string_alloc
	mov 
0:
	mov %rsi, %r12 # preserve length
	call _strndup
	mov %rax, %rbx
	mov $STR_SIZE, %rdi
	call xmalloc
	movw $0, (%rax)
	movb $STR_FL_STRUCT_ALLOC, 4(%rax) # only flag is allocation (for now).
	mov %r12, 8(%rax)
	mov %rbx, 16(%rax)
	pop %r12
	pop %rbx
	add $8, %rsp
	ret


.globl string_cache_lookup
string_cache_lookup:
	jmp die

.globl string_clone
string_clone:
	jmp die

.globl string_clone_static
string_clone_static:
	jmp die

.globl string_free
string_free:
	jmp die