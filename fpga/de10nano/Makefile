QUARTUS_SH ?= quartus_sh
QUARTUS_PGM ?= quartus_pgm
PROJECT = de10nano_top
SOF = output_files/$(PROJECT).sof

LINK_PROJECT = link_demo_top
LINK_SOF = output_files/$(LINK_PROJECT).sof

.PHONY: all
all: sof

.PHONY: sof
sof:
	$(QUARTUS_SH) --flow compile $(PROJECT)

.PHONY: link
link:
	$(QUARTUS_SH) --flow compile $(LINK_PROJECT)

.PHONY: program
program:
	$(QUARTUS_PGM) -m jtag -o "p;$(SOF)"

.PHONY: program-link
program-link:
	$(QUARTUS_PGM) -m jtag -o "p;$(LINK_SOF)"

.PHONY: clean
clean:
	rm -rf db incremental_db output_files
	rm -f *.qws *.rpt *.summary
