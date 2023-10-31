proj=vga

prog: $(proj).svf
	unset LD_LIBRARY_PATH;openFPGALoader -c usb-blaster $(proj).svf

#program: $(proj).sof
#	sudo quartus_pgm $(proj).cdf

output_files/$(proj).sof: $(proj).v
	quartus_map $(proj)
	quartus_fit $(proj)
	quartus_asm $(proj)
	quartus_sta $(proj)

$(proj).svf: output_files/$(proj).sof
	quartus_cpf -c -q 12.0MHz -g 3.3 -n p output_files/$(proj).sof $(proj).svf

simtile:
	iverilog -DSIM tile.v -o tile
	./tile
