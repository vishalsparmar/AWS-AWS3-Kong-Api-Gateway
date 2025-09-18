.PHONY: docs
docs:
	@terraform-docs markdown table . > README.md
	@echo "Documentation generated successfully!"

.PHONY: docs-check
docs-check:
	@terraform-docs markdown table . | diff README.md - || (echo "Documentation is out of date, please run 'make docs'" && exit 1)

.PHONY: init
init:
	@terraform init
	@make docs
