#!/usr/bin/make
SHELL := /bin/zsh

# Apply debug options if specified
ifdef DEBUG
PARSER_DEBUG_FLAGS = -d
endif

# Code generation commands
LEXER_GENERATOR := alex
LEXER_GENERATOR_FLAGS := -g
PARSER_GENERATOR := happy
PARSER_GENERATOR_FLAGS := -ga $(PARSER_DEBUG_FLAGS) -m spadeParser

# Code up-keep commands
LINTER := hlint
LINTER_FLAGS := -s
FORMATTER := stylish-haskell
FORMATTER_FLAGS := -i

.DEFAULT_GOAL := all

# All required source files (existent or otherwise)
SOURCE_FILES = $(shell find . -name '*.hs' | grep -v .stack-work) ./Args.hs ./Parser/SpadeLexer.hs ./Parser/SpadeParser.hs

all: build ## Build everything
.PHONY: all

build: ./spade ## Build everything, explicitly
.PHONY: build

./spade: ./.stack-work/install/x86_64-linux-tinfo6/a4fefd2a9618441c5b464352bd9d27949d738f84f553d0be92299367e59678e1/8.6.5/bin/spade
	ln -sf $^ $@
.DELETE_ON_ERROR: ./spade

./.stack-work/install/x86_64-linux-tinfo6/a4fefd2a9618441c5b464352bd9d27949d738f84f553d0be92299367e59678e1/8.6.5/bin/spade: $(SOURCE_FILES)
	stack build

./Parser/SpadeLexer.hs: ./Parser/SpadeLexer.x ./Parser/SpadeLexer.hs.patch
	$(LEXER_GENERATOR) $(LEXER_GENERATOR_FLAGS) $< -o $@
.DELETE_ON_ERROR: ./Parser/SpadeLexer.hs

./Parser/SpadeParser.hs: ./Parser/SpadeParser.y ./Parser/SpadeParser.hs.patch
	$(PARSER_GENERATOR) $(PARSER_GENERATOR_FLAGS) -i./Parser/SpadeParser.info $< -o $@
.DELETE_ON_ERROR: ./Parser/SpadeParser.hs

%.x:;
%.y:;
%.patch:;

./Args.hs: spade.json
	arggen_haskell < $^ > $@

%.hs:;

./spade.json:;

man: ./dist/doc/man/spade.1.gz; ## Make the man page
.PHONY: man

/usr/share/man/man1/spade.1.gz: ./dist/doc/man/spade.1.gz
	sudo install -Dm 644 $^ $@

./dist/doc/man/spade.1.gz: spade.json
	mkdir -p ./dist/doc/man/ 2>/dev/null || true
	(mangen | gzip --best) < $^ > $@
.DELETE_ON_ERROR: ./dist/doc/man/spade.1.gz

format: $(shell find . -name '*.hs' | grep -v dist | grep -v Args.hs | grep -v Parser/SpadeLexer.hs | grep -v Parser/SpadeParser.hs) ## Run the formatter on all non-generated source files
	$(FORMATTER) $(FORMATTER_FLAGS) $^
.PHONY: format

lint: $(shell find . -name '*.hs' | grep -v dist | grep -v Args.hs | grep -v Parser/SpadeLexer.hs | grep -v Parser/SpadeParser.hs) ## Run the linter on all non-generated source files
	$(LINTER) $(LINTER_FLAGS) $^
.PHONY: lint

doc: dist/doc/html/spade/spade/index.html ## Make the documentation
.PHONY: doc

dist/doc/html/spade/spade/index.html: $(SOURCE_FILES)
	stack haddock

clean: ## Delete all generated files
	stack clean --verbose=0
	$(RM) cabal.config Args.hs *_completions.sh ./spade ./Parser/Spade{Lexer,Parser,ParserData}.hs ./Parser/SpadeParser.info $(shell find . -name '*.orig') $(shell find . -name '*.info') $(shell find . -name '*.hi')
.PHONY: clean

# Our thanks to François Zaninotto! https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html for helping
# us document our Makefile
help: ## Output this help summary
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
