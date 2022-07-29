test_case = '' # Run all tests by default; otherwise run user specified test
.PHONY: dev fmt install lint migrations test fmt-ci lint-ci build install-dev load-test

build: ;

dev:
	uvicorn main:app --reload --host 0.0.0.0 --port 80

install:
	pip3 install --user -r requirements.txt