.PHONY: clean

run: knight
	./knight -e 'D 3'

knight: *.s
	gcc $^ -o knight

clean:
	-@rm knight
