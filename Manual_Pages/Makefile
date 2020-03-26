# Cheatsheet https://devhints.io/makefile

PANDOC ?= pandoc
MANSECTION ?= 1
OUTPUTS  = $(patsubst %.md, %.1, $(wildcard BaHaMAS*.md))

#---------------------------------------------

manuals: $(OUTPUTS)
	@echo All manuals correctly built!

.PHONY: manuals

%.$(MANSECTION): %.md
	@$(PANDOC) --standalone $(PANDOCFLAGS) --to man $< -o $@
	@echo Manual from $< created.
