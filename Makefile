.PHONY: all debug clean

MODS_MAIN = $(wildcard src/*/main.nim)
MODS = $(patsubst src/%/main.nim,%, $(MODS_MAIN))
MODS_TARGET = $(patsubst src/%/main.nim,out/mods_%.so, $(MODS_MAIN))

all: $(MODS_TARGET)

debug:
	@echo $(MODS_MAIN)
	@echo $(MODS)
	@echo $(MODS_TARGET)

clean:
	rm out/*.so

out/mods_%.so: src/%/*.nim
	@nim c -o:$@ -l:lib/jmp.s -l:-Wl,-soname,$(@F) --app:lib --cpu:i386 --os:android --cc:clang -d:release $(<D)/main.nim