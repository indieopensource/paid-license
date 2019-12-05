COMMONMARK=node_modules/.bin/commonform-commonmark
CRITIQUE=node_modules/.bin/commonform-critique
DOCX=node_modules/.bin/commonform-docx
HTML=node_modules/.bin/commonform-html
JSON=node_modules/.bin/json
LINT=node_modules/.bin/commonform-lint
TOOLS=$(COMMONMARK) $(CRITIQUE) $(DOCX) $(HTML) $(JSON) $(LINT)

SOURCES=terms.md
FORMS=$(addprefix build/,$(SOURCES:.md=.form.json))

.PHONY: all markdown html docx pdf

all: json markdown html docx pdf

json: $(FORMS)
markdown: $(addprefix build/,$(SOURCES))
html: $(addprefix build/,$(SOURCES:.md=.html))
docx: $(addprefix build/,$(SOURCES:.md=.docx))
pdf: $(addprefix build/,$(SOURCES:.md=.pdf))

build/%.docx: build/%.form.json build/%.title build/%.edition styles.json | build $(DOCX)
	$(DOCX) --title "$(shell cat build/$*.title)" --edition "$(shell cat build/$*.edition)" --number outline --indent-margins --left-align-title --styles styles.json $< > $@

build/%.md: build/%.form.json build/%.title build/%.edition | build $(COMMONMARK)
	$(COMMONMARK) stringify --title "$(shell cat build/$*.title)" --edition "$(shell cat build/$*.edition)" --ordered --ids < $< > $@

build/%.html: build/%.form.json build/%.title build/%.edition | build $(COMMONMARK)
	$(HTML) stringify --title "$(shell cat build/$*.title)" --edition "$(shell cat build/$*.edition)" --html5 --lists < $< > $@

%.pdf: %.docx
	unoconv $<

build/%.form.json: %.md | build $(CFCM)
	$(COMMONMARK) parse --only form < $< > $@

build/%.title: %.md | build $(CFCM) $(JSON)
	$(COMMONMARK) parse < $< | $(JSON) frontMatter.title > $@

build/%.edition: %.md | build $(CFCM) $(JSON)
	$(COMMONMARK) parse < $< | $(JSON) frontMatter.edition > $@

$(TOOLS):
	npm ci

build:
	mkdir -p build

.PHONY: clean lint critique docker

clean:
	rm -rf build

lint: $(FORMS) | $(LINT) $(JSON)
	@for form in $(FORMS); do \
		echo ; \
		echo $$form; \
		cat $$form | $(LINT) | $(JSON) -a message | sort -u; \
	done; \

critique: $(FORMS) | $(CRITIQUE) $(JSON)
	@for form in $(FORMS); do \
		echo ; \
		echo $$form ; \
		cat $$form | $(CRITIQUE) | $(JSON) -a message | sort -u; \
	done

docker:
	docker build -t indie-open-source-paid-license .
	docker run --name indie-open-source-paid-license indie-open-source-paid-license
	docker cp indie-open-source-paid-license:/workdir/build .
	docker rm indie-open-source-paid-license
