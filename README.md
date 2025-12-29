# GDF Plugin - Grumps Dotfiles

Personal workflow commands for development, git workflows, planning, and code review.

## Commands

### Feedback Workflow

- `/gdf:fba` - Feedback add: Start inline feedback workflow
- `/gdf:fbr` - Feedback review: Review and respond to feedback
- `/gdf:fbc` - Feedback clean: Remove all feedback comments

### Git Workflows

- `/gdf:commit` - Commit: Generate conventional commit message
- `/gdf:ppr` - Prepare PR: Prepare feature branch for PR

### Helm

- `/gdf:helm-render` - Helm render: Explore and validate Helm charts

### Just

- `/gdf:just-help` - Just help: Get help with Just command runner

### Planning

- `/gdf:pln` - Plan: Create implementation plan
- `/gdf:rvp` - Review plan: Review implementation plan

### Code Review

- `/gdf:rvc` - Review code: Review staged changes

## Usage

Commands can be invoked with or without the namespace:

- `/gdf:fba` (explicit namespace)
- `/fba` (short form, if no conflicts)

## Installation

This plugin is automatically installed via the dotfiles installer script.

## Version

1.0.0 - Initial release
