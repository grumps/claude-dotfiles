"""Unit tests for the feedback parser script."""

import json

# Import the feedback parser module
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent / 'scripts'))
from feedback_parser import FeedbackBlock, FeedbackParser  # noqa: E402


class TestFeedbackParser:
    """Test suite for FeedbackParser class."""

    def test_parse_metadata_with_severity(self) -> None:
        """Test parsing metadata with severity tag."""
        parser = FeedbackParser()
        line = '# FEEDBACK [CRITICAL] (@reviewer, 2025-11-23): Security issue'

        metadata = parser.parse_metadata(line)

        assert metadata['severity'] == 'CRITICAL'
        assert metadata['reviewer'] == 'reviewer'
        assert metadata['date'] == '2025-11-23'

    def test_parse_metadata_without_severity(self) -> None:
        """Test parsing metadata without severity tag."""
        parser = FeedbackParser()
        line = '# FEEDBACK (@alice, 2025-11-23): Some feedback'

        metadata = parser.parse_metadata(line)

        assert metadata['severity'] is None
        assert metadata['reviewer'] == 'alice'
        assert metadata['date'] == '2025-11-23'

    def test_parse_metadata_minimal(self) -> None:
        """Test parsing metadata with minimal information."""
        parser = FeedbackParser()
        line = '# FEEDBACK: Simple feedback'

        metadata = parser.parse_metadata(line)

        assert metadata['severity'] is None
        assert metadata['reviewer'] is None
        assert metadata['date'] is None

    def test_is_feedback_line_python_style(self) -> None:
        """Test identifying Python-style feedback comments."""
        parser = FeedbackParser()

        assert parser.is_feedback_line('# FEEDBACK: test') == 'FEEDBACK'
        assert parser.is_feedback_line('# RESPONSE: test') == 'RESPONSE'
        assert parser.is_feedback_line('# RESOLVED: test') == 'RESOLVED'
        assert parser.is_feedback_line('# Regular comment') is None

    def test_is_feedback_line_javascript_style(self) -> None:
        """Test identifying JavaScript-style feedback comments."""
        parser = FeedbackParser()

        assert parser.is_feedback_line('// FEEDBACK: test') == 'FEEDBACK'
        assert parser.is_feedback_line('// RESPONSE: test') == 'RESPONSE'
        assert parser.is_feedback_line('// RESOLVED: test') == 'RESOLVED'
        assert parser.is_feedback_line('// Regular comment') is None

    def test_is_feedback_line_html_style(self) -> None:
        """Test identifying HTML-style feedback comments."""
        parser = FeedbackParser()

        assert parser.is_feedback_line('<!-- FEEDBACK: test -->') == 'FEEDBACK'
        assert parser.is_feedback_line('<!-- RESPONSE: test -->') == 'RESPONSE'
        assert parser.is_feedback_line('<!-- RESOLVED: test -->') == 'RESOLVED'

    def test_parse_file_python_single_feedback(self) -> None:
        """Test parsing a Python file with single feedback block."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text(
                '# FEEDBACK [CRITICAL] (@alice, 2025-11-23): Fix this\n'
                '\n'
                'def function():\n'
                '    pass\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 1
            block = blocks[0]
            assert block.file_path == 'test.py'
            assert block.line_start == 1
            assert block.line_end == 1
            assert block.severity == 'CRITICAL'
            assert block.reviewer == 'alice'
            assert block.date == '2025-11-23'
            assert block.status == 'open'
            assert not block.has_response
            assert not block.has_resolved

    def test_parse_file_with_response(self) -> None:
        """Test parsing feedback with response."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text(
                '# FEEDBACK (@alice, 2025-11-23): Issue here\n'
                '# RESPONSE (@bob, 2025-11-24): Will fix\n'
                '\n'
                'code here\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 1
            block = blocks[0]
            assert block.status == 'responded'
            assert block.has_response
            assert not block.has_resolved

    def test_parse_file_with_resolved(self) -> None:
        """Test parsing feedback that's been resolved."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text(
                '# FEEDBACK (@alice, 2025-11-23): Issue here\n'
                '# RESPONSE (@bob, 2025-11-24): Fixed it\n'
                '# RESOLVED (@bob, 2025-11-24): Done\n'
                '\n'
                'code here\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 1
            block = blocks[0]
            assert block.status == 'resolved'
            assert block.has_response
            assert block.has_resolved

    def test_parse_file_multiple_blocks(self) -> None:
        """Test parsing file with multiple feedback blocks."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text(
                '# FEEDBACK [CRITICAL]: First issue\n'
                '\n'
                'def function1():\n'
                '    pass\n'
                '\n'
                '# FEEDBACK [MINOR]: Second issue\n'
                '\n'
                'def function2():\n'
                '    pass\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 2
            assert blocks[0].severity == 'CRITICAL'
            assert blocks[0].line_start == 1
            assert blocks[1].severity == 'MINOR'
            assert blocks[1].line_start == 6

    def test_parse_file_feedback_at_eof(self) -> None:
        """Test parsing feedback block at end of file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text('def function():\n    pass\n\n# FEEDBACK: Issue at end of file\n')

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 1
            assert blocks[0].line_start == 4
            assert blocks[0].line_end == 4

    def test_parse_file_javascript(self) -> None:
        """Test parsing JavaScript file with // comments."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.js'
            test_file.write_text(
                '// FEEDBACK [MAJOR] (@dev, 2025-11-23): Refactor needed\n'
                '// This is getting too complex\n'
                '\n'
                'function test() {\n'
                '}\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.js')

            assert len(blocks) == 1
            assert blocks[0].severity == 'MAJOR'
            assert blocks[0].reviewer == 'dev'

    def test_parse_file_markdown(self) -> None:
        """Test parsing Markdown file with HTML comments."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.md'
            test_file.write_text(
                '# Title\n\n<!-- FEEDBACK [MINOR]: Add more details -->\n\nContent here.\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.md')

            assert len(blocks) == 1
            assert blocks[0].severity == 'MINOR'
            assert blocks[0].line_start == 3

    def test_parse_file_empty(self) -> None:
        """Test parsing empty file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'empty.py'
            test_file.write_text('')

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('empty.py')

            assert len(blocks) == 0

    def test_parse_file_no_feedback(self) -> None:
        """Test parsing file without any feedback."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text(
                '# Regular comment\ndef function():\n    # Another comment\n    pass\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 0

    def test_parse_file_nonexistent(self) -> None:
        """Test parsing nonexistent file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('nonexistent.py')

            assert len(blocks) == 0

    def test_filter_blocks_by_status(self) -> None:
        """Test filtering blocks by status."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test1.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test1'],
                status='open',
            ),
            FeedbackBlock(
                file_path='test2.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test2'],
                status='resolved',
            ),
            FeedbackBlock(
                file_path='test3.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test3'],
                status='responded',
            ),
        ]

        open_blocks = parser.filter_blocks(status='open')
        assert len(open_blocks) == 1
        assert open_blocks[0].file_path == 'test1.py'

        resolved_blocks = parser.filter_blocks(status='resolved')
        assert len(resolved_blocks) == 1
        assert resolved_blocks[0].file_path == 'test2.py'

    def test_filter_blocks_by_severity(self) -> None:
        """Test filtering blocks by severity."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test1.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test1'],
                severity='CRITICAL',
            ),
            FeedbackBlock(
                file_path='test2.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test2'],
                severity='MINOR',
            ),
        ]

        critical_blocks = parser.filter_blocks(severity='CRITICAL')
        assert len(critical_blocks) == 1
        assert critical_blocks[0].severity == 'CRITICAL'

    def test_filter_blocks_by_file_path(self) -> None:
        """Test filtering blocks by file path."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='src/auth.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test1'],
            ),
            FeedbackBlock(
                file_path='src/api.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test2'],
            ),
            FeedbackBlock(
                file_path='tests/test_auth.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test3'],
            ),
        ]

        auth_blocks = parser.filter_blocks(file_path='auth')
        assert len(auth_blocks) == 2

        src_blocks = parser.filter_blocks(file_path='src/')
        assert len(src_blocks) == 2

    def test_filter_blocks_by_reviewer(self) -> None:
        """Test filtering blocks by reviewer."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test1.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test1'],
                reviewer='alice',
            ),
            FeedbackBlock(
                file_path='test2.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test2'],
                reviewer='bob',
            ),
        ]

        alice_blocks = parser.filter_blocks(reviewer='alice')
        assert len(alice_blocks) == 1
        assert alice_blocks[0].reviewer == 'alice'

    def test_get_summary(self) -> None:
        """Test generating summary statistics."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test1'],
                status='open',
                severity='CRITICAL',
                reviewer='alice',
            ),
            FeedbackBlock(
                file_path='test.py',
                line_start=5,
                line_end=5,
                feedback_lines=['# FEEDBACK: test2'],
                status='resolved',
                severity='MINOR',
                reviewer='bob',
            ),
        ]

        summary = parser.get_summary()

        assert summary['total'] == 2
        assert summary['by_status']['open'] == 1
        assert summary['by_status']['resolved'] == 1
        assert summary['by_severity']['CRITICAL'] == 1
        assert summary['by_severity']['MINOR'] == 1
        assert summary['by_file']['test.py'] == 2
        assert summary['by_reviewer']['alice'] == 1
        assert summary['by_reviewer']['bob'] == 1

    def test_export_json(self) -> None:
        """Test exporting feedback as JSON."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test.py',
                line_start=1,
                line_end=2,
                feedback_lines=['# FEEDBACK: test'],
                severity='CRITICAL',
            )
        ]

        json_output = parser.export_json()
        data = json.loads(json_output)

        assert 'summary' in data
        assert 'blocks' in data
        assert len(data['blocks']) == 1
        assert data['blocks'][0]['severity'] == 'CRITICAL'

    def test_generate_report(self) -> None:
        """Test generating text report."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test'],
                status='open',
                severity='CRITICAL',
            )
        ]

        report = parser.generate_report()

        assert '# Feedback Summary' in report
        assert 'Total feedback items: 1' in report
        assert '[CRITICAL]: 1' in report
        assert 'Open: 1' in report

    def test_generate_report_detailed(self) -> None:
        """Test generating detailed report."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test'],
                status='open',
            )
        ]

        report = parser.generate_report(detailed=True)

        assert '## Detailed Feedback' in report
        assert '**test.py:1**' in report

    def test_generate_archive(self) -> None:
        """Test generating archive document."""
        parser = FeedbackParser()
        parser.feedback_blocks = [
            FeedbackBlock(
                file_path='test.py',
                line_start=1,
                line_end=1,
                feedback_lines=['# FEEDBACK: test'],
                severity='CRITICAL',
                reviewer='alice',
                date='2025-11-23',
                status='resolved',
            )
        ]

        archive = parser.generate_archive()

        assert '# Feedback Archive' in archive
        assert '## test.py' in archive
        assert '[CRITICAL]' in archive
        assert '@alice' in archive
        assert '2025-11-23' in archive
        assert '(resolved)' in archive

    def test_feedback_block_content_property(self) -> None:
        """Test FeedbackBlock content property."""
        block = FeedbackBlock(
            file_path='test.py',
            line_start=1,
            line_end=3,
            feedback_lines=['# FEEDBACK: line 1', '# line 2', '# line 3'],
        )

        assert block.content == '# FEEDBACK: line 1\n# line 2\n# line 3'

    def test_all_severity_levels(self) -> None:
        """Test all severity levels are recognized."""
        parser = FeedbackParser()

        for severity in ['CRITICAL', 'MAJOR', 'MINOR', 'NIT']:
            line = f'# FEEDBACK [{severity}]: test'
            metadata = parser.parse_metadata(line)
            assert metadata['severity'] == severity

    def test_indented_feedback(self) -> None:
        """Test parsing indented feedback (e.g., in nested code)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / 'test.py'
            test_file.write_text(
                'def outer():\n'
                '    def inner():\n'
                '        # FEEDBACK: Nested too deep\n'
                '        pass\n'
            )

            parser = FeedbackParser(repo_path=Path(tmpdir))
            blocks = parser.parse_file('test.py')

            assert len(blocks) == 1
            assert blocks[0].line_start == 3


class TestFeedbackBlockDataclass:
    """Test suite for FeedbackBlock dataclass."""

    def test_default_values(self) -> None:
        """Test FeedbackBlock default values."""
        block = FeedbackBlock(
            file_path='test.py', line_start=1, line_end=1, feedback_lines=['# FEEDBACK: test']
        )

        assert block.severity is None
        assert block.reviewer is None
        assert block.date is None
        assert block.status == 'open'
        assert block.has_response is False
        assert block.has_resolved is False

    def test_all_fields(self) -> None:
        """Test FeedbackBlock with all fields set."""
        block = FeedbackBlock(
            file_path='test.py',
            line_start=1,
            line_end=3,
            feedback_lines=['line1', 'line2', 'line3'],
            severity='CRITICAL',
            reviewer='alice',
            date='2025-11-23',
            status='resolved',
            has_response=True,
            has_resolved=True,
        )

        assert block.file_path == 'test.py'
        assert block.line_start == 1
        assert block.line_end == 3
        assert len(block.feedback_lines) == 3
        assert block.severity == 'CRITICAL'
        assert block.reviewer == 'alice'
        assert block.date == '2025-11-23'
        assert block.status == 'resolved'
        assert block.has_response is True
        assert block.has_resolved is True
