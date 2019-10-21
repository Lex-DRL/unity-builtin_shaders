# encoding: utf-8

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
from drl_common import filesystem as _fs

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
	# first, let's replace any non-brake space to a regular spaces, since it's not catched by re's "\s":
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
	# file_path = r'p:\0-Unity\builtin_shaders\CGIncludes\AutoLight.cginc'

	lines, encoding, enc_sure = _fs.read_file_lines_best_enc(
		file_path, True, line_process_f=reformat_line,
		detect_limit=256*1024, detect_mode=_fs.DetectEncodingMode.FALLBACK_CHARDET
	)

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
