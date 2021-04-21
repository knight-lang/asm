/* string structure:
4 bytes refcount
1 byte flag
EITHER:
	{ 1 byte length, rest embedded }
OR:
	{ 3 padding, 8 bytes length, 8 bytes pointer }
}
*/

.globl kn_string_new_borrowed
kn_string_new_borrowed:
	call ddebug

/*
foo:
.byte 0x01
.byte 0x02
.byte 0x03
.byte 0x04
.byte 0xff
.byte 0xee
.quad 0x05 
.text
_main:
	lea foo(%rip), %rax
	xor %ecx, %ecx
	movw 4(%rax), %cx
	xor %ch, %ch
	jmp ddebug
*/

# struct kn_string {
# 	/*
# 	 * The flags that dictate how to manage this struct's memory.
# 	 *
# 	 * Note that the struct _must_ have an 8-bit alignment, so as to work with
# 	 * `kn_value`'s layout.
# 	 */
# 	_Alignas(8) enum kn_string_flags flags;
# 
# 	/*
# 	 * The amount of references to this string.
# 	 *
# 	 * This is increased when `kn_string_clone`d and decreased when
# 	 * `kn_string_free`d, and when it reaches zero, the struct will be freed.
# 	 */
# 	unsigned refcount;
# 
# 	/* All strings are either embedded or allocated. */
# 	union {
# 		struct {
# 			/*
# 			 * The length of the embedded string.
# 			 */
# 			char length;
# 
# 			/*
# 			 * The actual data for the embedded string.
# 			 */
# 			char data[KN_STRING_EMBEDDED_LENGTH];
# 		} embed;
# 
# 		struct {
# 			/*
# 			 * The length of the allocated string.
# 			 *
# 			 * This should equal `strlen(str)`, and is just an optimization aid.
# 			 */
# 			size_t length;
# 
# 			/*
# 			 * The data for an allocated string.
# 			 */
# 			char *str;
# 		} alloc;
# 	};
# 
# 	/*
# 	 * Extra padding for the struct, to make embedded strings have more room.
# 	 *
# 	 * This is generally a number that makes this struct's size an even multiple
# 	 * of two (so as to fill the space an allocator gives us).
# 	 */
# 	char _padding[KN_STRING_PADDING_LENGTH];
# };
# 
