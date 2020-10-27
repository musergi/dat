all:
	cp -r public_html ~/
	chmod +x ~/public_html/practica2/test_html.cgi
	chmod +x ~/public_html/practica2/test_txt.cgi
	cd prac2/prog-web/
	./bin/make-cgi src/counter.hs
	cd ../../
