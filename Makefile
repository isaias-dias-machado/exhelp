SRCS := $(shell find lib -type f)
CONFIGS := cli-configs.env

include cli-configs.env
export

CWD := $(shell pwd)

MIX := mix
APP_NAME := exh

compile: bin/$(APP_NAME).sh

bin/$(APP_NAME).sh: bin/$(APP_NAME)
	@echo "				 Build target"
	@echo "Compiling bash wrapper template executable..."
	@sed "s,{{BUILD_PATH}},$(CWD),g" lib/wrapper.sh.in > bin/$(APP_NAME).sh
	@sed -i "s,{{CACHE_DIR}},$(EXH_CACHE_DIR),g" bin/$(APP_NAME).sh
	@sed -i "s,{{TAGS_FILE}},$(EXH_TAGS_FILE),g" bin/$(APP_NAME).sh
	@chmod 0755 bin/$(APP_NAME).sh
	@echo "Building and installing mix archive..."
	@mix archive.build
	@mix archive.install --force
	@echo "Creating cache directory..."
	@mkdir -p $$EXH_CACHE_DIR
	@echo "Done"

bin/$(APP_NAME): mix.exs $(SRCS) $(CONFIGS) 
	mix escript.build
	@mv $(APP_NAME) bin/$(APP_NAME)

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
EXECUTABLE_PATH := $(BINDIR)/$(APP_NAME)

install: bin/$(APP_NAME)
	@echo "				Install target"
	@echo "Installing executable..."
	@install -m 0755 bin/$(APP_NAME).sh $(EXECUTABLE_PATH)
	@echo "Done"

uninstall:
	@echo "				Uninstall target"
	@echo "Removing exhelp executable"
	@rm -rf $(EXECUTABLE_PATH)
	@echo "Done"

clean:
	@echo "				Clean target"
	@rm -rf bin/*
	@echo "Uninstaling exhelp mix archive"
	@mix archive.uninstall exhelp -y &2>1 >/dev/null
	@echo "Removing exhelp cache directory"
	@rm -rf $$EXH_CACHE_DIR
	@echo "Done"

help:
	@echo "Run 'make compile' followed by 'sudo make install' to install"
	@echo "To uninstall run 'sudo make uninstall'"
