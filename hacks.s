# These functions i just directly copied from gcc; they'll be hand-written later on when i actually have
# a working version in asm. I just want to make sure they aren't the problem.

.globl number_to_string
number_to_string:
        movq    %rdi, %rsi
        negq    %rsi
        cmovlq  %rdi, %rsi
        lea     (number_to_string_buf+20)(%rip), %rcx
        movabsq $7378697629483820647, %r8       # imm = 0x6666666666666667
.LBB0__1:                                # =>This Inner Loop Header: Depth=1
        movq    %rsi, %rax
        imulq   %r8
        movq    %rdx, %rax
        shrq    $63, %rax
        sarq    $2, %rdx
        addq    %rax, %rdx
        lea     (%rdx,%rdx), %rax
        leal    (%rax,%rax,4), %r9d
        mov     %rsi, %rax
        subl    %r9d, %eax
        addb    $48, %al
        movb    %al, (%rcx)
        addq    $9, %rsi
        addq    $-1, %rcx
        cmpq    $18, %rsi
        movq    %rdx, %rsi
        ja      .LBB0__1
        testq   %rdi, %rdi
        js      .LBB0__4
        addq    $1, %rcx
        movq    %rcx, %rax
        retq
.LBB0__4:
        movb    $45, (%rcx)
        movq    %rcx, %rax
        retq

.globl read_file
read_file:                         # @compile_import
        pushq   %r15
        pushq   %r14
        pushq   %rbx
        lea     .LC0(%rip), %rsi
        callq   _fopen
        movq    %rax, %r15
        movq    %rax, %rdi
        xorl    %esi, %esi
        movl    $2, %edx
        callq   _fseek
        movq    %r15, %rdi
        callq   _ftell
        movq    %rax, %r14
        movq    %r15, %rdi
        xorl    %esi, %esi
        xorl    %edx, %edx
        callq   _fseek
        leaq    1(%r14), %rdi
        callq   xmalloc
        movq    %rax, %rbx
        movb    $0, (%rax,%r14)
        movl    $1, %esi
        movq    %rax, %rdi
        movq    %r14, %rdx
        movq    %r15, %rcx
        callq   _fread
        movq    %r15, %rdi
        callq   _fclose
        movq    %rbx, %rax
        popq    %rbx
        popq    %r14
        popq    %r15
        retq

.globl prompt_for_a_line
prompt_for_a_line:
        pushq   %r14
        pushq   %rbx
        subq    $24, %rsp
        movq    $0, 16(%rsp)
        movq    $0, 8(%rsp)
        call    _get_stdin
        mov     %rax, %rdx
        leaq    8(%rsp), %rdi
        leaq    16(%rsp), %rsi
        callq   _getline
        cmpq    $-1, %rax
        je      .LBB0_1
        movq    %rax, %r14
        lea     kn_string_empty(%rip), %rbx
        subq    $1, %r14
        jb      .LBB0_9
        movq    8(%rsp), %rdi
        cmpb    $10, (%rdi,%r14)
        jne     .LBB0_4
        testq   %r14, %r14
        je      .LBB0_9
        cmpb    $13, -2(%rdi,%rax)
        jne     .LBB0_8
        addq    $-2, %rax
        movq    %rax, %r14
        jne     .LBB0_8
        jmp     .LBB0_9
.LBB0_1:
        movq    8(%rsp), %rdi
        callq   _free
        lea     kn_string_empty(%rip), %rbx
        jmp     .LBB0_10
.LBB0_4:
        movq    %rax, %r14
.LBB0_8:
        movq    %r14, %rsi
        callq   _strndup
        movq    %rax, %rdi
        movq    %r14, %rsi
        callq   kn_string_new_owned
        movq    %rax, %rbx
.LBB0_9:
        movq    8(%rsp), %rdi
        callq   _free
.LBB0_10:
        orq     $3, %rbx
        movq    %rbx, %rax
        addq    $24, %rsp
        popq    %rbx
        popq    %r14
        retq


.globl shell_command
shell_command:
run:
        pushq   %r13
        lea     .LC0(%rip), %rsi
        pushq   %r12
        pushq   %rbp
        movq    %rdi, %rbp
        pushq   %rbx
        subq    $8, %rsp
        call    _popen
        movq    %rax, %r13
        testq   %rax, %rax
        je      .L13
.L2:
        movl    $2048, %edi
        xorl    %eax, %eax
        xorl    %ebp, %ebp
        movl    $2048, %ebx
        call    xmalloc
        mov     %rax, %r12
.L3:
        movq    %rbx, %rdx
        leaq    (%r12,%rbp), %rdi
        movq    %r13, %rcx
        movl    $1, %esi
        subq    %rbp, %rdx
        call    _fread
        testq   %rax, %rax
        je      .L14
        addq    %rax, %rbp
        cmpq    %rbp, %rbx
        jne     .L3
        addq    %rbx, %rbx
        movq    %r12, %rdi
        xorl    %eax, %eax
        movq    %rbx, %rsi
        call    xrealloc
        mov     %rax, %r12
        jmp     .L3
.L14:
        movq    %r13, %rdi
        call    _ferror
        testl   %eax, %eax
        jne     .L15
.L6:
        movq    %r12, %rdi
        xorl    %eax, %eax
        leaq    1(%rbp), %rsi
        call    xrealloc
        movq    %r13, %rdi
        mov     %rax, %r12
        movb    $0, (%r12,%rbp)
        call    _pclose
        cmpl    $-1, %eax
        je      .L16
.L7:
        movq    %rbp, %rsi
        movq    %r12, %rdi
        xorl    %eax, %eax
        call    kn_string_new_owned
        addq    $8, %rsp
        popq    %rbx
        popq    %rbp
        popq    %r12
        popq    %r13
        ret
.L15:
        lea    .LC2(%rip), %rdi
        xorl    %eax, %eax
        call    die
        jmp     .L6
.L16:
        lea    .LC3(%rip), %rdi
        xorl    %eax, %eax
        call    die
        jmp     .L7
.L13:
        movq    %rbp, %rsi
        lea    .LC1(%rip), %rdi
        xorl    %eax, %eax
        call    die
        jmp     .L2

.data
.LC0:
        .string "r"
.LC1:
        .string "unable to execute command '%s'."
.LC2:
        .string "unable to read command stream"
.LC3:
        .string "unable to close command stream"

.bss
number_to_string_buf:
        .zero 22




