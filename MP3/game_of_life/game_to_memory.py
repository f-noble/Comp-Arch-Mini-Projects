"""game_to_memory.py
converts game of life input file created using bits to a memory input file
uses an 8x8 grid and wraps the game around the edges of the grid
to act more like an infinite grid
"""

import argparse as ap # command line arguments
import re # regular expressions to confirm input file formatting

parser = ap.ArgumentParser()
_ = parser.add_argument("infile", help="the input file. must have 8 8-char\
        lines containing only 1s or 0s. Can have an additional starting line\
         of the form 'iter=NUMBER' representing how many times to iterate on\
          the game, from the simulator format")
parser.add_argument("outfile", help="file in a format that can be uploaded to fpga board memory")
args = parser.parse_args()

# confirm that line is 'iter=SOME_NUMBER'
iter_line = re.compile('^iter=[0-9]+$') 
infile = args.infile
outfile = args.outfile
lines = [0 for _ in range(8)]

print("opening ",infile)

with open(infile,"r") as file:
    
    line = file.readline()

    # set num of iterations if specified by file and not overridden by cmd args
    iter_match = iter_line.match(line)
    if(iter_match is not None):
        line = file.readline()
    print("input game state:")

    # print and save start condition to lines. check formatting
    for row in range(8):
        print(line,end='')
        assert(len(line) == 9 and line[8] == '\n')
        for col in range(8):
            assert((line[col] == '0') or (line[col] == '1'))
        lines[row] = int(line,2)
        print(type(lines[row]))
        line = file.readline()
    assert(line == "")

# output each row as a 2-digit hex number in outfile
with open(outfile, "w") as file:
    for row in range(8):
        write_line = lines[row]
        file.write(format(write_line,"02x")+"\n")
