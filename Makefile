ADDON   := Gearwright

REQUIRED  := clean distclean debug install uninstall deploy lint
HELP_VARS := WOW_RETAIL_ADDON_FOLDER WOW_DIR TAG DRY_RUN

## WOW_RETAIL_ADDON_FOLDER: Interface/AddOns of the retail client
WOW_RETAIL_ADDON_FOLDER ?=

## WOW_DIR: World of Warcraft folder, alternative to WOW_RETAIL_ADDON_FOLDER
WOW_DIR ?=

TOC     := $(ADDON).toc
VERSION := $(shell sed -n 's/^## Version: //p' $(TOC))

INSTALL_FILES := $(TOC) embeds.xml Bindings.xml CHANGELOG.md LICENSE
INSTALL_DIRS  := Core UI Data Locales Skin Media

DIST_DIR := dist
ZIP      := $(DIST_DIR)/$(ADDON)-$(VERSION).zip

GITHUB_URL := git@github.com:lasse-tech/gearwright.git

## TAG: release tag make github exports
TAG ?= v$(VERSION)

## DRY_RUN: 1 = make github commits in dist/github, pushes nothing
DRY_RUN ?= 0

# public export: one commit per release tag
PUBLIC_DIR   := $(DIST_DIR)/public
PUBLIC_PATHS := $(INSTALL_FILES) $(INSTALL_DIRS) README.md .pkgmeta github Makefile Makefile.bat scripts \
	.luacheckrc
PUBLIC_NAME  := Lars Gossard
PUBLIC_EMAIL := lars@lasse-tech.de

WOW_CANDIDATES := \
	"$$PROGRAMFILES/World of Warcraft" \
	"C:/Program Files (x86)/World of Warcraft" \
	"C:/Program Files/World of Warcraft" \
	"D:/World of Warcraft"

FIND_ADDONS = if [ -n "$(WOW_RETAIL_ADDON_FOLDER)" ]; then echo "$(WOW_RETAIL_ADDON_FOLDER)"; \
	elif [ -n "$(WOW_DIR)" ]; then echo "$(WOW_DIR)/_retail_/Interface/AddOns"; \
	else for d in $(WOW_CANDIDATES); do if [ -d "$$d/_retail_" ]; then echo "$$d/_retail_/Interface/AddOns"; break; fi; done; fi

NO_ADDONS_MSG = echo "AddOns folder not found. Set WOW_RETAIL_ADDON_FOLDER=/path/to/Interface/AddOns or WOW_DIR=/path/to/World of Warcraft"

.DEFAULT_GOAL := help

.PHONY: help version check check-tocs check-data luacheck lint data libs fetch-libs ensure-libs \
	debug install uninstall dist deploy public github clean distclean purge

##@ General

## help: list targets and variables
help:
	@echo "$(ADDON) $(VERSION)"
	@$(foreach v,$(HELP_VARS),$(v)='$($(v))') awk -f scripts/make-help.awk $(firstword $(MAKEFILE_LIST))

## version: print the addon version
version:
	@echo "$(VERSION)"

##@ Checks

## check: syntax-check every Lua file
check:
	@luac -p $$(find Core UI Data Locales Skin -name '*.lua' | sort) && echo "luac: all files parse"

## check-tocs: every file the TOC lists exists
check-tocs:
	@missing=0; \
	for f in $$(sed -n 's/\r$$//; s|\\|/|g; /^[A-Za-z].*\.\(lua\|xml\)$$/p' $(TOC)); do \
		[ -f "$$f" ] || { echo "  MISSING $$f (listed in $(TOC))"; missing=1; }; \
	done; \
	[ $$missing -eq 0 ] && echo "toc: every listed file exists"

## check-data: every pick in Data/ resolves
check-data:
	@lua5.1 tools/check-data.lua .

## luacheck: static analysis, any warning fails
luacheck:
	@command -v luacheck >/dev/null 2>&1 || { echo "luacheck not found (luarocks install luacheck)"; exit 1; }
	@luacheck --no-color -q . && echo "luacheck: no warnings"

## lint: luac, TOC, data, luacheck, Makefile comments (BLOCKER)
lint: check check-tocs check-data luacheck
	@awk -v required="$(REQUIRED)" -f scripts/make-lint.awk $(firstword $(MAKEFILE_LIST))
	@awk -v required="$(REQUIRED)" -v bat=1 -f scripts/make-lint.awk Makefile.bat
	@echo "make: comments ok"

