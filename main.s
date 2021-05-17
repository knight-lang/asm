.globl _main
_main:
	sub $8, %rsp
	call parse_commandline_args
	mov %rax, %rdi
	call _puts
	add $8, %rsp
	xor %eax, %eax
	ret


parse_commandline_args:
	cmp $3, %rdi
	jne usage
	mov 8(%rsi), %rdi

	mov (%rdi), %eax
	and $0x00ffffff, %eax

	# `\0e-`
	cmp $0x00652d, %eax
	je given

	# `\0f-`
	cmp $0x00662d, %eax
	jne usage
	mov 16(%rsi), %rdi
	# call read_file
	call die
given:
	mov 16(%rsi), %rax
	ret

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
