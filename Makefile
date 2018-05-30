include toolchain.mk

.PHONY: all debug clean clean-mods

MODS_MAIN = $(wildcard src/*/main.nim)
MODS = $(patsubst src/%/main.nim,%, $(MODS_MAIN))
MODS_TARGET = $(patsubst src/%/main.nim,out/mods_%.so, $(MODS_MAIN))
MODS_HOOKLIB = $(patsubst src/%/main.nim,src/%/pub, $(MODS_MAIN))

CPPSUPPORT = $(wildcard cppsupport/*.cpp)

export CXXFLAGS := -I$(CURDIR)/minecraft-headers -fno-rtti -O3 -fPIC -std=c++14 -Wno-invalid-offsetof

PUB_FILES = $(wildcard pub/*.nim)

all: $(patsubst lib/%.nim, out/lib%.so,$(wildcard lib/*.nim)) $(patsubst cppsupport/%.cpp,lib/%.o, $(CPPSUPPORT)) $(addsuffix /.keep,$(MODS_HOOKLIB)) $(MODS_TARGET)

debug:
	@echo $(EMBEDCPP)

clean-mods:
	rm -f out/*.so

clean: clean-mods
	rm -f $(MODS_HOOKLIB)
	rm -f lib/*.o

src/%/pub/.keep: pub/.keep
	@ln -s ../../pub $(@D)

lib/%.o: cppsupport/%.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS)

out/lib%.so: lib/%.nim
	nim c -o:$@ -d:noSignalHandler -l:-L./lib -l:-lminecraftpe -l:lib/jmp.s -l:-Wl,-soname,$(@F) --app:lib --cpu:i386 --os:android --cc:clang -d:release $<
	@ls out
	@echo $@ - $^

out/mods_%.so: src/%/*.nim $(wildcard src/%/Makefile) $(wildcard src/%/*.cpp) lib/libminecraftpe.so $(wildcard pub/*.nim) $(patsubst lib/%.nim, out/lib%.so,$(wildcard lib/*.nim))
	@echo [BUILD MOD $(@F)] $^
	(cd $(<D) && [ -e Makefile ] && (make || exit 1) || exit 0)
	nim c -o:$@ -d:noSignalHandler -d:ModBase=$(<D) -l:-L./lib -l:-lminecraftpe -l:lib/jmp.s -l:-Wl,-soname,$(@F) --app:lib --cpu:i386 --os:android --cc:clang -d:release $(<D)/main.nim
	@strip $@

lib/libminecraftpe.so:
	@echo You may need to put libminecraftpe.so to lib directory.
	@exit 1