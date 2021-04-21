.include "valueh.s"
#.include "debugh.s"

.equ stream_reg, %r12

.macro peek where:req
	movzb (stream_reg), \where
.endm

.macro advance
	inc stream_reg
.endm

.macro unadvance
	dec stream_reg
.endm

.globl parse
parse:
	push stream_reg
	mov %rdi, stream_reg
handle_stream:
	peek %eax
	advance
	lea (,%rax,8), %rcx
	add parse_table(%rip), %rcx
	jmp *(%rcx)

done_parsing:
	mov stream_reg, %rdi /* this is used by kn_value_new_function */
	pop stream_reg
	ret

.equ whitespace, handle_stream
/* todo: parse whitespace characters before going back, as consecutive whitespace is likely */

/* parse a comment out */
comment:
	peek %eax
	advance
	cmp $'\n', %al      /* check to see if we're at end of line */
	setne %al           /* if we are, set the currently read thing to `0` */
	cmp $0, %al         /* check if `%al` is zero (ie EOS or `\n` which was replaced) */
	jne comment         /* nonzero = not end of comment */
	jmp handle_stream   /* zero = end of comment */

integer:
	lea -'0'(%rax), %rax
	lea done_parsing(%rip), %rcx
	push %rcx
0:
	peek %ecx
	sub $'0', %ecx
	cmp $9, %rcx
	jg 1f                /* if it's not a digit, then stop */
	advance
	imul $10, %rax
	add %rcx, %rax
	jmp 0b
1:
	NEW_NUMBER %rax
	ret

identifier:
	mov -1(stream_reg), %rdi
0: # parse the identifier
	peek %eax
	advance
	sub $'0', %al
	cmp $9, %al
	jle 0b
	cmp $('_' - '0'), %al
	jz 0b 
	sub $('a' - '0'), %al
	cmp $('z' - 'a'), %al
	jle 0b
# fetch the variable
	mov stream_reg, %rsi
	sub %rdi, %rsi
	dec %rsi
	call env_fetch
# convert it to a string
	NEW_VARIABLE %rax
	jmp done_parsing

string:
	mov stream_reg, %rdi # keep string start
0: # parse string
	peek %ecx
	advance
	test %cl, %cl
	je string_missing_quote
	cmp %al, %cl
	jne 0b

# find length of string
 	mov stream_reg, %rsi
 	sub %rdi, %rsi
 	dec %rsi
# allocate the string and return
 	call string_new_borrowed
 	NEW_STRING %rax
 	jmp done_parsing

string_missing_quote:
	dec %rdi # todo: can this be lea?
	mov %rdi, %rsi
	lea unterminated_quote_msg(%rip), %rdi
	call abort


# 	sub $32, %rsp
# 	mov stream_reg, (%rsp) /* store quote start */
# 0:
# 	peek %ecx
# 	advance
# 	cmp $0, %ecx
# 	je 1f
# 	cmp %al, %cl
# 	jne 0b
# 
# 	/* find the length of the string */
# 	mov stream_reg, %rdi
# 	sub (%rsp), %rdi
# 	dec %rdi
# 	mov %rdi, 8(%rsp) /* preserve length */
# 
# 	/* allocate it and dereference it */
# 	call kn_str_alloc
# 	mov %rax, 16(%rsp)
# 	mov %rax, %rdi
# 	call kn_str_deref
# 
# 	/* populate the string */
# 	mov %rax, %rdi    /* the string we jsut allocated */
# 	mov (%rsp), %rsi  /* quote start */
# 	mov 8(%rsp), %rdx /* length */
# 
# 	/* set trailing NUL */
# 	mov %rdi, %rax
# 	add %rdx, %rax
# 	movb $0, (%rax)
	# 
# 	call _memcpy
# 
# 	/* return */
# 	mov 16(%rsp), %rax /* load the allocated string */
# 	add $32, %rsp
# 
# 	kn_vl_new_string %rax
# 	jmp done_parsing



literal_false:
	xor %eax, %eax
	jmp strip_literal
literal_true:
	mov $TRUE, %eax
	jmp strip_literal
literal_null:
	mov $NULL, %eax
	# fallthrough
strip_literal:
	peek %ecx
	sub $'A', %cl
	cmp $('Z' - 'A'), %cl
	jg done_parsing
	advance
	jmp strip_literal



function_not: 
function_mod: 
function_and: 
function_mul: 
function_add: 
function_sub: 
function_div: 
function_then: 
function_lth: 
function_assign: 
function_gth: 
function_eql: 
function_pow: 
function_system: 
function_or: 

