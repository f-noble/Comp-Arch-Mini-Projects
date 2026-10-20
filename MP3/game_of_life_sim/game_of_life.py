"""game_of_life.py
provides options to run iterations of the game of life from a file
and save them to a new file
uses an 8x8 grid and wraps the game around the edges of the grid
to act more like an infinite grid
"""

import argparse as ap # command line arguments
import re # regular expressions to confirm input file formatting

parser = ap.ArgumentParser()
_ = parser.add_argument("infile", help="the input file. must have 8 8-char\
        lines containing only 1s or 0s. Can have an additional starting line\
         of the form 'iter=NUMBER' representing how many times to iterate on\
          the game")
_ = parser.add_argument("-i", "--iterations", type=int, help="number of times\
           to iterate upon the input matrix")
parser.add_argument("-o", "--outfile", help="file to output the last state of\
                     the game after all planned iterations")
args = parser.parse_args()

# confirm that line is 'iter=SOME_NUMBER'
iter_line = re.compile('^iter=[0-9]+$') 
infile = args.infile
outfile = args.outfile
iterations_left = args.iterations
lines = [[0 for _ in range(8)] for _ in range(8)]

print("opening ",infile)

# run 10 iterations by default
if iterations_left is None:
    iterations_left = 10

with open(infile,"r") as file:
    
    line = file.readline()

    # set num of iterations if specified by file and not overridden by cmd args
    iter_match = iter_line.match(line)
    if(iter_match is not None):
        if(args.iterations is None):
            iterations_left = int(line[5:-1])
        line = file.readline()
    print("running ",iterations_left," iterations")
    print("starting state:")

    # print and save start condition to lines. check formatting
    for row in range(8):
        print(line,end='')
        assert(len(line) == 9 and line[8] == '\n')
        for col in range(8):
            assert((line[col] == '0') or (line[col] == '1'))
            lines[row][col] = int(line[col])
        line = file.readline()
    assert(line == "")


print("starting iterations")
new_lines = [[0 for _ in range(8)] for _ in range(8)]
while(iterations_left > 0):
    print(iterations_left,"iterations left")
    for row in range(8):
        printstr = ""
        for col in range(8):
            # game of life rules for each grid square
            # modulo operator wraps adjacent indices around edges of grid
            top_sum = lines[(row-1)%8][(col-1)%8]\
                +lines[(row-1)%8][col]\
                    +lines[(row-1)%8][(col+1)%8]
            mid_sum = lines[row][(col-1)%8]\
               +lines[row][(col+1)%8]
            bottom_sum = lines[(row+1)%8][(col-1)%8]\
                +lines[(row+1)%8][col]\
                    +lines[(row+1)%8][(col+1)%8]
            n_sum = top_sum + mid_sum + bottom_sum
            assert(top_sum >= 0 and top_sum <=3)
            assert(mid_sum >= 0 and mid_sum <=2)
            assert(bottom_sum >= 0 and bottom_sum <=3)
            if(lines[row][col] == 1):
                new_lines[row][col] = int(n_sum==2 or n_sum==3)
            else:
                new_lines[row][col] = int(n_sum==3)
                
                
            printstr = printstr+str(new_lines[row][col])
        print(printstr)
    lines = [a_row[:] for a_row in new_lines]
    iterations_left -= 1
print("done")

# save to output file. not yet implemented. 
if (outfile is None):
    outfile = "gameoflife_output"
    print("no outfile specified. outputting to:",outfile)
else:
    print("outputting to:",outfile)

