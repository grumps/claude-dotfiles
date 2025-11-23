#!/usr/bin/env python3
"""
Feedback Parser - Parse and manage inline code review feedback comments.

This script helps Claude Code efficiently find, parse, and process inline
feedback comments without using excessive tokens. It can:
- Find all feedback blocks in a repository
- Parse metadata (reviewer, date, severity, status)
- Generate structured reports (JSON or text)
- Count feedback by status, severity, file
- Extract feedback for archiving
- Identify feedback blocks for removal

Usage:
    # List all feedback with summary
    feedback-parser.py list

    # Show detailed report
    feedback-parser.py report

    # Export as JSON
    feedback-parser.py export --format json

    # Find unresolved feedback
    feedback-parser.py list --status open

    # Find critical feedback
    feedback-parser.py list --severity critical

    # Archive all feedback
    feedback-parser.py archive --output feedback-archive.md

    # Get cleanup commands (for resolved feedback)
    feedback-parser.py cleanup --dry-run
"""

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class FeedbackBlock:
    """Represents a single feedback block with all metadata."""

    file_path: str
    line_start: int
    line_end: int
    feedback_lines: List[str]
    severity: Optional[str] = None
    reviewer: Optional[str] = None
    date: Optional[str] = None
    status: str = 'open'  # open, responded, resolved
    has_response: bool = False
    has_resolved: bool = False

    @property
    def content(self) -> str:
        """Get the full text content of the feedback block."""
        return '\n'.join(self.feedback_lines)