##@ Data and libraries

## data: rebuild Data/Specs.lua (Battle.net API, Raider.IO, wago.tools), takes about 45 minutes
data:
	@python3 -u tools/fetch_data.py
	@$(MAKE) --no-print-directory check-data

AWK_EXTERNALS := /^externals:/{e=1;next} /^[a-zA-Z]/{e=0} e&&/^  [^ \#]/{sub(/:$$/,"",$$1);p=$$1;next} e&&p&&$$1=="url:"{print p, $$2; p=""}

LIBS_MISSING = for lib in $$(tr '\134' '/' < embeds.xml | sed -n 's|.*Libs/\([^/]*\)/.*|\1|p' | sort -u); do \
	[ -d "Libs/$$lib" ] || echo "$$lib"; done

## libs: report libraries missing from Libs/
libs:
	@missing=$$($(LIBS_MISSING)); \
	if [ -n "$$missing" ]; then echo "missing in Libs/:" $$missing; else echo "Libs/ complete"; fi

## fetch-libs: download the .pkgmeta externals into Libs/
fetch-libs:
	@command -v svn >/dev/null 2>&1 || { echo "svn not found"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "git not found"; exit 1; }
	@awk '$(AWK_EXTERNALS)' .pkgmeta | while read -r path url; do \
		[ -n "$$path" ] && [ -n "$$url" ] || continue; \
		rm -rf "$$path"; \
		case "$$url" in \
			*github.com*) git clone -q --depth 1 "$$url" "$$path.tmp" && rm -rf "$$path.tmp/.git" \
				&& mv "$$path.tmp" "$$path" || exit 1;; \
			*) svn export -q --force --non-interactive "$$url" "$$path" || exit 1;; \
		esac; \
		echo "  fetched $$path"; \
	done
	@sed -n '/^ignore:/,$$p' .pkgmeta | sed -n 's|^  - \(Libs/[^/]*/.*\)$$|\1|p' | while read -r p; do \
		[ -e "$$p" ] && rm -rf "$$p" && echo "  dropped $$p (ignored by .pkgmeta, fetched just now)"; true; \
	done
	@find Libs -name .pkgmeta -delete 2>/dev/null; true

ensure-libs:
	@if [ -n "$$($(LIBS_MISSING))" ]; then \
		echo "Libs/ incomplete - fetching"; $(MAKE) --no-print-directory fetch-libs || exit 1; fi
	@missing=$$($(LIBS_MISSING)); if [ -n "$$missing" ]; then echo "still missing:" $$missing; exit 1; fi

##@ Client

## install: copy the addon into the client
install: ensure-libs lint
	@addons=$$($(FIND_ADDONS)); \
	if [ -z "$$addons" ]; then $(NO_ADDONS_MSG); exit 1; fi; \
	target="$$addons/$(ADDON)"; \
	rm -rf "$$target"; \
	mkdir -p "$$target"; \
	for d in $(INSTALL_DIRS) Libs; do cp -r "$$d" "$$target/"; done; \
	for f in $(INSTALL_FILES); do cp "$$f" "$$target/"; done; \
	echo "installed $(ADDON) $(VERSION) -> $$target - /reload in game"

## debug: link the working copy into the client (edit, then /reload)
debug: ensure-libs
	@addons=$$($(FIND_ADDONS)); \
	if [ -z "$$addons" ]; then $(NO_ADDONS_MSG); exit 1; fi; \
	target="$$addons/$(ADDON)"; \
	rm -rf "$$target"; \
	mkdir -p "$$target"; \
	for d in $(INSTALL_DIRS); do ln -s "$(CURDIR)/$$d" "$$target/$$d"; done; \
	for f in $(INSTALL_FILES); do ln -s "$(CURDIR)/$$f" "$$target/$$f"; done; \
	cp -r Libs "$$target/"; \
	echo "linked $(ADDON) (working copy) -> $$target - /reload after each edit"

