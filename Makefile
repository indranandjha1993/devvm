PREFIX ?= /usr/local
BINDIR  = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/devvm
COMPDIR_BASH = $(PREFIX)/etc/bash_completion.d
COMPDIR_ZSH  = $(PREFIX)/share/zsh/site-functions

.PHONY: install uninstall link build

build:
	@echo "Nothing to build (pure bash). Ready to install."

install:
	@echo "Installing devvm to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 cli/dev $(BINDIR)/devvm
	@install -d $(SHAREDIR)
	@cp -R cloud-init provision observability systemd vscode demo-apps $(SHAREDIR)/
	@cp verify.sh setup.sh $(SHAREDIR)/
	@install -d $(COMPDIR_BASH) $(COMPDIR_ZSH)
	@install -m 644 completions/devvm.bash $(COMPDIR_BASH)/devvm
	@install -m 644 completions/_devvm $(COMPDIR_ZSH)/_devvm
	@echo "Installed. Run 'devvm help' to get started."

uninstall:
	@echo "Removing devvm..."
	@rm -f $(BINDIR)/devvm
	@rm -rf $(SHAREDIR)
	@rm -f $(COMPDIR_BASH)/devvm
	@rm -f $(COMPDIR_ZSH)/_devvm
	@echo "Removed."

link:
	@echo "Symlinking devvm to $(BINDIR)..."
	@ln -sf $(CURDIR)/cli/dev $(BINDIR)/devvm
	@echo "Linked. Changes to cli/dev take effect immediately."
