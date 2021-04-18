.include "sharedh.s"

.data
source:
	/* .asciz "; = a 3 : O + 'a*4=' * a 4" */
	.asciz "123"
# 	.asciz "123'abdqw\"
# '"#\'

.globl _main
.text
_main:
	sub $8, %rsp

	call process_arguments
	mov %rax, %rdi
	call kn_parse
	mov %rax, %rdi
	call kn_value_run

	add $8, %rsp
	xor %eax, %eax
	ret

# parse command line arguments, returning a `char *`
# note that the returned value isn't necessarily owned.
process_arguments:
	cmp $3, %rdi
	jne usage
	mov 8(%rsi), %rdi
	mov (%rdi), %ax # move both the lower and upper parts in.

	cmp $'-', %al # must start with `-`
	jne usage
	cmp $'e', %ah # check to see if it's an expression
	jne 0f
	mov 16(%rsi), %rax # load the third argument and return it
	ret
0:
	mov 16(%rsi), %rdi # load the filename, as we're pros not going to usage.
	cmp $'f', %ah
	je readfile
usage:
	sub $8, %rsp
	lea usage_str(%rip), %rdi
	mov (%rsi), %rsi
	call _printf
	call die


readfile:
	jmp _abort # todo

.data:
usage_str:
	.asciz "usage: %s (-e 'expr' | -f file)\n"
