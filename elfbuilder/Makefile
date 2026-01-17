CC := cc
CFLAGS := -std=c11 -Wall -Wextra -Werror -O2 -Iinclude

BUILD := build
BIN := $(BUILD)/as64 $(BUILD)/ld64

all: $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/as64: src/as64.c | $(BUILD)
	$(CC) $(CFLAGS) -o $@ $<

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
	$(BUILD)/as64 ../src/stat.s -o $(BUILD)/tools/stat.mobj
	$(BUILD)/ld64 $(BUILD)/tools/stat.mobj -o $(BUILD)/tools/stat
	$(BUILD)/as64 ../src/utils_test.s -o $(BUILD)/tools/utils_test.mobj
	$(BUILD)/ld64 $(BUILD)/tools/utils_test.mobj -o $(BUILD)/tools/utils_test

size: test
	@echo "Sizes (bytes):"
	@for f in $(BUILD)/tools/*; do \
	  if [ -f $$f ] && [ $${f##*.} != "mobj" ]; then \
	    printf "%8s  %s\n" "$$(stat -c %s $$f)" "$$f"; \
	  fi; \
	done

.PHONY: all clean test size
