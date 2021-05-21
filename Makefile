.PHONY: clean optimized

DBGFLAGS=#-g -fsanitize=address,undefined
SFLAGS=#-Wl,-stack_size -Wl,0x100000000
knight: *.s
	gcc $^ -o knight stdin.o $(DBGFLAGS) $(SFLAGS)

optimized: *.s
	gcc -DKN_RECKLESS="TRUE" -DNDEBUG="TRUE" $^ -o knight -g include/*.o

clean:
	-@rm knight
