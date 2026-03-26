PREFIX   ?= /usr/local
BINDIR    = $(PREFIX)/bin
SHAREDIR  = $(PREFIX)/share/devvm
BASH_COMP = $(PREFIX)/etc/bash_completion.d
ZSH_COMP  = $(PREFIX)/share/zsh/site-functions

.PHONY: build install uninstall link

build:
	@echo "Nothing to build (pure bash). Ready to install."

install: build
	@echo "Installing devvm..."
	@install -d $(BINDIR) $(SHAREDIR)
	@install -m 755 cli/dev $(BINDIR)/devvm
	@cp -R cloud-init provision observability systemd vscode $(SHAREDIR)/
	@cp verify.sh $(SHAREDIR)/
	@install -d $(BASH_COMP) $(ZSH_COMP)
	@install -m 644 completions/devvm.bash $(BASH_COMP)/devvm
	@install -m 644 completions/_devvm $(ZSH_COMP)/_devvm
	@echo ""
	@echo "Done. Run 'devvm init' to set up your dev machine."

uninstall:
	@echo "Removing devvm..."
	@rm -f $(BINDIR)/devvm
	@rm -rf $(SHAREDIR)
	@rm -f $(BASH_COMP)/devvm $(ZSH_COMP)/_devvm
	@echo "Removed."

link:
	@echo "Symlinking devvm..."
	@ln -sf $(CURDIR)/cli/dev $(BINDIR)/devvm
	@echo "Linked. Edits to cli/dev take effect immediately."
