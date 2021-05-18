.include "valueh.s"
.include "debugh.s"

# Starts up knight.
.globl kn_startup
kn_startup:
	sub $8, %rsp
	call kn_function_startup
	add $8, %rsp
	jmp kn_env_startup

# Parses its given argument as a knight program, then executes it.
.globl kn_run
kn_run:
	push %rbx
	# Run the program.
	call kn_parse
	mov %rax, %rbx

.ifndef KN_RECKLESS
	# Check to see if the result is a valid expression.
	cmp $KN_UNDEFINED, %rax
	jne 1f
	diem "unable to parse stream"
1:
.endif
	# Run the parsed expression.
	mov %rax, %rdi
	call kn_value_run

	# Free the parsed value.
	mov %rbx, %rdi
	mov %rax, %rbx
	call kn_value_free

	# Restore the ran expression, then return.
	mov %rbx, %rax
	pop %rbx
	ret
