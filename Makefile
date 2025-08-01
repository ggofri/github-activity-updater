.PHONY: test test-unit test-integration test-all clean help
help:
	@echo "GitHub Activity Updater - Available commands:"
	@echo ""
	@echo "  test           - Run all tests"
	@echo "  test-unit      - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  clean          - Clean up temporary files"
	@echo "  lint           - Run shellcheck on bash scripts"
	@echo "  help           - Show this help message"
	@echo ""


test: test-unit test-integration


test-unit:
	@echo "Running unit tests..."
	@chmod +x tests/test_unit.sh
	@chmod +x src/github_activity.sh
	@bash tests/test_unit.sh


test-integration:
	@echo "Running integration tests..."
	@chmod +x tests/test_integration.sh
	@chmod +x src/github_activity.sh
	@bash tests/test_integration.sh


test-all:
	@echo "Running complete test suite..."
	@chmod +x tests/run_all_tests.sh
	@chmod +x tests/test_unit.sh
	@chmod +x tests/test_integration.sh
	@chmod +x src/github_activity.sh
	@bash tests/run_all_tests.sh


lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck src/github_activity.sh tests/*.sh || echo "Shellcheck found issues"; \
	else \
		echo "Shellcheck not found, skipping lint check"; \
	fi


clean:
	@echo "Cleaning up..."
	@find . -name "*.tmp" -delete
	@find . -name "README.tmp" -delete
	@echo "Clean complete"


setup-hooks:
	@echo "Setting up Git hooks..."
	@bash setup-hooks.sh
	