all:
	cp -r public_html ~/
	chmod +x ~/public_html/practica2/test_html.cgi
	chmod +x ~/public_html/practica2/test_txt.cgi
	mkdir ~/public_html/practica1/graphics
	run-main prac1/ex1.hs > ~/public_html/practica1/graphics/exercise1.svg
	run-main prac1/ex2.hs > ~/public_html/practica1/graphics/exercise2.svg
	run-main prac1/ex3.hs > ~/public_html/practica1/graphics/exercise3.svg
	run-main prac1/ex4.hs > ~/public_html/practica1/graphics/exercise4.svg
	run-main prac1/ex5.hs > ~/public_html/practica1/graphics/exercise5.svg
	run-main prac1/ex6.hs > ~/public_html/practica1/graphics/exercise6.svg
	./prac2/prog-web/bin/make-cgi src/counter.hs
	./prac2/prog-web/bin/make-cgi src/calc.hs
