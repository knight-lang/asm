.include "debugh.s"
.include "valueh.s"
.include "envh.s"

.equ KN_ENV_NBUCKETS, 65536
.equ KN_ENV_CAPACITY, 256

.globl kn_env_startup
kn_env_startup:
	sub $8, %rsp
	push %rbx
	push %r12
	lea kn_env_map(%rip), %rbx
	mov $KN_ENV_NBUCKETS, %r12d
0:
	# Allocate enough pointers for the bucket
	mov $(KN_ENV_CAPACITY * 8), %rdi
	call xmalloc

	# Store the pointer into the map.
	mov %rax, (%rbx)
	# Set the initial pointer to zero.
	movq $0, (%rax)

	add $8, %rbx
	dec %r12d
	test %r12d, %r12d
	jnz 0b

	pop %r12
	pop %rbx
	add $8, %rsp
	ret

	# todo
.globl kn_env_fetch
kn_env_fetch:
	# Save our previous values.
	push %rbx # variable name
	push %r12 # variable length
	push %r13 # next variable index (ie bucket segment pointer)
	push %r14 # current variable
	sub $8, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12

	# Find the hash bucket
	call kn_hash
	and $(KN_ENV_NBUCKETS - 1), %rax
	imul $8, %rax
	lea kn_env_map(%rip), %r13
	add %rax, %r13
	mov (%r13), %r13

# try to find the variable within that hash bucket.
0:
	# Check to see if the current variable pointer is NULL. if it is, make a new variable.
	mov (%r13), %r14
	test %r14, %r14
	jz kn_env_fetch_new_variable

	add $8, %r13 # add 8 here so that the `new_variable` is in the right spot, but `jnz 0b` is too.

	# Otherwise, check to see if the variable and the input are the same
	mov KN_VAR_OFF_NAME(%r14), %rdi
	mov %rbx, %rsi
	mov %r12, %rdx
	call _strncmp
	test %eax, %eax
	jnz 0b

	# We've found the right variable! huzzah!
	KN_NEW_VARIABLE %r14, %rax
done:
	add $8, %rsp
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	ret

# We need to make a new variable.
kn_env_fetch_new_variable:
	# Duplicate the variable name
	mov %rbx, %rdi
	mov %r12, %rsi
	call _strndup
	mov %rax, %rbx

	# Allocate and assign the new variable
	mov $KN_VAR_SIZE, %rdi
	call xmalloc

	mov %rbx, KN_VAR_OFF_NAME(%rax)
	movq $KN_UNDEFINED, KN_VAR_OFF_VAL(%rax)

	# move it into the right spot
	mov %rax, (%r13)
	# set the next variable as null
	movq $0, 8(%r13)

	# done!
	or $2, %al
	jmp done

.bss
.align 16
kn_env_map:
	.zero KN_ENV_NBUCKETS * 8
