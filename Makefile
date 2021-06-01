.PHONY: clean optimized

ifndef NDEBUG
	DBGFLAGS=-g -fsanitize=address,undefined
	SFLAGS=-Wl,-stack_size -Wl,0x1000000000
endif

knight: *.s
	gcc $^ -o knight stdin.o $(DBGFLAGS) $(SFLAGS)

optimized: *.s
	gcc -DKN_RECKLESS="TRUE" -DNDEBUG="TRUE" $^ -o knight -g include/*.o

clean:
	-@rm knight
