.PHONY: clean run

run: knight
	./knight -e 'D 3'

knight: *.s
	gcc $^ -o knight -g

clean:
	-@rm knight
