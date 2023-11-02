# Embed the Quartus qenv.sh here as it depends on private libraries
QUARTUS_BINDIR=$(HOME)/intelFPGA_lite/21.1/quartus/linux64
Q=LD_LIBRARY_PATH=$(QUARTUS_BINDIR): $(QUARTUS_BINDIR)/

proj=vga

prog: $(proj).svf
	openFPGALoader -c usb-blaster $(proj).svf

#program: $(proj).sof
#	sudo quartus_pgm $(proj).cdf

output_files/$(proj).sof: $(proj).v tile.v edgeeqn.v pll.v vga.qsf fpga.v clock.v
	$(Q)quartus_map $(proj)
	$(Q)quartus_fit $(proj)
	$(Q)quartus_asm $(proj)
	$(Q)quartus_sta $(proj)

$(proj).svf: output_files/$(proj).sof
	$(Q)quartus_cpf -c -q 12.0MHz -g 3.3 -n p output_files/$(proj).sof $(proj).svf

simtile:
	iverilog -DSIM tile.v -o tile
	./tile

simedgeeqn:
	iverilog -DSIM edgeeqn.v -o edgeeqn
	./edgeeqn

yosys:;yosys -p "synth_ecp5 -top tt_um_no_time_for_squares_tommythorn -json foobar" tt_um_no_time_for_squares_tommythorn.v clock.v vga.v tile.v

simvga:
	iverilog -DSIMVGA vga.v -o vga
	./vga

simclock:
	iverilog -DSIMCLOCK clock.v vga.v tile.v -o clock
	./clock
