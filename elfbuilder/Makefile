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
	$(BUILD)/as64 ../src/date.s -o $(BUILD)/tools/date.mobj
	$(BUILD)/ld64 $(BUILD)/tools/date.mobj -o $(BUILD)/tools/date
	$(BUILD)/as64 ../src/seq.s -o $(BUILD)/tools/seq.mobj
	$(BUILD)/ld64 $(BUILD)/tools/seq.mobj -o $(BUILD)/tools/seq
	$(BUILD)/as64 ../src/whoami.s -o $(BUILD)/tools/whoami.mobj
	$(BUILD)/ld64 $(BUILD)/tools/whoami.mobj -o $(BUILD)/tools/whoami
	$(BUILD)/as64 ../src/yes.s -o $(BUILD)/tools/yes.mobj
	$(BUILD)/ld64 $(BUILD)/tools/yes.mobj -o $(BUILD)/tools/yes
	$(BUILD)/as64 ../src/printf.s -o $(BUILD)/tools/printf.mobj
	$(BUILD)/ld64 $(BUILD)/tools/printf.mobj -o $(BUILD)/tools/printf
	$(BUILD)/as64 ../src/sort.s -o $(BUILD)/tools/sort.mobj
	$(BUILD)/ld64 $(BUILD)/tools/sort.mobj -o $(BUILD)/tools/sort
	$(BUILD)/as64 ../src/uniq.s -o $(BUILD)/tools/uniq.mobj
	$(BUILD)/ld64 $(BUILD)/tools/uniq.mobj -o $(BUILD)/tools/uniq
	$(BUILD)/as64 ../src/cut.s -o $(BUILD)/tools/cut.mobj
	$(BUILD)/ld64 $(BUILD)/tools/cut.mobj -o $(BUILD)/tools/cut
	$(BUILD)/as64 ../src/tr.s -o $(BUILD)/tools/tr.mobj
	$(BUILD)/ld64 $(BUILD)/tools/tr.mobj -o $(BUILD)/tools/tr
	$(BUILD)/as64 ../src/od.s -o $(BUILD)/tools/od.mobj
	$(BUILD)/ld64 $(BUILD)/tools/od.mobj -o $(BUILD)/tools/od
	$(BUILD)/as64 ../src/tee.s -o $(BUILD)/tools/tee.mobj
	$(BUILD)/ld64 $(BUILD)/tools/tee.mobj -o $(BUILD)/tools/tee
	$(BUILD)/as64 ../src/sleep.s -o $(BUILD)/tools/sleep.mobj
	$(BUILD)/ld64 $(BUILD)/tools/sleep.mobj -o $(BUILD)/tools/sleep
	$(BUILD)/as64 ../src/basename.s -o $(BUILD)/tools/basename.mobj
	$(BUILD)/ld64 $(BUILD)/tools/basename.mobj -o $(BUILD)/tools/basename
	$(BUILD)/as64 ../src/dirname.s -o $(BUILD)/tools/dirname.mobj
	$(BUILD)/ld64 $(BUILD)/tools/dirname.mobj -o $(BUILD)/tools/dirname
	$(BUILD)/as64 ../src/uname.s -o $(BUILD)/tools/uname.mobj
	$(BUILD)/ld64 $(BUILD)/tools/uname.mobj -o $(BUILD)/tools/uname
	$(BUILD)/as64 ../src/shell.s -o $(BUILD)/tools/shell.mobj
	$(BUILD)/ld64 $(BUILD)/tools/shell.mobj -o $(BUILD)/tools/shell

size: test
	@echo "Sizes (bytes):"
	@for f in $(BUILD)/tools/*; do \
	  if [ -f $$f ] && [ $${f##*.} != "mobj" ]; then \
	    printf "%8s  %s\n" "$$(stat -c %s $$f)" "$$f"; \
	  fi; \
	done

.PHONY: all clean test size
