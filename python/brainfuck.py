
"""a simple parser for brainfuck. can be imported"""

def _update_memory(memory, cell_head, size):
    memory += [0] * (cell_head+1 - len(memory))
    if size and len(memory) > size:
        raise MemoryError('memory exceeding maximum cell count ({})'.format(size))
    return memory

class Results:
    """Represents the results of a brainfuck parse."""

    # maybe i should use @dataclass for this?

    def __init__(self, *args, **kwargs):
        for x, y in kwargs.items():
            setattr(self, f"_{x}", y)

    @property
    def input(self) -> str:
        """The inputted brainfuck string."""
        return self._input

    @property
    def clean_input(self):
        """The inputted brainfuck string, containing only valid brainfuck characters."""
        return ''.join(filter(lambda x: x in '+-<>[].,', self._input))
    
    @property
    def output(self) -> str:
        """The output of the brainfuck."""
        return self._output

    @property
    def operations(self) -> int:
        """The number of operations done on the brainfuck parse."""
        return self._operations

    @property
    def memory(self) -> list:
        """The state of memory at the end of the parse."""
        return self._memory

    @property
    def inputs(self) -> list:
        """The inputs passed during the parse."""
        return self._inputs

def parse(p, *, inputs=[], limit=None, size=None, verbose=False, results=False) -> str or Results:
    """Parses brainfuck code and returns its output.

    Characters aside from the default eight will simply be ignored.
    Blank inputs will be passed in as ASCII character 0x00.

    p:          the string in brainfuck to parse.
    inputs:     a list of strings to insert whenever an input is prompted.
                the strings must only contain one character per item.
    limit:      the top limit of each memory cell. incrementing values over
                this limit will wrap the cell's value back to 0.
    size:       the maximum amount of cells to use in memory.
    verbose:    prints the inner workings of the parse onto the console.
    results:    returns a Results object containing details about the parse.
    """

    for x in inputs:
        if not isinstance(x, str):
            raise SyntaxError('expected a string of length 1, but {0.__class__.__name__} was found ("{0}")'.format(x))
        elif len(x) != 1:
            raise SyntaxError('expected a string of length 1, but a string of length {1} was found ("{0}")'.format(x, len(x)))

    _inputs = (x for x in inputs)

    memory = []
    output = ''

    operations = 0
    references = []
    cell_head = 0
    frozen = False
    frozen_at = None
    i = 0

    def _print(*args):
        if verbose:
            print(*args)

    while i < len(p):
        x = p[i]

        # loop skipping

        if frozen and x not in ['[', ']']:
            i += 1
            operations += 1
            _print(cell_head, memory, 'action:', x, 'references:', references)
            continue

        # memory increment/decrement

        if x == '+':
            memory = _update_memory(memory, cell_head, size)
            memory[cell_head] += 1
            if limit and memory[cell_head] > limit:
                memory[cell_head] = 0

        elif x == '-':
            memory = _update_memory(memory, cell_head, size)
            memory[cell_head] -= 1

        # loop logic

        elif x == '[':
            # update memory to cell_head for zero checking
            memory = _update_memory(memory, cell_head, size)
            references.append(i+1)

            # zero values will skip ahead to the next matching "]"
            if memory[cell_head] == 0 and not frozen:
                frozen_at = len(references) - 1
                frozen = True
        elif x == ']':
            # will use the references list to check whether this "]"
            # is on the same level as when the freeze started
            if frozen:
                references.pop()
                if len(references) == frozen_at:
                    frozen = False
            else:
                memory = _update_memory(memory, cell_head, size)
                if memory[cell_head] == 0:
                    references.pop()
                else:
                    i = references[-1]
                    operations += 1
                    _print(cell_head, memory, 'action:', x, 'references:', references)
                    continue

        # memory movement logic

        elif x == '>':
            cell_head += 1
        elif x == '<':
            cell_head -= 1 if cell_head > 0 else 0

        # i/o logic

        elif x == '.':
            _chr = chr(memory[cell_head])
            _print('output character {0}: {1!r}'.format(memory[cell_head], _chr))
            output += _chr
        elif x == ',':
            try:
                c = next(_inputs)
            # will fallback to normal input when input list is exhausted
            except StopIteration:
                c = input(' enter input: ') or '\x00'

            _ord = ord(c)
            _print('input character {0}: {1!r}'.format(_ord, c))

            memory = _update_memory(memory, cell_head, size)
            memory[cell_head] = _ord

        else:
            i += 1
            continue

        i += 1
        operations += 1
        _print(cell_head, memory, 'action:', x, 'references:', references)

    # raises an error on open brackets
    if references:
        raise ValueError('a square bracket was left open at position {}'.format(references[0] - 1))

    if results:
        return Results(
            output=output,
            operations=operations,
            memory=memory,
            input=p,
            inputs=inputs)
    else:
        return output
