.PHONY: check deps format test

check: test format
	mix dialyzer

deps:
	mix deps.get

format:
	mix format --check-formatted

test:
	mix test
