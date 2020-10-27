all:
	cp -r public_html ~/
	chmod +x ~/public_html/practica2/test_html.cgi
	chmod +x ~/public_html/practica2/test_txt.cgi
	./prac2/prog-web/bin/make-cgi prac2/prog-web/src/counter.hs
