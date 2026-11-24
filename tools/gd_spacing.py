"""Project GDScript spacing layered over gdformat's syntax formatting."""

from lark import Tree
from gdtoolkit.formatter import format_code
from gdtoolkit.formatter.safety_checks import check_tree_invariant
from gdtoolkit.parser import parser

CONTROL = {"if_stmt", "for_stmt", "while_stmt", "match_stmt"}


def format_readable(source):
    formatted = format_code(source, max_line_length=100)
    tree = parser.parse(formatted, gather_metadata=True)
    lines = formatted.splitlines()
    insert_before = set()

    # Use parsed sibling statements: never insert whitespace inside expressions,
    # multiline literals, argument lists, or between an if and its else branch.
    for block in tree.iter_subtrees():
        statements = [
            child
            for child in block.children
            if isinstance(child, Tree)
            and (str(child.data).endswith("_stmt") or child.data == "func_def")
        ]
        for previous, current in zip(statements, statements[1:]):
            if current.meta.line <= previous.meta.line:
                continue
            boundary = (
                previous.data in CONTROL
                or current.data in CONTROL
                or current.data == "return_stmt"
                or (
                    previous.data == "func_var_stmt" and current.data != "func_var_stmt"
                )
            )
            if boundary:
                insert_before.add(current.meta.line - 1)

    # gdformat hardcodes two blank lines around functions. Collapse only the
    # whitespace immediately preceding parsed function declarations.
    remove = set()
    for function in tree.find_data("func_def"):
        index = function.meta.line - 2
        while index >= 0 and not lines[index].strip():
            remove.add(index)
            index -= 1
        if index >= 0:
            insert_before.add(function.meta.line - 1)

    result = []
    for index, line in enumerate(lines):
        if index in remove:
            continue
        if index in insert_before and result and result[-1].strip():
            result.append("")
        result.append(line)
    output = "\n".join(result) + "\n"
    check_tree_invariant(source, output)
    return output
