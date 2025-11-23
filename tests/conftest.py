"""Pytest configuration and fixtures."""

import sys
from pathlib import Path

# Add scripts directory to Python path for testing
scripts_dir = Path(__file__).parent.parent / 'scripts'
sys.path.insert(0, str(scripts_dir))
