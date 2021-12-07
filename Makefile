calc: calc.y calc.l
	bison -d calc.y
	flex  -o calc.lex.c calc.l
	gcc -Wall -o calc calc.lex.c calc.tab.c -lfl -lm `pkg-config --libs --cflags glib-2.0`

clean:
	rm -rf calc
