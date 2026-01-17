BUILD_DIR := build
SRC_DIR := src
AS := as
LD := ld
ASFLAGS := -I $(SRC_DIR)
LDFLAGS := -s --build-id=none

TOOLS := exit0 utils_test true false echo cat pwd ls stat wc
BINS := $(addprefix $(BUILD_DIR)/,$(TOOLS))
OBJS := $(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(TOOLS)))

.PHONY: all clean strip run test

all: $(BINS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(SRC_DIR)/syscalls.inc $(SRC_DIR)/utils.inc | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/%: $(BUILD_DIR)/%.o
	$(LD) $(LDFLAGS) -o $@ $<

strip: $(BINS)
	strip -s $(BINS)

run: $(BUILD_DIR)/exit0
	$(BUILD_DIR)/exit0

test: $(BINS)
	@$(BUILD_DIR)/exit0; status=$$?; \
	if [ $$status -ne 0 ]; then \
		echo "exit0 failed: $$status"; \
		exit 1; \
	fi; \
	echo "exit0 ok"
	@$(BUILD_DIR)/utils_test; status=$$?; \
	if [ $$status -ne 0 ]; then \
		echo "utils_test failed: $$status"; \
		exit 1; \
	fi; \
	echo "utils_test ok"
	@$(BUILD_DIR)/true; status=$$?; \
	if [ $$status -ne 0 ]; then \
		echo "true failed: $$status"; \
		exit 1; \
	fi; \
	echo "true ok"
	@$(BUILD_DIR)/false; status=$$?; \
	if [ $$status -eq 0 ]; then \
		echo "false failed: $$status"; \
		exit 1; \
	fi; \
	echo "false ok"
	@out="$$( $(BUILD_DIR)/echo a b )"; \
	if [ "$$out" != "a b" ]; then \
		echo "echo failed: $$out"; \
		exit 1; \
	fi; \
	echo "echo ok"
	@out="$$( printf 'hi\n' | $(BUILD_DIR)/cat )"; \
	if [ "$$out" != "hi" ]; then \
		echo "cat stdin failed: $$out"; \
		exit 1; \
	fi; \
	printf 'file\n' > $(BUILD_DIR)/cat_test.txt; \
	out="$$( $(BUILD_DIR)/cat $(BUILD_DIR)/cat_test.txt )"; \
	if [ "$$out" != "file" ]; then \
		echo "cat file failed: $$out"; \
		exit 1; \
	fi; \
	echo "cat ok"
	@out="$$( $(BUILD_DIR)/pwd )"; \
	if [ "$$out" != "$$PWD" ]; then \
		echo "pwd failed: $$out"; \
		exit 1; \
	fi; \
	echo "pwd ok"
	@rm -rf $(BUILD_DIR)/ls_test; \
	mkdir -p $(BUILD_DIR)/ls_test; \
	printf 'a' > $(BUILD_DIR)/ls_test/one; \
	printf 'b' > $(BUILD_DIR)/ls_test/two; \
	out="$$( $(BUILD_DIR)/ls $(BUILD_DIR)/ls_test )"; \
	printf '%s\n' "$$out" | grep -qx one || { echo "ls missing one"; exit 1; }; \
	printf '%s\n' "$$out" | grep -qx two || { echo "ls missing two"; exit 1; }; \
	echo "ls ok"
	@printf '1234' > $(BUILD_DIR)/stat_test.txt; \
	out="$$( $(BUILD_DIR)/stat $(BUILD_DIR)/stat_test.txt )"; \
	set -- $$out; \
	if [ "$$1" != "4" ]; then \
		echo "stat size failed: $$out"; \
		exit 1; \
	fi; \
	if [ -z "$$2" ] || [ -z "$$3" ]; then \
		echo "stat fields failed: $$out"; \
		exit 1; \
	fi; \
	echo "stat ok"
	@printf 'a b\nc\n' > $(BUILD_DIR)/wc_test.txt; \
	out="$$( $(BUILD_DIR)/wc $(BUILD_DIR)/wc_test.txt )"; \
	if [ "$$out" != "2 3 6" ]; then \
		echo "wc file failed: $$out"; \
		exit 1; \
	fi; \
	out="$$( printf 'a b\nc\n' | $(BUILD_DIR)/wc )"; \
	if [ "$$out" != "2 3 6" ]; then \
		echo "wc stdin failed: $$out"; \
		exit 1; \
	fi; \
	echo "wc ok"
	@$(BUILD_DIR)/ls -z >/dev/null 2>$(BUILD_DIR)/opt_err.txt; status=$$?; \
	if [ $$status -eq 0 ]; then \
		echo "options invalid accepted"; \
		exit 1; \
	fi; \
	grep -q "usage:" $(BUILD_DIR)/opt_err.txt || { echo "options usage missing"; exit 1; }; \
	echo "opts ok"

clean:
	rm -rf $(BUILD_DIR)
