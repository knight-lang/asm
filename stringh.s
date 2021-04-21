.equ KN_STR_FL_STRUCT_ALLOC, 1
.equ KN_STR_FL_EMBED, 2
.equ KN_STR_FL_STATIC, 4
.equ KN_STR_FL_CACHED, 8


.equ KN_STR_OFFSET_refcount, 0
.equ KN_STR_OFFSET_flags, 4
.equ KN_STR_OFFSET_embedded_length, 5
.equ KN_STR_OFFSET_allocated_length, 8
.equ KN_STR_OFFSET_embedded_start, 6
.equ KN_STR_OFFSET_allocated_pointer, 16


.macro KN_STR_LENGTH str:req, out_r=%rdx, out_e=%edx, out_x=%dx, out_hi=%dh, out_lo=%dl
	mov KN_STR_OFFSET_flags(\str), \out_r
	test $KN_STR_FL_EMBED, \out_lo # bc little endian
	jnz kn_str_length_embedded_\@
	movq KN_STR_OFFSET_allocated_length(\str), \out_r
	jmp kn_str_length_done_\@
kn_str_length_embedded_\@:
	movzb \out_hi, \out_e
kn_str_length_done_\@:
.endm

.macro KN_STR_DEREF str:req, out=%rdx
	testb $KN_STR_FL_EMBED, 4(\str)
	jnz kn_str_deref_embedded_\@
	mov KN_STR_OFFSET_allocated_pointer(\str), \out
	jmp kn_str_deref_done_\@
kn_str_deref_embedded_\@:
	lea KN_STR_OFFSET_embedded_start(\str), \out
kn_str_deref_done_\@:
.endm

# 

# size_t kn_str_length(const struct kn_string *string) {
# 	assert(string != NULL);
# 
# 	return KN_LIKELY(string->flags & KN_STR_FL_EMBED)
# 		? (size_t) string->embed.length
# 		: string->alloc.length;
# }
# 
# char *kn_str_deref(struct kn_string *string) {
# 	assert(string != NULL);
# 
# 	return KN_LIKELY(string->flags & KN_STR_FL_EMBED)
# 		? string->embed.data
# 		: string->alloc.str;
# }