function_block: 
function_debug: 
function_call: 
function_eval: 
function_get: 
function_length: 
function_output: 
function_prompt: 
function_quit: 
function_random: 
function_set: 
function_while: 
function_if: 
	jmp ddebug
# 	sub $32, %rsp
# 	mov stream_reg, (%rsp) /* store quote start */
# 0:
# 	peek %ecx
# 	advance
# 	cmp $0, %ecx
# 	je 1f
# 	cmp %al, %cl
# 	jne 0b
# 
# 	/* find the length of the string */
# 	mov stream_reg, %rdi
# 	sub (%rsp), %rdi
# 	dec %rdi
# 	mov %rdi, 8(%rsp) /* preserve length */
# 
# 	/* allocate it and dereference it */
# 	call kn_str_alloc
# 	mov %rax, 16(%rsp)
# 	mov %rax, %rdi
# 	call kn_str_deref
# 
# 	/* populate the string */
# 	mov %rax, %rdi    /* the string we jsut allocated */
# 	mov (%rsp), %rsi  /* quote start */
# 	mov 8(%rsp), %rdx /* length */
# 
# 	/* set trailing NUL */
# 	mov %rdi, %rax
# 	add %rdx, %rax
# 	movb $0, (%rax)
	# 
# 	call _memcpy
# 
# 	/* return */
# 	mov 16(%rsp), %rax /* load the allocated string */
# 	add $32, %rsp
# 
# 	kn_vl_new_string %rax
# 	jmp done_parsing
# 
# 1: // An unterminated quote was encountered.
# 	dec %rdi
# 	mov %rdi, %rsi
# 	lea unterminated_quote_msg(%rip), %rdi
# 	jmp abort
# 
# .macro decl_sym_function label:req
# function_\label:
# 	lea kn_func_\label(%rip), %rdi
# 	jmp function
# .endm
# 
# .macro decl_kw_function label:req
# function_\label:
# 	lea kn_func_\label(%rip), %rdi
# 	jmp keyword_function
# .endm
# 
# decl_sym_function not
# decl_sym_function mod
# decl_sym_function and
# decl_sym_function mul
# decl_sym_function add
# decl_sym_function sub
# decl_sym_function div
# decl_sym_function then
# decl_sym_function lth
# decl_sym_function assign
# decl_sym_function gth
# decl_sym_function eql
# decl_sym_function pow
# decl_sym_function system
# decl_sym_function or
# 
# decl_kw_function block
# decl_kw_function debug
# decl_kw_function call
# decl_kw_function eval
# decl_kw_function get
# decl_kw_function length
# decl_kw_function output
# decl_kw_function prompt
# decl_kw_function quit
# decl_kw_function random
# decl_kw_function set
# decl_kw_function while
# 
# function_if: // optimization because if is used often.
# 	lea kn_func_if(%rip), %rdi
# keyword_function:
# 	peek %eax
# 	advance
# 	sub $'A', %al
# 	cmp $('Z' - 'A'), %rax
# 	jle keyword_function
# 	unadvance
# function:
# 	lea done_parsing(%rip), %rax
# 	push %rax
# 	jmp kn_value_new_function
# 

/* A token was expected, but could not be found. */
expected_token:
	lea expected_token_fmt(%rip), %rdi
	jmp abort

/* an unknown character was character was given. */
invalid:
	lea invalid_token_fmt(%rip), %rdi
	mov %rax, %rsi
	jmp abort

.data
expected_token_fmt:
	.asciz "expected a token.\n"
invalid_token_fmt:
	.asciz "unknown token character '%1$c' (0x%1$x).\n"
unterminated_quote_msg:
	.asciz "unterminated quote encountered: %s\n"
