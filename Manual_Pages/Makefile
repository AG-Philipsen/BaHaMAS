# Cheatsheet https://devhints.io/makefile

PANDOC ?= pandoc
POPULATE_OPTIONS ?= ./PopulateOptions.bash
MANSECTION ?= 1
OUTPUTS  = $(patsubst %.md, man1/%.1, $(wildcard BaHaMAS*.md))

#---------------------------------------------

manuals: $(OUTPUTS)
	@echo All manuals correctly built!

.PHONY: manuals

man1/BaHaMAS.$(MANSECTION): BaHaMAS.md
	@$(PANDOC) --standalone $(PANDOCFLAGS) --to man $< -o $@
	@echo Manual from $< created.

man1/%.$(MANSECTION): %.md OptionsPool.md
	@$(POPULATE_OPTIONS) $<
	@$(PANDOC) --standalone $(PANDOCFLAGS) --to man $< -o $@
	@echo Manual from $< created.

clean:
	@rm man1/*.$(MANSECTION)
	@echo All manuals were removed.
