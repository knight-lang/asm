.include "sharedh.s"
.include "valueh.s"
.include "stringh.s"

.data
source:
	/* .asciz "; = a 3 : O + 'a*4=' * a 4" */
	.asciz "'Hello world!'	a "
dump:
	.asciz "'%s'\n"
# 	.asciz "123'abdqw\"
# '"#\'
foo:
	.byte 0xaa,0xaa,0xaa,0xaa
	.byte 0x12
	.byte 0xbb
	.byte 'H', 'e'
	.byte 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l'
	.byte 'd', '!', 0
#	.byte 0xcc, 0xcc
#	.quad 6
#	.quad source
.text
_main:
	sub $8, %rsp
	lea source(%rip), %rdi
	call _strdup
	mov %rax, %rdi
	call parse

	VALUE_AS_STRING %rax
	STR_DEREF %rax, %rsi
	lea dump(%rip), %rdi
	call abort
	#xor %ecx, %ecx
	#movw 4(%rax), %cx
	#xor %ch, %ch
	jmp ddebug

.globl _main
_main1:
	sub $8, %rsp

# parse command-line
	call process_arguments
	mov %rax, %rdi
# parse program text
	call parse
	mov %rax, %rdi
	call ddebug
# execute the program
	call value_run
# free the returned value
	mov %rax, %rdi
	call value_free
	# todo: do we free the environment as well?

	add $8, %rsp
	xor %eax, %eax # successful return.
	ret

# parse command line arguments, returning a `char *`
# note that the returned value isn't necessarily owned.
process_arguments:
	lea source(%rip), %rdi; jmp _strdup # for debugging only

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
