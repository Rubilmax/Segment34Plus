include .env

MONKEYC := java -XX:ReservedCodeCacheSize=256m -XX:-TieredCompilation -jar "$(SDK_HOME)/bin/monkeybrains.jar"
CONNECTIQ := "$(SDK_HOME)/bin/connectiq"
MONKEYDO := "$(SDK_HOME)/bin/monkeydo"
JUNGLE := monkey.jungle

.PHONY: iq sim run clean

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

clean:
	rm -rf bin Segment34Plus.iq
