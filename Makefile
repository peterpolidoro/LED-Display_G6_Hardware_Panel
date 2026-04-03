KICAD_CONFIG_HOME := $(CURDIR)/.guix/.config/kicad
XDG_CACHE_HOME := /tmp/codex-kicad-cache
GUIX_TIME_MACHINE = guix time-machine -C .guix/channels.scm
GUIX_SHELL = $(GUIX_TIME_MACHINE) -- shell --pure -m .guix/manifest.scm
KICAD_ENV = KICAD_CONFIG_HOME=$(KICAD_CONFIG_HOME) XDG_CACHE_HOME=$(XDG_CACHE_HOME)
KICAD_SHELL = $(KICAD_ENV) $(GUIX_SHELL) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" --
KICAD_CLI = $(KICAD_SHELL) kicad-cli

PROJECT_DIR ?= panel_rp2354_20x20_v0p2
PROJECT_NAME ?= panel_rp2354_20x20
SCH ?= $(PROJECT_DIR)/$(PROJECT_NAME).kicad_sch
PCB ?= $(PROJECT_DIR)/$(PROJECT_NAME).kicad_pcb
PRODUCTION_DIR ?= production/v0p2r0
ZIP_NAME ?= G6_panel_45mm_RP2354_v0.2.0.zip
FAB_FILES = \
	$(PROJECT_NAME)-NPTH-drl_map.gbr \
	$(PROJECT_NAME)-PTH-drl_map.gbr \
	$(PROJECT_NAME)-NPTH.drl \
	$(PROJECT_NAME)-PTH.drl \
	$(PROJECT_NAME)-Edge_Cuts.gm1 \
	$(PROJECT_NAME)-B_Paste.gbp \
	$(PROJECT_NAME)-F_Paste.gtp \
	$(PROJECT_NAME)-In4_Cu.g4 \
	$(PROJECT_NAME)-In3_Cu.g3 \
	$(PROJECT_NAME)-B_Silkscreen.gbo \
	$(PROJECT_NAME)-In2_Cu.g2 \
	$(PROJECT_NAME)-F_Silkscreen.gto \
	$(PROJECT_NAME)-In1_Cu.g1 \
	$(PROJECT_NAME)-B_Mask.gbs \
	$(PROJECT_NAME)-B_Cu.gbl \
	$(PROJECT_NAME)-F_Mask.gts \
	$(PROJECT_NAME)-F_Cu.gtl
# Start Codex in this repo with the KiCad toolchain using:
# codex-guix-shell --channels-file .guix/channels.scm --manifest .guix/manifest.scm .
# codex-guix-shell does not auto-discover manifests under .guix/, so both files
# need to be passed explicitly.

.PHONY: guix-shell kicad-edits erc drc production clean-production-dir
guix-shell:
	$(GUIX_SHELL)

kicad-edits:
	mkdir -p $(KICAD_CONFIG_HOME)
	mkdir -p $(XDG_CACHE_HOME)
	$(KICAD_SHELL) kicad

erc:
	mkdir -p $(XDG_CACHE_HOME) $(PRODUCTION_DIR)
	$(KICAD_CLI) sch erc --severity-error --severity-warning --exit-code-violations \
		-o $(PRODUCTION_DIR)/ERC.rpt $(SCH)

drc:
	mkdir -p $(XDG_CACHE_HOME) $(PRODUCTION_DIR)
	$(KICAD_CLI) pcb drc --severity-error --severity-warning --exit-code-violations \
		-o $(PRODUCTION_DIR)/DRC.rpt $(PCB)

production: erc drc
	mkdir -p $(XDG_CACHE_HOME) $(PRODUCTION_DIR)
	$(KICAD_CLI) pcb export gerbers --board-plot-params -o $(PRODUCTION_DIR) $(PCB)
	$(KICAD_CLI) pcb export drill --excellon-separate-th --generate-map --map-format gerberx2 \
		-o $(PRODUCTION_DIR) $(PCB)
	cd $(PRODUCTION_DIR) && zip -q $(ZIP_NAME) $(FAB_FILES)
