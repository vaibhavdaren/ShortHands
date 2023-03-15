###########################################################
# Author: Vaibhav Aren <vaibhavdaren@gmail.com> 2023-03-15
###########################################################


import subprocess


def column_width(rows, column_index):
    return max(len(str(row[column_index])) for row in rows)


def is_table(data):
    # Very simple check to see if data might represent a table
    return data.count('\t') > 1


def excel_to_markdown(excel_data):
    rows = [line.split('\t') for line in excel_data.splitlines()]
    col_widths = [column_width(rows, i) for i in range(len(rows[0]))]

    # Create the markdown table
    markdown_rows = []
    markdown_rows.append('| ' + ' | '.join(rows[0][i].ljust(col_widths[i]) for i in range(len(rows[0]))) + ' |')
    markdown_rows.append('| ' + ' | '.join(''.ljust(col_widths[i], '-') for i in range(len(rows[0]))) + ' |')
    for row in rows[1:]:
        markdown_rows.append('| ' + ' | '.join(row[i].ljust(col_widths[i]) for i in range(len(row))) + ' |')

    return '\n'.join(markdown_rows)


def read_from_clipboard():
    return subprocess.check_output(
        'pbpaste', env={'LANG': 'en_US.UTF-8'}).decode('utf-8')


def write_to_clipboard(output):
    process = subprocess.Popen(
        'pbcopy', env={'LANG': 'en_US.UTF-8'}, stdin=subprocess.PIPE)
    process.communicate(output.encode('utf-8'))


if __name__ == '__main__':
    xls_data = read_from_clipboard()
    if is_table(xls_data):
        markdown_table = excel_to_markdown(xls_data)
        print(markdown_table)
        write_to_clipboard(markdown_table)
    else:
        print('Input data does not appear to be a table')

# this script converts xls data that you have copied from somewhere to markdown and changes it inplace to markdown data 
