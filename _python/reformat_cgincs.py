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
	_str_h = _t.Union[str, unicode]
except:
	# noinspection PyBroadException
	try:
		_str_h = _t.Union[str, bytes]
	except:
		_str_h = str

# noinspection PyBroadException
try:
	_str_t = (str, unicode)
except:
	_str_t = (bytes, str)

# endregion

from os import path as _pth

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
	file_line=''  # type: _str_h
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
		line  # type: _str_h
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
		line  # type: _str_h
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
		line  # type: _str_h
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
		line  # type: _str_h
	):
		"""
		Move indents after the "#" sign outside the macro.
		"""
		# line = u'#               define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, 0)'
		match_macro = _re_indent_macro.match(line)
		if not match_macro:
			return line

		pre_indent = match_macro.groups()[0]  # type: _str_h
		in_macro = _re_indent_macro.sub(' ', line)

		# since now, there's no dash sign at start
		in_macro = _clean_main_indent(in_macro)
		if not in_macro.startswith('\t'):
			return pre_indent + '#' + in_macro
		macro_tabs = _re_start_tabs.match(in_macro).groups()[0]
		in_macro = in_macro[len(macro_tabs):]
		return pre_indent + macro_tabs + '#' + in_macro

	def _clean_syntax(
		line  # type: _str_h
	):
		indent, main_code = _re_split_indent.match(line).groups()  # type: _str_h, _str_h
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


_required_subdirs = (
	'CGIncludes', 'DefaultResources', 'DefaultResourcesExtra', 'Editor'
)
_extensions = {
	'.shader', '.cginc', '.glslinc', '.compute', '.cs'
}


def list_files_gen(
	root='',  # type: _str_h
	onerror=None,  # type: _t.Optional[_t.Callable[[OSError], _t.Any]]
	dirs_limit=30
):
	"""
	A generator, listing all the files that should be re-formatted in the
	given root dir with Unity's built-in shaders folder structure.

	:param root: The root directory.
	:param onerror: a callback function passed to the os.walk()
	:param dirs_limit: max number of subdirs checked.
	"""
	import os
	import string

	def p_join(*path_segs):
		# type: (_t.Tuple[_str_h, ...]) -> _str_h
		"""
		A shorthand for joining arguments with '/'.
		Just lets to avoid writing lists on each join.
		"""
		return '/'.join(path_segs)

	if not (root and isinstance(root, _str_t)):
		return
	if not _pth.exists(root) and _pth.isdir(root):
		print("The path isn't a folder: " + root)
		return

	# root = r'C:\_builtin_shaders'
	if not (isinstance(dirs_limit, int) and 5 < dirs_limit < 100):
		dirs_limit = 30

	root = root.replace('\\', '/')
	notrail = root.rstrip('/')
	if notrail:
		root = notrail
	main_subdirs = [p_join(root, subdir) for subdir in _required_subdirs]

	root_listed = set(os.listdir(root))
	# separate loop - to make sure at least main subfolders exist
	for subdir, subdir_path in zip(_required_subdirs, main_subdirs):
		if not(
			root_listed  # will return on the 1st iteration
			and subdir in root_listed
			and _pth.isdir(subdir_path)
		):
			print(
				"The path doesn't seem to be a Unity-builtin-shaders root dir, "
				"the subfolder isn't found: " + subdir
			)
			return

	# we're pretty sure it's a shader dir, let's start listing:

	supported_first_chars = set(string.ascii_letters)

	total_subdirs = 0  # prevent listing too much dirs
	for subdir_path in main_subdirs:
		for cur_root, dirs, files in os.walk(
			subdir_path, topdown=True, onerror=onerror, followlinks=False
		):
			# cur_root = 'C:/_builtin_shaders/DefaultResourcesExtra\\AR\\Shaders'
			cur_root = cur_root.replace('\\', '/')
			if dirs:
				# In-place list modification to filter out dir names starting from
				# anything but an ASCII letter ('.git' or similar):
				dirs[:] = (
					d for d in dirs if (d and d[0] in supported_first_chars)
				)
			# Starting subdirs are pre-checked, so no need to also check cur_root.

			if total_subdirs > dirs_limit:
				print (
					"Somehow, more then {} directories are already listed.\n"
					"Probably, {} is not a Unity-builtin-shaders folder after all. "
					"Or maybe we're stuck in a symlink loop.\n"
					"Anyway, file listing is terminated.".format(dirs_limit, repr(root))
				)
				return

			for fl in files:
				# fl = 'TangoARRender.shader'
				if fl and _pth.splitext(fl)[-1].lower() in _extensions:
					yield p_join(cur_root, fl)
			total_subdirs += 1
	return


def _cleanup_args_gen(*args):
	"""
	A generator, checking passed arguments and turning them to
	a list of files to process.

	Each argument should be either a file of dir path:
		* passed files are checked to exist and have the right extension.
		*
			passed dirs are supposed to be a root folder for Unity's built-in
			shaders with a standard folder structure.
	"""
	for arg in args:
		if not(arg and isinstance(arg, _str_t)):
			print ("Wrong argument, skipped: {}".format(repr(arg)))
			continue
		if not _pth.exists(arg):
			print ("File/folder not found: {}".format(arg))

		if _pth.isdir(arg):
			# assume a root shaders folder
			for file_path in list_files_gen(arg):
				yield file_path
			continue

		# should be an existing file
		if _pth.splitext(arg)[-1].lower() not in _extensions:
			print ("Unsupported file type, skipped: {}".format(repr(arg)))
			continue
		yield arg


if __name__ == '__main__':
	import sys, warnings
	errors = list()

	i = 1
	for fl_pth in sorted(
		_cleanup_args_gen(*sys.argv[1:])
	):
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
