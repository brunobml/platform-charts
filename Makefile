.PHONY: all lint package-all push-all clean help

all: help

help:
	@echo "Platform Engineering Golden Path Charts:"
	@echo "  make lint         - Lint all Helm charts"
	@echo "  make package-all  - Package and push all charts to OCI registry"
	@echo "  make clean        - Remove packaged .tgz artifacts"

lint:
	@for chart in charts/*; do \
		if [ -d "$$chart" ]; then \
			echo "==> Linting $$chart..."; \
			if ls "$$chart"/ci/*-values.yaml >/dev/null 2>&1; then \
				for v in "$$chart"/ci/*-values.yaml; do helm lint "$$chart" -f "$$v" || exit 1; done; \
			else \
				helm lint "$$chart" --set image=placeholder:latest; \
			fi; \
		fi \
	done

package-all:
	@for chart in charts/*; do \
		if [ -d "$$chart" ]; then \
			cname=$$(basename "$$chart"); \
			bash scripts/package-and-push.sh "$$cname"; \
		fi \
	done

clean:
	@rm -rf dist/
