.PHONY: clean run

run: knight
	./knight -e 'D 3'

knight: *.s
	gcc $^ -o knight -g include/*.o

clean:
	-@rm knight
