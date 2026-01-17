BUILD_DIR := build
SRC_DIR := src
AS := as
LD := ld
ASFLAGS := -I $(SRC_DIR)
LDFLAGS := -s --build-id=none

TOOLS := exit0 utils_test true false echo cat pwd ls stat wc mkdir rmdir rm touch head tail cp mv ln du chmod date seq whoami yes printf sort uniq cut
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
	@rm -rf $(BUILD_DIR)/mr_test; \
	$(BUILD_DIR)/mkdir $(BUILD_DIR)/mr_test; status=$$?; \
	if [ $$status -ne 0 ] || [ ! -d $(BUILD_DIR)/mr_test ]; then \
		echo "mkdir failed"; \
		exit 1; \
	fi; \
	$(BUILD_DIR)/rmdir $(BUILD_DIR)/mr_test; status=$$?; \
	if [ $$status -ne 0 ] || [ -d $(BUILD_DIR)/mr_test ]; then \
		echo "rmdir failed"; \
		exit 1; \
	fi; \
	printf 'x' > $(BUILD_DIR)/rm_test.txt; \
	$(BUILD_DIR)/rm $(BUILD_DIR)/rm_test.txt; status=$$?; \
	if [ $$status -ne 0 ] || [ -e $(BUILD_DIR)/rm_test.txt ]; then \
		echo "rm file failed"; \
		exit 1; \
	fi; \
	$(BUILD_DIR)/rm $(BUILD_DIR) >/dev/null 2>&1; status=$$?; \
	if [ $$status -eq 0 ]; then \
		echo "rm directory should fail"; \
		exit 1; \
	fi; \
	echo "mkdir/rmdir/rm ok"
	@rm -f $(BUILD_DIR)/touch_test.txt; \
	$(BUILD_DIR)/touch $(BUILD_DIR)/touch_test.txt; status=$$?; \
	if [ $$status -ne 0 ] || [ ! -f $(BUILD_DIR)/touch_test.txt ]; then \
		echo "touch failed"; \
		exit 1; \
	fi; \
	printf '1\n2\n3\n' > $(BUILD_DIR)/head_tail_test.txt; \
	out="$$( $(BUILD_DIR)/head $(BUILD_DIR)/head_tail_test.txt )"; \
	expected="$$( printf '1\n2\n3' )"; \
	if [ "$$out" != "$$expected" ]; then \
		echo "head failed: $$out"; \
		exit 1; \
	fi; \
	printf '1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n' > $(BUILD_DIR)/head_tail_test.txt; \
	out="$$( $(BUILD_DIR)/tail $(BUILD_DIR)/head_tail_test.txt )"; \
	expected="$$( printf '3\n4\n5\n6\n7\n8\n9\n10\n11\n12' )"; \
	if [ "$$out" != "$$expected" ]; then \
		echo "tail failed: $$out"; \
		exit 1; \
	fi; \
	echo "touch/head/tail ok"
	@rm -f $(BUILD_DIR)/cp_dst.txt $(BUILD_DIR)/mv_dst.txt $(BUILD_DIR)/ln_dst.txt; \
	printf 'copyme' > $(BUILD_DIR)/cp_src.txt; \
	$(BUILD_DIR)/cp $(BUILD_DIR)/cp_src.txt $(BUILD_DIR)/cp_dst.txt; status=$$?; \
	if [ $$status -ne 0 ]; then \
		echo "cp failed"; \
		exit 1; \
	fi; \
	cmp -s $(BUILD_DIR)/cp_src.txt $(BUILD_DIR)/cp_dst.txt || { echo "cp mismatch"; exit 1; }; \
	$(BUILD_DIR)/mv $(BUILD_DIR)/cp_dst.txt $(BUILD_DIR)/mv_dst.txt; status=$$?; \
	if [ $$status -ne 0 ] || [ ! -f $(BUILD_DIR)/mv_dst.txt ]; then \
		echo "mv failed"; \
		exit 1; \
	fi; \
	$(BUILD_DIR)/ln $(BUILD_DIR)/mv_dst.txt $(BUILD_DIR)/ln_dst.txt; status=$$?; \
	if [ $$status -ne 0 ] || [ ! -f $(BUILD_DIR)/ln_dst.txt ]; then \
		echo "ln failed"; \
		exit 1; \
	fi; \
	cmp -s $(BUILD_DIR)/mv_dst.txt $(BUILD_DIR)/ln_dst.txt || { echo "ln content mismatch"; exit 1; }; \
	echo "cp/mv/ln ok"
	@printf 'abcde' > $(BUILD_DIR)/du_test.txt; \
	out="$$( $(BUILD_DIR)/du $(BUILD_DIR)/du_test.txt )"; \
	expected="$$( printf '5' )"; \
	if [ "$$out" != "$$expected" ]; then \
		echo "du failed: $$out"; \
		exit 1; \
	fi; \
	printf 'x' > $(BUILD_DIR)/chmod_test.txt; \
	$(BUILD_DIR)/chmod 600 $(BUILD_DIR)/chmod_test.txt; status=$$?; \
	if [ $$status -ne 0 ]; then \
		echo "chmod failed"; \
		exit 1; \
	fi; \
	mode="$$( stat -c %a $(BUILD_DIR)/chmod_test.txt )"; \
	if [ "$$mode" != "600" ]; then \
		echo "chmod mode failed: $$mode"; \
		exit 1; \
	fi; \
	echo "du/chmod ok"
	@out="$$( $(BUILD_DIR)/seq 3 )"; \
	if [ "$$out" != "$$( printf '1\n2\n3' )" ]; then \
		echo "seq 3 failed: $$out"; \
		exit 1; \
	fi; \
	out="$$( $(BUILD_DIR)/seq 2 4 )"; \
	if [ "$$out" != "$$( printf '2\n3\n4' )" ]; then \
		echo "seq 2 4 failed: $$out"; \
		exit 1; \
	fi; \
	echo "seq ok"
	@out="$$( $(BUILD_DIR)/date )"; \
	printf '%s' "$$out" | grep -Eq '^[0-9]+$$' || { echo "date failed: $$out"; exit 1; }; \
	echo "date ok"
	@out="$$( $(BUILD_DIR)/whoami )"; \
	printf '%s' "$$out" | grep -Eq '^[A-Za-z0-9_.-]+$$' || { echo "whoami failed: $$out"; exit 1; }; \
	echo "whoami ok"
	@out="$$( $(BUILD_DIR)/printf 'x%s%dy' foo 3 )"; \
	if [ "$$out" != "xfoo3y" ]; then \
		echo "printf failed: $$out"; \
		exit 1; \
	fi; \
	out="$$( $(BUILD_DIR)/printf '%u %x %X %o %c' 255 255 255 8 65 )"; \
	if [ "$$out" != "255 ff FF 10 A" ]; then \
		echo "printf format failed: $$out"; \
		exit 1; \
	fi; \
	out="$$( $(BUILD_DIR)/printf '%b' 'a\nb' )"; \
	if [ "$$out" != "$$( printf 'a\nb' )" ]; then \
		echo "printf %b failed: $$out"; \
		exit 1; \
	fi; \
	out="$$( $(BUILD_DIR)/printf 'a\nb' )"; \
	if [ "$$out" != "$$( printf 'a\nb' )" ]; then \
		echo "printf escape failed: $$out"; \
		exit 1; \
	fi; \
	echo "printf ok"
	@out="$$( $(BUILD_DIR)/yes hi | $(BUILD_DIR)/head )"; \
	expected="$$( printf 'hi\nhi\nhi\nhi\nhi\nhi\nhi\nhi\nhi\nhi' )"; \
	if [ "$$out" != "$$expected" ]; then \
		echo "yes failed: $$out"; \
		exit 1; \
	fi; \
	out="$$( $(BUILD_DIR)/yes -n hi | head -c 5 )"; \
	if [ "$$out" != "hihih" ]; then \
		echo "yes -n failed: $$out"; \
		exit 1; \
	fi; \
	echo "yes ok"
	@out="$$( printf 'b\na\nc\n' | $(BUILD_DIR)/sort )"; \
	if [ "$$out" != "$$( printf 'a\nb\nc' )" ]; then \
		echo "sort failed: $$out"; \
		exit 1; \
	fi; \
	echo "sort ok"
	@out="$$( printf 'a\na\nb\nb\nb\n' | $(BUILD_DIR)/uniq )"; \
	if [ "$$out" != "$$( printf 'a\nb' )" ]; then \
		echo "uniq failed: $$out"; \
		exit 1; \
	fi; \
	echo "uniq ok"
	@out="$$( printf 'a:1:x\nb:2:y\n' | $(BUILD_DIR)/cut -d : -f 2 )"; \
	if [ "$$out" != "$$( printf '1\n2' )" ]; then \
		echo "cut failed: $$out"; \
		exit 1; \
	fi; \
	echo "cut ok"

clean:
	rm -rf $(BUILD_DIR)