parse_table:
	.quad 	parse_table+8
	.quad 	expected_token   /* \x00 */
	.quad 	invalid          /* \x01 */
	.quad 	invalid          /* \x02 */
	.quad 	invalid          /* \x03 */
	.quad 	invalid          /* \x04 */
	.quad 	invalid          /* \x05 */
	.quad 	invalid          /* \x06 */
	.quad 	invalid          /* \x07 */
	.quad 	invalid          /* \x08 */
	.quad 	whitespace       /* \t   */
	.quad 	whitespace       /* \n   */
	.quad 	whitespace       /* \v   */
	.quad 	whitespace       /* \f   */
	.quad 	whitespace       /* \r   */
	.quad 	invalid          /* \x0E */
	.quad 	invalid          /* \x0F */
	.quad 	invalid          /* \x10 */
	.quad 	invalid          /* \x11 */
	.quad 	invalid          /* \x12 */
	.quad 	invalid          /* \x13 */
	.quad 	invalid          /* \x14 */
	.quad 	invalid          /* \x15 */
	.quad 	invalid          /* \x16 */
	.quad 	invalid          /* \x17 */
	.quad 	invalid          /* \x18 */
	.quad 	invalid          /* \x19 */
	.quad 	invalid          /* \x1A */
	.quad 	invalid          /* \x1B */
	.quad 	invalid          /* \x1C */
	.quad 	invalid          /* \x1D */
	.quad 	invalid          /* \x1E */
	.quad 	invalid          /* \x1F */
	.quad 	whitespace       /* <space> */
	.quad 	function_not     /* !    */
	.quad 	string           /* "    */
	.quad 	comment          /* #    */
	.quad 	invalid          /* $    */
	.quad 	function_mod     /* %    */
	.quad 	function_and     /* &    */
	.quad 	string           /* '    */
	.quad 	whitespace       /* (    */
	.quad 	whitespace       /* )    */
	.quad 	function_mul     /* *    */
	.quad 	function_add     /* +    */
	.quad 	invalid          /* ,    */
	.quad 	function_sub     /* -    */
	.quad 	invalid          /* .    */
	.quad 	function_div     /* /    */
	.quad 	integer          /* 0    */
	.quad 	integer          /* 1    */
	.quad 	integer          /* 2    */
	.quad 	integer          /* 3    */
	.quad 	integer          /* 4    */
	.quad 	integer          /* 5    */
	.quad 	integer          /* 6    */
	.quad 	integer          /* 7    */
	.quad 	integer          /* 8    */
	.quad 	integer          /* 9    */
	.quad 	whitespace       /* :    */
	.quad 	function_then    /* ;    */
	.quad 	function_lth     /* <    */
	.quad 	function_assign  /* =    */
	.quad 	function_gth     /* >    */
	.quad 	function_eql     /* ?    */
	.quad 	invalid          /* @    */
	.quad 	invalid          /* A    */
	.quad 	function_block   /* B    */
	.quad 	function_call    /* C    */
	.quad 	function_debug   /* D    */
	.quad 	function_eval    /* E    */
	.quad 	literal_false    /* F    */
	.quad 	function_get     /* G    */
	.quad 	invalid          /* H    */
	.quad 	function_if      /* I    */
	.quad 	invalid          /* J    */
	.quad 	invalid          /* K    */
	.quad 	function_length  /* L    */
	.quad 	invalid          /* M    */
	.quad 	literal_null     /* N    */
	.quad 	function_output  /* O    */
	.quad 	function_prompt  /* P    */
	.quad 	function_quit    /* Q    */
	.quad 	function_random  /* R    */
	.quad 	function_set     /* S    */
	.quad 	literal_true     /* T    */
	.quad 	invalid          /* U    */
	.quad 	invalid          /* V    */
	.quad 	function_while   /* W    */
	.quad 	invalid          /* X    */
	.quad 	invalid          /* Y    */
	.quad 	invalid          /* Z    */
	.quad 	whitespace       /* [    */
	.quad 	invalid          /* \    */
	.quad 	whitespace       /* ]    */
	.quad 	function_pow     /* ^    */
	.quad 	identifier       /* _    */
	.quad 	function_system  /* `    */
	.quad 	identifier       /* a    */
	.quad 	identifier       /* b    */
	.quad 	identifier       /* c    */
	.quad 	identifier       /* d    */
	.quad 	identifier       /* e    */
	.quad 	identifier       /* f    */
	.quad 	identifier       /* g    */
	.quad 	identifier       /* h    */
	.quad 	identifier       /* i    */
	.quad 	identifier       /* j    */
	.quad 	identifier       /* k    */
	.quad 	identifier       /* l    */
	.quad 	identifier       /* m    */
	.quad 	identifier       /* n    */
	.quad 	identifier       /* o    */
	.quad 	identifier       /* p    */
	.quad 	identifier       /* q    */
	.quad 	identifier       /* r    */
	.quad 	identifier       /* s    */
	.quad 	identifier       /* t    */
	.quad 	identifier       /* u    */
	.quad 	identifier       /* v    */
	.quad 	identifier       /* w    */
	.quad 	identifier       /* x    */
	.quad 	identifier       /* y    */
	.quad 	identifier       /* z    */
	.quad 	whitespace       /* {    */
	.quad 	function_or      /* |    */
	.quad 	whitespace       /* }    */
	.quad 	invalid          /* ~    */
	.quad   invalid          /* 0x7f */
