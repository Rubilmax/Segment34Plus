include .env

MONKEYC := java -XX:ReservedCodeCacheSize=256m -XX:-TieredCompilation -jar "$(SDK_HOME)/bin/monkeybrains.jar" --no-gen-styles
CONNECTIQ := "$(SDK_HOME)/bin/connectiq"
MONKEYDO := "$(SDK_HOME)/bin/monkeydo"
JUNGLE := monkey.jungle
DEVICE ?= fenix847mm
WATCHFACE_SOURCES := $(shell find source resources* disp-resources size-resources -type f 2>/dev/null) manifest.xml $(JUNGLE)
RELEASE_BUILD := scripts/build-watchface.mjs
OPTIMIZER := node_modules/@markw65/monkeyc-optimizer/package.json

.PHONY: iq sim run test clean

iq: Segment34Plus.iq

$(OPTIMIZER): package.json package-lock.json
	npm ci --ignore-scripts --no-audit --no-fund

Segment34Plus.iq: $(WATCHFACE_SOURCES) $(RELEASE_BUILD) $(OPTIMIZER)
	node $(RELEASE_BUILD) "$(SDK_HOME)" "$(KEY)" $@

sim: bin/Segment34Plus-$(DEVICE).prg

bin/Segment34Plus-$(DEVICE).prg: $(WATCHFACE_SOURCES) $(RELEASE_BUILD) $(OPTIMIZER)
	node $(RELEASE_BUILD) "$(SDK_HOME)" "$(KEY)" $@ $(DEVICE)

run: bin/Segment34Plus-$(DEVICE).prg
	$(CONNECTIQ) &
	@sleep 5
	$(MONKEYDO) $< $(DEVICE)

bin/Segment34Plus-tests-$(DEVICE).prg: $(WATCHFACE_SOURCES)
	@mkdir -p bin
	$(MONKEYC) -o $@ -f $(JUNGLE) -y "$(KEY)" -d $(DEVICE) -t -w

test: bin/Segment34Plus-tests-$(DEVICE).prg
	$(CONNECTIQ)
	@sleep 5
	@# SDK 8.4.1 can exit 1 after passing tests; require its explicit success summary.
	@$(MONKEYDO) $< $(DEVICE) -t > bin/weather-tests.log 2>&1 || true
	@cat bin/weather-tests.log
	@grep -Eq '^PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)$$' bin/weather-tests.log

clean:
	rm -rf bin Segment34Plus.iq
