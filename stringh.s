.equ KN_STR_OFF_RC, 0
.equ KN_STR_OFF_FLAGS, 4
.equ KN_STR_OFF_LEN, 8
.equ KN_STR_OFF_EMBED_START, 12
.equ KN_STR_OFF_ALLOC_PTR, 16
.equ KN_STR_SIZE, 64 # to allow for lots of embedded data.

.equ KN_STR_FL_STRUCT_ALLOC, 1
.equ KN_STR_FL_EMBED, 2
.equ KN_STR_FL_STATIC, 4
.equ KN_STR_FL_CACHED, 8
.equ KN_STR_EMBED_MAXLEN, (KN_STR_SIZE - 4*3 - 1)

.macro STATIC_STRING what:req, len:req
	.long -2147483648
	.long KN_STR_FL_EMBED
	.long \len
	.asciz "\what"
	.zero (KN_STR_EMBED_MAXLEN - \len)
.endm

.macro STRING_PTR src:req, dst=_none, src_offset=0, scratch=%r8
	.ifc \dst, _none
		STRING_PTR \src, \scratch, \src_offset
		mov \scratch, \src
		.exitm
	.endif

	lea ((\src_offset) + KN_STR_OFF_EMBED_START)(\src), \dst
	testl $KN_STR_FL_EMBED, ((\src_offset) + KN_STR_OFF_FLAGS)(\src)
	cmovz KN_STR_OFF_ALLOC_PTR(\src), \dst
.endm

.macro STRING_LEN src:req, dst:req, src_offset=0
	movl ((\src_offset) + KN_STR_OFF_LEN)(\src), \dst
.endm

.macro STRING_FREE src:req
	decl (\src)
	jne kn_string_free_\@
	.ifnc \src, %rdi
		mov \src, %rdi
	.endif
	call kn_string_free
kn_string_free_\@:
.endm

# 
# 
# size_t kn_string_length(const struct kn_string *string) {
# 	assert(string != NULL);
# 
# 	return KN_LIKELY(string->flags & KN_STR_FL_EMBED)
# 		? (size_t) string->embed.length
# 		: string->alloc.length;
# }
# 
# char *kn_string_deref(struct kn_string *string) {
# 	assert(string != NULL);
# 
# 	return KN_LIKELY(string->flags & KN_STR_FL_EMBED)
# 		? string->embed.data
# 		: string->alloc.str;
# }