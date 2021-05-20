.include "valueh.s"
.include "stringh.s"
.include "debugh.s"

.text
.globl _main
_main:
	push %rbx

	# parse command line arguments; the return value is an owned string we can parse.
	call parse_commandline_args

	mov %rax, %rbx

	# Start up Knight.
	call kn_startup

	# Run the program.
	mov %rbx, %rdi
	call kn_run

	# we ignore the return value, as we're not going to free it.	
	pop %rbx
	xor %eax, %eax
	ret


# parse out all command line arguments
parse_commandline_args:
	cmp $3, %rdi
	jne usage
	mov 8(%rsi), %rdi

	mov (%rdi), %eax
	and $0x00ffffff, %eax

	# we're given `\0e-`
	cmp $0x00652d, %eax
	jne 0f
	mov 16(%rsi), %rdi
	jmp _strdup # gotta dup it so it's on a multiple of 8 boundary

0:
	# `\0f-`
	cmp $0x00662d, %eax
	jne usage
	mov 16(%rsi), %rdi
	# call read_file
	call die

usage:
	sub $8, %rsp
	mov (%rsi), %rsi
	lea usage_message(%rip), %rdi
	call _printf
	xor %edi, %edi
	call _exit

.text
usage_message:
	.asciz "usage: %s (-e 'expr' | -f filename)\n"
