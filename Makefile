.PHONY: clean optimized

knight: *.s
	gcc $^ -o knight -g include/*.o

optimized: *.s
	gcc -DKN_RECKLESS="TRUE" -DNDEBUG="TRUE" $^ -o knight -g include/*.o

clean:
	-@rm knight
