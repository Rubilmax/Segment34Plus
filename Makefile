include .env

MONKEYC := java -XX:ReservedCodeCacheSize=256m -XX:-TieredCompilation -jar "$(SDK_HOME)/bin/monkeybrains.jar"
CONNECTIQ := "$(SDK_HOME)/bin/connectiq"
MONKEYDO := "$(SDK_HOME)/bin/monkeydo"
JUNGLE := monkey.jungle

.PHONY: iq sim run test clean

iq: Segment34Plus.iq

Segment34Plus.iq: $(shell find source resources* disp-resources size-resources -type f 2>/dev/null) manifest.xml $(JUNGLE)
	$(MONKEYC) -o $@ -f $(JUNGLE) -y "$(KEY)" -e -w -r

sim: bin/Segment34Plus-fenix847mm.prg

bin/Segment34Plus-fenix847mm.prg: $(shell find source resources* disp-resources size-resources -type f 2>/dev/null) manifest.xml $(JUNGLE)
	@mkdir -p bin
	$(MONKEYC) -o $@ -f $(JUNGLE) -y "$(KEY)" -d fenix847mm -w

run: bin/Segment34Plus-fenix847mm.prg
	@pkill -f connectiq || true
	@sleep 1
	$(CONNECTIQ) &
	@sleep 5
	$(MONKEYDO) bin/Segment34Plus-fenix847mm.prg fenix847mm

bin/Segment34Plus-tests.prg: $(shell find source resources* disp-resources size-resources -type f 2>/dev/null) manifest.xml $(JUNGLE)
	@mkdir -p bin
	$(MONKEYC) -o $@ -f $(JUNGLE) -y "$(KEY)" -d fenix847mm -t -w

test: bin/Segment34Plus-tests.prg
	$(CONNECTIQ)
	@sleep 5
	@# SDK 8.4.1 can exit 1 after passing tests; require its explicit success summary.
	@$(MONKEYDO) $< fenix847mm -t > bin/weather-tests.log 2>&1 || true
	@cat bin/weather-tests.log
	@grep -Eq '^PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)$$' bin/weather-tests.log

clean:
	rm -rf bin Segment34Plus.iq
