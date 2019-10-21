# encoding: utf-8
"""
=====
Unity's shaders re-formatter
=====

-----
MIT License
-----

Copyright (c) 2019 `Lex Darlog <https://github.com/Lex-DRL>`_

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=====
Description
=====

This script re-formats all the Unity's `.shader` and `.cginc` files, making them
compliant to my code style. It just fixes:
	* spaces-to-tabs
	* macro indents

This is just a script for my personal use, so it's far from a complete tool.
I don't endorse you to use it but I also don't mind if you want to.

-----
Usage
-----

Unfortunately, you can't just run this script if you don't know me in person.
It depends on my external `drl_common` package I don't publicly share yet
(and don't intend to).
A few service functions from that package is used, that perform
a high-level (file encoding- and python-version-independent) reads and writes
to files.

So you have two options:
	* replace those lines with a built-in file-treating functions.
	*
		never call this script directly from a command line and only
		use it as a module with the main `reformat_line` function in your own
		wrapper script, also never calling the other (`reformat_file`) function.

Keep in mind, however, that some Unity's cgincs contain a non-ASCII characters
(which most likely are just typos of some european guy), which caused some
troubles on attempt to read thos efiles with Python2's default `open()`
and which were very difficult to find. So I guess, you'll **NEED** to read
those files with a right encoding, after all. Using `io.open()`.

After you've done that step, it's just a matter of selecting all the
shader-related files (`.shader`, `.glslinc`, `.cginc`, `.compute`) and
drag-n-dropping them to this script.
Or, from a command line:

::

	python.exe reformat_cgincs.py "path/to/file1.cginc" "path/to/file2.cginc" ...

Some manual fixes are still required, but there's just a couple of them -
related to intentionally put multiple-spaces. It's much easier to manually
restore them with your git client's diff.

"""

__author__ = 'Lex Darlog (DRL)'

# region the regular Type-Hint stuff

try:
	# support type hints in Python 3:
	# noinspection PyUnresolvedReferences
	import typing as _t
except ImportError:
	pass

# noinspection PyBroadException
try:
	str_hint = _t.Union[str, unicode]
except:
	# noinspection PyBroadException
	try:
		str_hint = _t.Union[str, bytes]
	except:
		str_hint = str

# noinspection PyBroadException
try:
	str_t = (str, unicode)
except:
	str_t = (bytes, str)

# endregion

import re as _re

# region RE's

_re_indent_spaces_4 = _re.compile('^(\t*) {4}')
_re_indent_spaces_3 = _re.compile('^(\t*) {3}')
_re_indent_spaces_2 = _re.compile('^(\t*) {2}')
_re_indent_spaces_1 = _re.compile('^(\t*) ')

_re_comment_spaces_4 = _re.compile('^(\t*/[/*]+\t*) {4}')
_re_comment_spaces_3 = _re.compile('^(\t*/[/*]+\t*) {3}')
_re_comment_spaces_2 = _re.compile('^(\t*/[/*]+\t*) {2}')
_re_comment_spaces_2_or_1 = _re.compile('^(\t*/[/*]+) {1,2}')
_re_comment_spaces_1 = _re.compile('^(\t*/[/*]+\t+) ')

_re_trailing_space = _re.compile('\s+$')
_re_comment_trailing_space = _re.compile('/[/*]+\s+$')
_re_double_space = _re.compile('([^\s]) {2}([^\s])')

_re_indent_macro = _re.compile('^(\s*)#')
_re_start_tabs = _re.compile('^(\t+)')

_re_split_indent = _re.compile('^(\s*(?:/[/*]+\s*)?)(.*)$')

_re_spaces_brace_pre = _re.compile('\(\s{2,}')
_re_spaces_brace_post = _re.compile('([^\s])\s{2,}\)')
_re_equal_post = _re.compile('=\s{2,}')

# endregion


