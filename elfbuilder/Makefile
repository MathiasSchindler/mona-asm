CC := cc
CFLAGS := -std=c11 -Wall -Wextra -Werror -O2 -Iinclude

BUILD := build
BIN := $(BUILD)/as64 $(BUILD)/ld64

AS64_SRCS := src/as64.c src/as64_base.c src/as64_emit.c src/as64_pass.c

all: $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/as64: $(AS64_SRCS) | $(BUILD)
	$(CC) $(CFLAGS) -o $@ $(AS64_SRCS)

$(BUILD)/ld64: src/ld64.c | $(BUILD)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(BUILD)

test: all
	mkdir -p $(BUILD)/tools
	$(BUILD)/as64 ../src/true.s -o $(BUILD)/tools/true.mobj
	$(BUILD)/ld64 $(BUILD)/tools/true.mobj -o $(BUILD)/tools/true
	$(BUILD)/as64 ../src/false.s -o $(BUILD)/tools/false.mobj
	$(BUILD)/ld64 $(BUILD)/tools/false.mobj -o $(BUILD)/tools/false
	$(BUILD)/as64 ../src/exit0.s -o $(BUILD)/tools/exit0.mobj
	$(BUILD)/ld64 $(BUILD)/tools/exit0.mobj -o $(BUILD)/tools/exit0
	$(BUILD)/as64 ../src/echo.s -o $(BUILD)/tools/echo.mobj
	$(BUILD)/ld64 $(BUILD)/tools/echo.mobj -o $(BUILD)/tools/echo
	$(BUILD)/as64 ../src/pwd.s -o $(BUILD)/tools/pwd.mobj
	$(BUILD)/ld64 $(BUILD)/tools/pwd.mobj -o $(BUILD)/tools/pwd
	$(BUILD)/as64 ../src/ls.s -o $(BUILD)/tools/ls.mobj
	$(BUILD)/ld64 $(BUILD)/tools/ls.mobj -o $(BUILD)/tools/ls
	$(BUILD)/as64 ../src/cat.s -o $(BUILD)/tools/cat.mobj
	$(BUILD)/ld64 $(BUILD)/tools/cat.mobj -o $(BUILD)/tools/cat
	$(BUILD)/as64 ../src/mkdir.s -o $(BUILD)/tools/mkdir.mobj
	$(BUILD)/ld64 $(BUILD)/tools/mkdir.mobj -o $(BUILD)/tools/mkdir
	$(BUILD)/as64 ../src/rmdir.s -o $(BUILD)/tools/rmdir.mobj
	$(BUILD)/ld64 $(BUILD)/tools/rmdir.mobj -o $(BUILD)/tools/rmdir
	$(BUILD)/as64 ../src/rm.s -o $(BUILD)/tools/rm.mobj
	$(BUILD)/ld64 $(BUILD)/tools/rm.mobj -o $(BUILD)/tools/rm
	$(BUILD)/as64 ../src/stat.s -o $(BUILD)/tools/stat.mobj
	$(BUILD)/ld64 $(BUILD)/tools/stat.mobj -o $(BUILD)/tools/stat
	$(BUILD)/as64 ../src/cp.s -o $(BUILD)/tools/cp.mobj
	$(BUILD)/ld64 $(BUILD)/tools/cp.mobj -o $(BUILD)/tools/cp
	$(BUILD)/as64 ../src/mv.s -o $(BUILD)/tools/mv.mobj
	$(BUILD)/ld64 $(BUILD)/tools/mv.mobj -o $(BUILD)/tools/mv
	$(BUILD)/as64 ../src/ln.s -o $(BUILD)/tools/ln.mobj
	$(BUILD)/ld64 $(BUILD)/tools/ln.mobj -o $(BUILD)/tools/ln
	$(BUILD)/as64 ../src/utils_test.s -o $(BUILD)/tools/utils_test.mobj
	$(BUILD)/ld64 $(BUILD)/tools/utils_test.mobj -o $(BUILD)/tools/utils_test
	$(BUILD)/as64 ../src/du.s -o $(BUILD)/tools/du.mobj
	$(BUILD)/ld64 $(BUILD)/tools/du.mobj -o $(BUILD)/tools/du
	$(BUILD)/as64 ../src/chmod.s -o $(BUILD)/tools/chmod.mobj
	$(BUILD)/ld64 $(BUILD)/tools/chmod.mobj -o $(BUILD)/tools/chmod
	$(BUILD)/as64 ../src/touch.s -o $(BUILD)/tools/touch.mobj
	$(BUILD)/ld64 $(BUILD)/tools/touch.mobj -o $(BUILD)/tools/touch
	$(BUILD)/as64 ../src/head.s -o $(BUILD)/tools/head.mobj
	$(BUILD)/ld64 $(BUILD)/tools/head.mobj -o $(BUILD)/tools/head
	$(BUILD)/as64 ../src/tail.s -o $(BUILD)/tools/tail.mobj
	$(BUILD)/ld64 $(BUILD)/tools/tail.mobj -o $(BUILD)/tools/tail

size: test
	@echo "Sizes (bytes):"
	@for f in $(BUILD)/tools/*; do \
	  if [ -f $$f ] && [ $${f##*.} != "mobj" ]; then \
	    printf "%8s  %s\n" "$$(stat -c %s $$f)" "$$f"; \
	  fi; \
	done

.PHONY: all clean test size
