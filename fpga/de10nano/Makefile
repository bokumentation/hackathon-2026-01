QUARTUS_SH ?= quartus_sh
QUARTUS_PGM ?= quartus_pgm
PROJECT = de10nano_top
SOF = output_files/$(PROJECT).sof

.PHONY: all
all: sof

.PHONY: sof
sof:
	$(QUARTUS_SH) --flow compile $(PROJECT)

.PHONY: program
program:
	$(QUARTUS_PGM) -m jtag -o "p;$(SOF)"

.PHONY: clean
clean:
	rm -rf db incremental_db output_files
	rm -f *.qws *.rpt *.summary