def reformat_line(
	file_line=''  # type: str_hint
):
	"""
	The main function performing re-formatting of a single line.
	"""

	# first, let's replace any non-brake space to a regular spaces,
	# since it's not catched by re's "\s":
	if isinstance(file_line, unicode):
		file_line = file_line.replace(u'\xa0', u' ')
	else:
		# assume a regular `str`
		file_line = file_line.replace('\xc2\xa0', ' ')

	def _clean_main_indent(
		line  # type: str_hint
	):
		"""
		replace space indentations to tabs
		"""
		# line = u'\t\t\t return\xa0max(dist > threshold, lightShadowDataX);'.replace('\t', '    ')
		# line = u'\t\t //\t  Shadow helpers  (5.6+ version)    \t  '.replace('\t', '    ')
		while _re_indent_spaces_4.match(line):
			line = _re_indent_spaces_4.sub('\\1\t', line)
		while _re_indent_spaces_3.match(line):
			line = _re_indent_spaces_3.sub('\\1\t', line)
		while _re_indent_spaces_2.match(line):
			line = _re_indent_spaces_2.sub('\\1\t', line)
		while _re_indent_spaces_1.match(line):
			line = _re_indent_spaces_1.sub('\\1', line)
		return line

	def _clean_indent_in_comment(
		line  # type: str_hint
	):
		"""
		same thing with spaces in only-comment lines
		"""
		while _re_comment_spaces_4.match(line):
			line = _re_comment_spaces_4.sub('\\1\t', line)
		while _re_comment_spaces_3.match(line):
			line = _re_comment_spaces_3.sub('\\1\t', line)
		# file_line = u'\t\t// Shadow helpers  (5.6+ version)          '
		while _re_comment_spaces_2.match(line):
			if _re_comment_spaces_2_or_1.match(line):
				line = _re_comment_spaces_2_or_1.sub('\\1 ', line)
			else:
				line = _re_comment_spaces_2.sub('\\1', line)
		while _re_comment_spaces_1.match(line):
			line = _re_comment_spaces_1.sub('\\1', line)
		return line

	def _clean_redundant_spaces(
		line  # type: str_hint
	):
		"""
		remove any trailing whitespace chars, if they're not a comment
		and double-spaces in-line.
		"""
		if not _re_comment_trailing_space.search(line):
			line = _re_trailing_space.sub('', line)
		while _re_double_space.search(line):
			line = _re_double_space.sub(r'\1 \2', line)
		return line

	def _clean_indents_in_macro(
		line  # type: str_hint
	):
		"""
		Move indents after the "#" sign outside the macro.
		"""
		# line = u'#               define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, 0)'
		match_macro = _re_indent_macro.match(line)
		if not match_macro:
			return line

		pre_indent = match_macro.groups()[0]  # type: str_hint
		in_macro = _re_indent_macro.sub(' ', line)

		# since now, there's no dash sign at start
		in_macro = _clean_main_indent(in_macro)
		if not in_macro.startswith('\t'):
			return pre_indent + '#' + in_macro
		macro_tabs = _re_start_tabs.match(in_macro).groups()[0]
		in_macro = in_macro[len(macro_tabs):]
		return pre_indent + macro_tabs + '#' + in_macro

	def _clean_syntax(
		line  # type: str_hint
	):
		indent, main_code = _re_split_indent.match(line).groups()  # type: str_hint, str_hint
		while _re_spaces_brace_pre.search(main_code):
			main_code = _re_spaces_brace_pre.sub(r'( ', main_code)
		while _re_spaces_brace_post.search(main_code):
			main_code = _re_spaces_brace_post.sub(r'\1 )', main_code)
		while _re_equal_post.search(main_code):
			main_code = _re_equal_post.sub('= ', main_code)

		return indent + main_code

	file_line = _clean_main_indent(file_line)
	file_line = _clean_indent_in_comment(file_line)
	file_line = _clean_redundant_spaces(file_line)
	file_line = _clean_indents_in_macro(file_line)
	file_line = _clean_syntax(file_line)

	return file_line


def reformat_file(file_path=''):
	"""
	Re-format a single file, at the given path.
	"""
	try:
		from drl_common import filesystem as _fs
	except ImportError:
		raise ImportError(
			"This script uses a non-shared external module. Read the description first: "
			"you need to manually re-work the script a bit."
		)
	# file_path = r'p:\0-Unity\builtin_shaders\CGIncludes\AutoLight.cginc'

	# DRL: the next function reads a file to a list of lines,
	# automatically assuming it's encoding and using the `line_process_f` function
	# to process each line. Re-implement it yourself:
	lines, encoding, enc_sure = _fs.read_file_lines_best_enc(
		file_path, strip_newline_char=True,
		line_process_f=reformat_line,
		detect_limit=256*1024, detect_mode=_fs.DetectEncodingMode.FALLBACK_CHARDET
	)

	# similarly, this one writes the processed lines, detecting the best encoding:
	_fs.write_file_lines(file_path, lines, encoding)


if __name__ == '__main__':
	import sys, warnings
	errors = list()
	i = 1
	for fl_pth in sys.argv[1:]:
		try:
			with warnings.catch_warnings():
				warnings.simplefilter("ignore")

				reformat_file(fl_pth)
				print('{0}:\t{1}'.format(i, fl_pth))
				i += 1
		except IOError as err:
			errors.append(str(err))

	if errors:
		print('\nErrors during file processing:')
		i = 1
		for i, msg in enumerate(errors):
			print('{0}: {1}'.format(i, msg))

	print('\nComplete')

	try:
		raw_input()
	except:
		input()