## uninstall: remove the addon, SavedVariables stay
uninstall:
	@addons=$$($(FIND_ADDONS)); \
	if [ -z "$$addons" ]; then $(NO_ADDONS_MSG); exit 1; fi; \
	target="$$addons/$(ADDON)"; \
	if [ ! -e "$$target" ]; then echo "not installed: $$target"; exit 0; fi; \
	rm -rf "$$target" && echo "removed $$target"; \
	echo "SavedVariables kept - 'make purge' deletes them"

## purge: uninstall and delete the SavedVariables
purge:
	@$(MAKE) --no-print-directory uninstall
	@addons=$$($(FIND_ADDONS)); \
	if [ -z "$$addons" ]; then $(NO_ADDONS_MSG); exit 1; fi; \
	wtf=$$(dirname "$$(dirname "$$addons")")/WTF; found=0; \
	for f in "$$wtf"/Account/*/SavedVariables/$(ADDON).lua*; do \
		[ -e "$$f" ] || continue; found=1; \
		rm -f "$$f" && echo "  deleted $$f"; \
	done; \
	[ $$found -eq 1 ] || echo "no SavedVariables found"

##@ Release

## dist: build dist/Gearwright-<version>.zip
dist: ensure-libs lint
	@rm -f "$(ZIP)"
	@mkdir -p $(DIST_DIR)/stage/$(ADDON)
	@for d in $(INSTALL_DIRS) Libs; do cp -r "$$d" $(DIST_DIR)/stage/$(ADDON)/; done
	@for f in $(INSTALL_FILES); do cp "$$f" $(DIST_DIR)/stage/$(ADDON)/; done
	@cd $(DIST_DIR)/stage && zip -qr "../$(ADDON)-$(VERSION).zip" $(ADDON)
	@rm -r $(DIST_DIR)/stage
	@echo "built $(ZIP)"

## deploy: none - a v* tag pushed to Forgejo is exported to GitHub and packaged there
deploy:
	@echo "No deploy: git tag v$(VERSION) && git push origin main v$(VERSION)"

# github/gitattributes: renamed on export (git archive would apply it to github/)
# $(call public-tree,<ref>,<out dir>)
define public-tree
	rm -rf "$(2)" && mkdir -p "$(2)"
	git archive "$(1)" $(PUBLIC_PATHS) | tar -x -C "$(2)"
	cp -r "$(2)/github/." "$(2)/" && rm -r "$(2)/github"
	mv "$(2)/gitattributes" "$(2)/.gitattributes"
endef

## public: build the public export of HEAD into dist/public
public:
	$(call public-tree,HEAD,$(PUBLIC_DIR))
	@cd $(PUBLIC_DIR) && find . -type f | sort

## github: export TAG to GitHub as one commit and tag it
github:
	@git rev-parse -q --verify "refs/tags/$(TAG)" >/dev/null || { echo "tag $(TAG) not found"; exit 1; }
	@! git ls-remote --exit-code --tags $(GITHUB_URL) "refs/tags/$(TAG)" >/dev/null || { echo "$(TAG) is on GitHub already"; exit 1; }
	$(call public-tree,$(TAG),$(PUBLIC_DIR))
	rm -rf $(DIST_DIR)/github && git clone -q $(GITHUB_URL) $(DIST_DIR)/github
	@cd $(DIST_DIR)/github && git checkout -q -B main \
		&& find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} + \
		&& cp -r ../public/. . && git add -A \
		&& GIT_AUTHOR_NAME="$(PUBLIC_NAME)" GIT_AUTHOR_EMAIL="$(PUBLIC_EMAIL)" \
		GIT_COMMITTER_NAME="$(PUBLIC_NAME)" GIT_COMMITTER_EMAIL="$(PUBLIC_EMAIL)" \
		git commit -qm "$(ADDON) $(TAG:v%=%)" && git tag "$(TAG)" \
		&& git show --format="%h %s" --stat=100 HEAD | sed '$$d'
	@if [ "$(DRY_RUN)" = "1" ]; then echo "DRY_RUN=1: nothing pushed, see $(DIST_DIR)/github"; \
	else cd $(DIST_DIR)/github && git push -q origin main "refs/tags/$(TAG)" && echo "pushed $(TAG) to GitHub"; fi

## clean: remove dist/ and the data cache
clean:
	@rm -rf $(DIST_DIR) .cache; echo "clean"

## distclean: clean and empty Libs/
distclean: clean
	@rm -rf Libs; echo "distclean"
