
"""conway's GOL. more object-oriented than the last one.

also has its own system of input -- a hexadecimal string where the first
four characters determine the size in 8 bits (X and Y respectively),
following a pattern of the simulation in binary, with the bottom right
corner as the first bit."""

import time

ON = 1
OFF = 0

class Board:
    """represents the board and perhaps the game itself."""
    
    def __init__(self, *, size: dict=None, s: str=None):
        self.size = None
        self.board = None

        if s is not None:
            t, b = self._from_hex(s)
            self.size = t
            self.board = b
        elif size is not None:
            self.size = size
            self.board = [[OFF for x in range(size['x'])] for y in range(size['y'])]

        self.generation = 0

    # display

    def __str__(self):
        def cell(state):
            return '██' if state == ON else '░░'
        return '\n'.join([''.join([cell(x) for x in y]) for y in self.board])

    # emulation

    def update(self):
        # board[:] won't work due to the lists inside
        new_board = [y[:] for y in self.board]
        size = self.size

        for y in range(size['y']):
            for x in range(size['x']):
                n = self.get_neighbors(x, y)

                # rules
                if self.board[y][x] == ON:
                    if n < 2 or n > 3:
                        new_board[y][x] = OFF
                else:
                    if n == 3:
                        new_board[y][x] = ON

        self.board[:] = new_board
        self.generation += 1

    def get_neighbors(self, pos_x, pos_y):
        # will wrap around board
        board = self.board
        size = self.size

        e = 0
        for y in range(pos_y - 1, pos_y + 2):
            for x in range(pos_x - 1, pos_x + 2):
                if x == pos_x and y == pos_y:
                    continue

                # mod for wrapping boundaries
                e += board[y % size['y']][x % size['x']]

        return e

    def add_pattern(self, array, *, x=0, y=0):
        # pos_x and pos_y are the coordinates on where the top left
        # corneer will be placed
        # defaults to 0, 0 on the board (top-left)

        pos_x = x
        pos_y = y

        # is it necessary to put this on a new board?
        new_board = [y[:] for y in self.board]
        array_size = {'x': len(array[0]), 'y': len(array)}

        for j in range(array_size['y']):
            for i in range(array_size['x']):
                # mod for wrap-around
                y = (pos_y + j) % self.size['y']
                x = (pos_x + i) % self.size['x']
                new_board[y][x] = array[j][i]

        self.board[:] = new_board

    # compression to text

    def to_hex(self):
        s = ''

        # size
        size = self.size
        s += hex(size['x'])[2:].zfill(2)
        s += hex(size['y'])[2:].zfill(2)

        # data
        t = ''
        for y in self.board:
            for x in y:
                t += str(x)
        s += hex(int(t, 2))[2:]

        return s

    def _from_hex(self, s):
        size = {
            'x': int(s[0:2], 16),
            'y': int(s[2:4], 16),
        }
        totalsize = size['x'] * size['y']

        b = bin(int(s[4:], 16))[2:].zfill(totalsize)

        gen = (int(x) for x in b)
        board = [[next(gen) for x in range(size['x'])] for y in range(size['y'])]
        return size, board

    @classmethod
    def from_hex(self, s):
        return Board(s=s)

    # misc.

    def __repr__(self):
        return "<Board hex='{}' generation={}>".format(self.to_hex(), self.generation)

# ways to make/manipulate a board
board = Board(size={'x': 20, 'y': 20})
board = Board.from_hex('1414a0000600004000000000000000000000')

# individual toggling
# board.board[4][5] = ON
# board.board[5][5] = ON
# board.board[6][5] = ON
# board.board[6][4] = ON
# board.board[5][3] = ON

# pattern
arr = [
    [OFF, OFF, ON ],
    [ON , OFF, ON ],
    [OFF, ON , ON ],
]

board.add_pattern(arr, x=5, y=5)

print(str(board))
print(board.to_hex())
print('generation 0')

for i in range(1, 40):
    time.sleep(.1)
    board.update()

    print(str(board))
    print(board.to_hex())
    print(f'generation {board.generation}')
    print()
