BATS := tests/bats-core/bin/bats
BATS_ARGS := --recursive --timing

test-unit:
	$(BATS) $(BATS_ARGS) tests/unit/

test-integration:
	$(BATS) --jobs 1 $(BATS_ARGS) tests/integration/

test-lint:
	$(BATS) $(BATS_ARGS) tests/lint/

test-all: test-unit test-integration test-lint

# R4-M16: make test is an alias for test-all to avoid recursing into
# vendored bats-core/tests/ and other non-test directories.
test: test-all

.PHONY: test-unit test-integration test-lint test-all test
