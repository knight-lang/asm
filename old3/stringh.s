.equ STR_FL_STRUCT_ALLOC, 1
.equ STR_FL_EMBED, 2
.equ STR_FL_STATIC, 4
.equ STR_FL_CACHED, 8


.equ STR_OFFSET_refcount, 0
.equ STR_OFFSET_flags, 4
.equ STR_OFFSET_embedded_length, 5
.equ STR_OFFSET_allocated_length, 8
.equ STR_OFFSET_embedded_start, 6
.equ STR_OFFSET_allocated_pointer, 16
.equ STR_SIZE, 32 # extra 8 bytes of padding
.equ STR_MAX_EMBED_LENGTH, (STR_SIZE - STR_OFFSET_embedded_start - 1) # `-1` for `\0`


.macro STR_LENGTH str:req, out_r=%rdx, out_e=%edx, out_x=%dx, out_hi=%dh, out_lo=%dl
	mov STR_OFFSET_flags(\str), \out_r
	test $STR_FL_EMBED, \out_lo # bc little endian
	jnz str_length_embedded_\@
	movq STR_OFFSET_allocated_length(\str), \out_r
	jmp str_length_done_\@
str_length_embedded_\@:
	movzb \out_hi, \out_e
str_length_done_\@:
.endm

.macro STR_DEREF str:req, out=%rdx
	testb $STR_FL_EMBED, 4(\str)
	jnz str_deref_embedded_\@
	mov STR_OFFSET_allocated_pointer(\str), \out
	jmp str_deref_done_\@
str_deref_embedded_\@:
	lea STR_OFFSET_embedded_start(\str), \out
str_deref_done_\@:
.endm