class FeedbackParser:
    """Parser for inline feedback comments."""

    # Regex patterns for different comment styles
    PATTERNS = {
        'python': re.compile(r'^\s*#\s*(FEEDBACK|RESPONSE|RESOLVED)'),
        'js': re.compile(r'^\s*//\s*(FEEDBACK|RESPONSE|RESOLVED)'),
        'html': re.compile(r'^\s*<!--\s*(FEEDBACK|RESPONSE|RESOLVED).*?-->'),
        'css': re.compile(r'^\s*/\*\s*(FEEDBACK|RESPONSE|RESOLVED).*?\*/'),
    }

    # Severity levels
    SEVERITIES = ['CRITICAL', 'MAJOR', 'MINOR', 'NIT']

    # Default paths to ignore (documentation examples)
    DEFAULT_IGNORE_PATHS = [
        'commands/',
        'examples/',
        '.claude/commands/',
        'docs/examples/',
    ]

    def __init__(self, repo_path: Path = Path('.'), ignore_paths: Optional[List[str]] = None):
        self.repo_path = repo_path
        self.feedback_blocks: List[FeedbackBlock] = []
        self.ignore_paths = ignore_paths if ignore_paths is not None else self.DEFAULT_IGNORE_PATHS

    def should_ignore_file(self, file_path: str) -> bool:
        """Check if file should be ignored based on ignore paths."""
        for ignore_path in self.ignore_paths:
            if file_path.startswith(ignore_path):
                return True
        return False

    def find_files_with_feedback(self) -> List[str]:
        """Use git grep to find all files containing feedback."""
        try:
            result = subprocess.run(
                ['git', 'grep', '-l', 'FEEDBACK'],
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode == 0:
                all_files = [
                    line.strip() for line in result.stdout.strip().split('\n') if line.strip()
                ]
                # Filter out ignored paths
                return [f for f in all_files if not self.should_ignore_file(f)]
            return []
        except subprocess.CalledProcessError:
            return []

    def parse_metadata(self, line: str) -> Dict[str, Optional[str]]:
        """Parse metadata from a feedback line."""
        metadata: Dict[str, Optional[str]] = {
            'severity': None,
            'reviewer': None,
            'date': None,
        }

        # Extract severity
        for severity in self.SEVERITIES:
            if f'[{severity}]' in line:
                metadata['severity'] = severity
                break

        # Extract reviewer (e.g., @username)
        reviewer_match = re.search(r'@([\w-]+)', line)
        if reviewer_match:
            metadata['reviewer'] = reviewer_match.group(1)

        # Extract date (YYYY-MM-DD format)
        date_match = re.search(r'(\d{4}-\d{2}-\d{2})', line)
        if date_match:
            metadata['date'] = date_match.group(1)

        return metadata

    def is_feedback_line(self, line: str) -> Optional[str]:
        """Check if line is a feedback comment. Returns comment type or None."""
        for pattern in self.PATTERNS.values():
            match = pattern.search(line)
            if match:
                return match.group(1)  # FEEDBACK, RESPONSE, or RESOLVED
        return None

    def parse_file(self, file_path: str) -> List[FeedbackBlock]:
        """Parse a single file for feedback blocks."""
        blocks: List[FeedbackBlock] = []
        full_path = self.repo_path / file_path

        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except (IOError, UnicodeDecodeError):
            return blocks

        current_block = None
        current_lines: List[str] = []
        block_start: Optional[int] = None
        has_feedback = False
        has_response = False
        has_resolved = False
        metadata: Dict[str, Optional[str]] = {}

        for line_num, line in enumerate(lines, start=1):
            comment_type = self.is_feedback_line(line)

            if comment_type:
                # Start or continue a feedback block
                if current_block is None:
                    current_block = True
                    block_start = line_num
                    has_feedback = False
                    has_response = False
                    has_resolved = False
                    metadata = {}

                current_lines.append(line.rstrip())

                # Parse metadata from first FEEDBACK line
                if comment_type == 'FEEDBACK' and not has_feedback:
                    metadata = self.parse_metadata(line)
                    has_feedback = True
                elif comment_type == 'RESPONSE':
                    has_response = True
                elif comment_type == 'RESOLVED':
                    has_resolved = True

            else:
                # End of feedback block
                if current_lines and block_start is not None:
                    # Determine status
                    if has_resolved:
                        status = 'resolved'
                    elif has_response:
                        status = 'responded'
                    else:
                        status = 'open'

                    block = FeedbackBlock(
                        file_path=file_path,
                        line_start=block_start,
                        line_end=block_start + len(current_lines) - 1,
                        feedback_lines=current_lines,
                        severity=metadata.get('severity'),
                        reviewer=metadata.get('reviewer'),
                        date=metadata.get('date'),
                        status=status,
                        has_response=has_response,
                        has_resolved=has_resolved,
                    )
                    blocks.append(block)

                    # Reset for next block
                    current_lines = []
                    current_block = None
                    block_start = None

        # Handle block at end of file
        if current_lines and block_start is not None:
            if has_resolved:
                status = 'resolved'
            elif has_response:
                status = 'responded'
            else:
                status = 'open'

            block = FeedbackBlock(
                file_path=file_path,
                line_start=block_start,
                line_end=block_start + len(current_lines) - 1,
                feedback_lines=current_lines,
                severity=metadata.get('severity'),
                reviewer=metadata.get('reviewer'),
                date=metadata.get('date'),
                status=status,
                has_response=has_response,
                has_resolved=has_resolved,
            )
            blocks.append(block)

        return blocks

    def parse_repository(self) -> None:
        """Parse the entire repository for feedback blocks."""
        files = self.find_files_with_feedback()
        self.feedback_blocks = []

        for file_path in files:
            blocks = self.parse_file(file_path)
            self.feedback_blocks.extend(blocks)

    def get_summary(self) -> Dict[str, Any]:
        """Get summary statistics about feedback."""
        summary: Dict[str, Any] = {
            'total': len(self.feedback_blocks),
            'by_status': defaultdict(int),
            'by_severity': defaultdict(int),
            'by_file': defaultdict(int),
            'by_reviewer': defaultdict(int),
        }

        for block in self.feedback_blocks:
            summary['by_status'][block.status] += 1
            if block.severity:
                summary['by_severity'][block.severity] += 1
            summary['by_file'][block.file_path] += 1
            if block.reviewer:
                summary['by_reviewer'][block.reviewer] += 1

        return summary

    def filter_blocks(
        self,
        status: Optional[str] = None,
        severity: Optional[str] = None,
        file_path: Optional[str] = None,
        reviewer: Optional[str] = None,
    ) -> List[FeedbackBlock]:
        """Filter feedback blocks by criteria."""
        filtered = self.feedback_blocks

        if status:
            filtered = [b for b in filtered if b.status == status]
        if severity:
            filtered = [b for b in filtered if b.severity == severity.upper()]
        if file_path:
            filtered = [b for b in filtered if file_path in b.file_path]
        if reviewer:
            filtered = [b for b in filtered if b.reviewer == reviewer]

        return filtered

    def export_json(self) -> str:
        """Export all feedback blocks as JSON."""
        data = {
            'summary': self.get_summary(),
            'blocks': [asdict(block) for block in self.feedback_blocks],
        }
        return json.dumps(data, indent=2)

    def generate_report(self, detailed: bool = False) -> str:
        """Generate a human-readable report."""
        summary = self.get_summary()
        lines = []

        lines.append('# Feedback Summary\n')
        lines.append(f'Total feedback items: {summary["total"]}\n')

        if summary['by_status']:
            lines.append('\n## By Status')
            for status, count in sorted(summary['by_status'].items()):
                emoji = {'open': '⏳', 'responded': '💬', 'resolved': '✅'}.get(status, '❓')
                lines.append(f'  {emoji} {status.capitalize()}: {count}')

        if summary['by_severity']:
            lines.append('\n## By Severity')
            for severity in self.SEVERITIES:
                if severity in summary['by_severity']:
                    count = summary['by_severity'][severity]
                    lines.append(f'  [{severity}]: {count}')

        if summary['by_file']:
            lines.append('\n## By File')
            for file_path, count in sorted(summary['by_file'].items(), key=lambda x: -x[1]):
                lines.append(f'  {file_path}: {count}')

        if detailed:
            lines.append('\n## Detailed Feedback\n')

            # Group by status
            for status in ['open', 'responded', 'resolved']:
                blocks = self.filter_blocks(status=status)
                if blocks:
                    emoji = {'open': '⏳', 'responded': '💬', 'resolved': '✅'}.get(status, '❓')
                    lines.append(f'\n### {emoji} {status.capitalize()} ({len(blocks)} items)\n')

                    for block in blocks:
                        severity_tag = f'[{block.severity}] ' if block.severity else ''
                        reviewer_tag = f'@{block.reviewer} ' if block.reviewer else ''
                        date_tag = f'({block.date}) ' if block.date else ''

                        header = (
                            f'**{block.file_path}:{block.line_start}** '
                            f'{severity_tag}{reviewer_tag}{date_tag}'
                        )
                        lines.append(header)
                        lines.append('```')
                        for line in block.feedback_lines[:5]:  # Limit to first 5 lines
                            lines.append(line)
                        if len(block.feedback_lines) > 5:
                            lines.append(f'... ({len(block.feedback_lines) - 5} more lines)')
                        lines.append('```\n')

        return '\n'.join(lines)

    def generate_archive(self) -> str:
        """Generate an archive document of all feedback."""
        lines = []
        lines.append('# Feedback Archive')
        lines.append(f'\nGenerated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
        lines.append(f'Total items: {len(self.feedback_blocks)}\n')

        # Group by file
        by_file = defaultdict(list)
        for block in self.feedback_blocks:
            by_file[block.file_path].append(block)

        for file_path in sorted(by_file.keys()):
            blocks = by_file[file_path]
            lines.append(f'\n## {file_path}\n')

            for block in blocks:
                severity_tag = f'[{block.severity}] ' if block.severity else ''
                reviewer_tag = f'@{block.reviewer} ' if block.reviewer else ''
                date_tag = f'{block.date} ' if block.date else ''
                status_tag = f'({block.status})' if block.status else ''

                lines.append(f'### Line {block.line_start} {severity_tag}{status_tag}')
                lines.append(f'**Metadata:** {reviewer_tag}{date_tag}\n')
                lines.append('```')
                lines.append(block.content)
                lines.append('```\n')

        return '\n'.join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Parse and manage inline code review feedback',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    # Global arguments
    parser.add_argument(
        '--ignore-paths',
        nargs='*',
        help='Paths to ignore (default: commands/, examples/, .claude/commands/, docs/examples/)',
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to run')

    # List command
    list_parser = subparsers.add_parser('list', help='List feedback items')
    list_parser.add_argument(
        '--status',
        choices=['open', 'responded', 'resolved'],
        help='Filter by status',
    )
    list_parser.add_argument(
        '--severity',
        choices=['critical', 'major', 'minor', 'nit'],
        help='Filter by severity',
    )
    list_parser.add_argument('--file', help='Filter by file path (substring match)')
    list_parser.add_argument('--reviewer', help='Filter by reviewer username')

    # Report command
    report_parser = subparsers.add_parser('report', help='Generate detailed report')
    report_parser.add_argument(
        '--detailed', action='store_true', help='Include full feedback content'
    )

    # Export command
    export_parser = subparsers.add_parser('export', help='Export feedback as JSON')
    export_parser.add_argument('--output', '-o', help='Output file (default: stdout)')

    # Archive command
    archive_parser = subparsers.add_parser('archive', help='Generate archive document')
    archive_parser.add_argument('--output', '-o', required=True, help='Output file path')

    # Summary command (quick stats)
    subparsers.add_parser('summary', help='Show quick summary statistics')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Initialize parser with ignore paths
    ignore_paths = args.ignore_paths if args.ignore_paths is not None else None
    fb_parser = FeedbackParser(ignore_paths=ignore_paths)
    fb_parser.parse_repository()

    # Execute command
    if args.command == 'list':
        blocks = fb_parser.filter_blocks(
            status=args.status,
            severity=args.severity.upper() if args.severity else None,
            file_path=args.file,
            reviewer=args.reviewer,
        )

        if not blocks:
            print('No feedback found matching criteria.')
            sys.exit(0)

        print(f'Found {len(blocks)} feedback item(s):\n')
        for block in blocks:
            severity_tag = f'[{block.severity}] ' if block.severity else ''
            emoji_map = {
                'open': '⏳',
                'responded': '💬',
                'resolved': '✅',
            }
            status_emoji = emoji_map.get(block.status, '❓')
            print(f'{status_emoji} {block.file_path}:{block.line_start} {severity_tag}')

    elif args.command == 'report':
        report = fb_parser.generate_report(detailed=args.detailed)
        print(report)

    elif args.command == 'export':
        json_output = fb_parser.export_json()
        if args.output:
            with open(args.output, 'w') as f:
                f.write(json_output)
            print(f'Exported to {args.output}')
        else:
            print(json_output)

    elif args.command == 'archive':
        archive = fb_parser.generate_archive()
        with open(args.output, 'w') as f:
            f.write(archive)
        print(f'Archive written to {args.output}')

    elif args.command == 'summary':
        summary = fb_parser.get_summary()
        print(f'Total: {summary["total"]}')
        print('\nStatus:')
        for status, count in sorted(summary['by_status'].items()):
            print(f'  {status}: {count}')
        if summary['by_severity']:
            print('\nSeverity:')
            for severity in FeedbackParser.SEVERITIES:
                if severity in summary['by_severity']:
                    print(f'  {severity}: {summary["by_severity"][severity]}')


if __name__ == '__main__':
    main()
