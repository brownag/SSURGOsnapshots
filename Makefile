# Makefile for SSURGOsnapshots package development

.PHONY: all build check install test document clean

# Default target
all: document build check

# Build the package
build:
	R CMD build .

# Check the package
check:
	R CMD check --no-manual --no-vignettes SSURGOsnapshots_*.tar.gz

# Install the package
install:
	R CMD INSTALL SSURGOsnapshots_*.tar.gz

# Run tests
test:
	Rscript -e "devtools::test()"

# Generate documentation
document:
	Rscript -e "devtools::document()"

# Clean up build artifacts
clean:
	rm -f SSURGOsnapshots_*.tar.gz
	rm -rf SSURGOsnapshots.Rcheck