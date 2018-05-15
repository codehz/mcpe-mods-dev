.PHONY: all debug clean clean-mods

MODS_MAIN = $(wildcard src/*/main.nim)
MODS = $(patsubst src/%/main.nim,%, $(MODS_MAIN))
MODS_TARGET = $(patsubst src/%/main.nim,out/mods_%.so, $(MODS_MAIN))
MODS_HOOKLIB = $(patsubst src/%/main.nim,src/%/pub, $(MODS_MAIN))

PUB_FILES = $(wildcard pub/*.nim)

all: $(addsuffix /.keep,$(MODS_HOOKLIB)) $(MODS_TARGET)

debug:
	@echo $(MODS_MAIN)
	@echo $(MODS)
	@echo $(MODS_TARGET)
	@echo $(addsuffix /.keep,$(MODS_HOOKLIB))
	@echo $(PUB_FILES)

clean-mods:
	rm out/*.so

clean: clean-mods
	rm $(MODS_HOOKLIB)

src/%/pub/.keep: pub/.keep
	@ln -s ../../pub $(@D)

out/mods_%.so: src/%/*.nim lib/libminecraftpe.so pub/*.nim
	@echo [BUILD MOD $(@F)]
	@nim c -o:$@ -l:-L./lib -l:-lminecraftpe -l:lib/jmp.s -l:-Wl,-soname,$(@F) --app:lib --cpu:i386 --os:android --cc:clang -d:release $(<D)/main.nim
	@strip $@

lib/libminecraftpe.so:
	@echo You may need to put libminecraftpe.so to lib directory.
	@exit 1