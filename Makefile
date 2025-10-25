SRCS := $(shell find lib -type f)
WRAPPER := bin/exh.sh
BINARY := bin/exh
WRAPPER_IN := priv/wrapper.sh.in

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
LIBEXECDIR := $(PREFIX)/libexec

INSTALLED_WRAPPER := $(BINDIR)/exh
INSTALLED_BINARY := $(LIBEXECDIR)/exh

help:
	@echo "Run 'make compile' followed by 'sudo make install' to install"
	@echo "To uninstall run 'sudo make uninstall'"

compile: bin $(WRAPPER) $(BINARY)

bin:
	mkdir -p bin

$(WRAPPER): $(WRAPPER_IN)
	@echo "Compiling bash script dev wrapper..."
	@sed "s,{{EXEC_DIR}},$(CURDIR),g" $(WRAPPER_IN) > $(WRAPPER)
	@chmod +x $(WRAPPER)

$(BINARY): mix.exs $(SRCS)
	@echo "Compiling escript..."
	@mix escript.build
	@echo "Building and installing mix archive..."
	@mix archive.install --force
	@rm -f exhelp-*
	@mv exh bin

install:
	@if [ ! -f $(BINARY) ]; then \
		echo "Error: Run 'make compile' first (without sudo)"; \
		exit 1; \
	fi
	@echo "Installing cli binary..."
	@install -d $(DESTDIR)$(BINDIR)
	@install -d $(DESTDIR)$(LIBEXECDIR)
	@echo "Compiling and installing cli wrapper..."
	@sed 's,{{EXECUTABLE}},$(INSTALLED_BINARY),g' $(WRAPPER_IN) | \
		install -m 755 /dev/stdin $(DESTDIR)$(INSTALLED_WRAPPER)
	@install -m 755 $(BINARY) $(DESTDIR)$(INSTALLED_BINARY)

uninstall:
	@echo "Removing exhelp executables..."
	@rm -f $(DESTDIR)$(INSTALLED_WRAPPER)
	@rm -f $(DESTDIR)$(INSTALLED_BINARY)

clean:
	@rm -rf bin/*
	@echo "Uninstaling exhelp mix archive..."
	@mix archive.uninstall exhelp --force 2>/dev/null || true

.PHONY: help compile install uninstall clean
