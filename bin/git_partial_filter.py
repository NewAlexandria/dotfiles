#!/usr/bin/env python3
"""
git-filter-comments.py

Usage:
  # Stage all changes except lines that are comment-only (leading whitespace allowed):
  ./git-filter-comments.py --stage path/to/dir/**

  # Revert only comment-only changes back to HEAD in working tree:
  ./git-filter-comments.py --revert-comments path/to/dir/**

  # Dry-run: show filtered patches without applying:
  ./git-filter-comments.py --stage --dry-run path/to/dir/**

Notes:
- "Comment" definition: optional leading whitespace then '#' as the first non-whitespace character on the line.
- Requires Git and Python 3.6+.
- This script crafts filtered patches and uses `git apply` (with --cached for staging).
- Use --dry-run first to verify.
"""
import argparse
import subprocess
import sys
import tempfile
import os
import fnmatch
import shlex
import re
from pathlib import Path

COMMENT_RE = re.compile(r'^[\+\-]([ \t]*)#')  # matches patch line starting with + or - then optional space then #

def run(cmd, cwd=None, capture=False, check=True, input_bytes=None):
    if capture:
        p = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        if check and p.returncode != 0:
            raise subprocess.CalledProcessError(p.returncode, cmd, output=p.stdout, stderr=p.stderr)
        return p
    else:
        return subprocess.run(cmd, cwd=cwd, check=check)

def git_diff_for_paths(paths):
    """Return git diff patch text for the provided paths (HEAD..WORKTREE)."""
    cmd = ['git', 'diff', '--no-color', '--'] + paths
    p = run(cmd, capture=True)
    return p.stdout.decode('utf-8', errors='replace')

def write_temp(name, text):
    fd, path = tempfile.mkstemp(prefix=name, suffix='.patch')
    with os.fdopen(fd, 'w') as f:
        f.write(text)
    return path

def parse_and_filter_patch(patch_text, keep_comments=False):
    """
    Parse unified patch and return a filtered patch string.

    If keep_comments == True: keep only comment-only +/- lines (and necessary headers/hunks).
    If keep_comments == False: keep only non-comment +/- lines (i.e., omit comment-only lines).

    Recomputes hunk headers so git apply accepts the patch.
    """
    if not patch_text.strip():
        return ''

    out_lines = []
    lines = patch_text.splitlines(keepends=False)
    i = 0
    current_file_block = []
    # We'll consume file-level headers up to hunks, then process hunks.
    while i < len(lines):
        line = lines[i]
        # Start of diff for file: keep file header lines until first hunk or next diff
        if line.startswith('diff --git '):
            # flush previous (should not happen)
            current_file_block = []
            current_file_block.append(line)
            i += 1
            # collect header until hunk or next diff
            while i < len(lines) and not lines[i].startswith('@@ ') and not lines[i].startswith('diff --git '):
                current_file_block.append(lines[i])
                i += 1
            # now we are at hunk or next file; write header to out and then process hunks
            out_lines.extend(current_file_block)
            # process hunks for this file
            while i < len(lines) and lines[i].startswith('@@ '):
                hunk_header = lines[i]
                i += 1
                hunk_lines = []
                while i < len(lines) and not lines[i].startswith('@@ ') and not lines[i].startswith('diff --git '):
                    hunk_lines.append(lines[i])
                    i += 1
                # filter hunk lines
                filtered_lines = []
                # We need to keep context lines (' ') always.
                # For +/- lines, keep or drop based on comment detection.
                for l in hunk_lines:
                    if not l:
                        # empty line in patch is context? In unified patch, an empty line may be represented as a single empty string (but that still begins with a char)
                        # To be safe, treat as context if it doesn't start with + or -.
                        if l and (l[0] == '+' or l[0] == '-'):
                            pass
                        else:
                            filtered_lines.append(l)
                        continue
                    c = l[0]
                    if c == ' ':
                        filtered_lines.append(l)
                    elif c in ('+', '-'):
                        m = COMMENT_RE.match(l)
                        is_comment = bool(m)
                        if keep_comments and is_comment:
                            filtered_lines.append(l)
                        if (not keep_comments) and (not is_comment):
                            filtered_lines.append(l)
                        # else skip the line
                    else:
                        # Unrecognized — keep (defensive)
                        filtered_lines.append(l)
                # If filtered_lines contain any +/- changes then we must keep hunk; else drop it.
                has_plus_minus = any((ln and ln[0] in ('+', '-')) for ln in filtered_lines)
                if has_plus_minus:
                    # Recompute hunk header counts
                    # Original header looks like: @@ -a,b +c,d @@ optional
                    hh = hunk_header
                    # Extract start/counts
                    m = re.match(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$', hh)
                    if not m:
                        # if we can't parse, just include original header and hope for best
                        out_lines.append(hunk_header)
                        out_lines.extend(filtered_lines)
                    else:
                        orig_a = int(m.group(1))
                        orig_b = int(m.group(2) or '1')
                        orig_c = int(m.group(3))
                        orig_d = int(m.group(4) or '1')
                        trailing = m.group(5) or ''
                        # compute counts: minus side lines are context lines (space) + kept '-' lines
                        ctx_count = sum(1 for ln in filtered_lines if ln and ln[0] == ' ')
                        kept_minus = sum(1 for ln in filtered_lines if ln and ln[0] == '-')
                        kept_plus = sum(1 for ln in filtered_lines if ln and ln[0] == '+')
                        new_minus = ctx_count + kept_minus
                        new_plus = ctx_count + kept_plus
                        # hunk start positions remain the same (we keep original starts)
                        # If counts become 0, Git expects count 0 to be represented as 0? In unified diff a count of 0 is allowed.
                        new_hh = f"@@ -{orig_a},{new_minus} +{orig_c},{new_plus} @@{trailing}"
                        out_lines.append(new_hh)
                        out_lines.extend(filtered_lines)
                else:
                    # drop this hunk entirely
                    pass
            # continue outer loop (we're now either at next diff or EOF)
        else:
            # Lines outside 'diff --git' (rare) — copy through
            out_lines.append(line)
            i += 1

    # Join with newlines and trailing newline
    return '\n'.join(out_lines) + ('\n' if out_lines else '')

def find_paths_from_args(patterns):
    # If pure filenames or globs, expand using shell-style globbing (relative to repo root)
    # We'll let git handle files that exist; for globs we walk
    paths = []
    for p in patterns:
        # if contains glob chars, expand
        if any(ch in p for ch in ['*', '?', '[']):
            for root, dirs, files in os.walk('.'):
                for f in files:
                    candidate = os.path.join(root, f)
                    if fnmatch.fnmatch(candidate, p) or fnmatch.fnmatch(candidate.lstrip('./'), p):
                        paths.append(candidate)
        else:
            paths.append(p)
    # Remove duplicates and ensure paths exist (if they don't exist, git diff will ignore)
    uniq = []
    for p in paths:
        if p not in uniq:
            uniq.append(p)
    return uniq

def apply_patch(patch_text, to_cached=False, reverse=False, dry_run=False):
    if not patch_text.strip():
        print("No patch to apply.")
        return 0
    path = write_temp('git-filter-comments', patch_text)
    cmd = ['git', 'apply']
    if to_cached:
        cmd.append('--cached')
    if reverse:
        cmd.append('-R')
    # For safety, we pass the file via --unsafe-paths? Not needed.
    cmd.extend([path])
    print(f"Applying patch file: {path}  (cached={to_cached}, reverse={reverse}, dry_run={dry_run})")
    if dry_run:
        with open(path, 'r') as f:
            print("---- PATCH START ----")
            print(f.read())
            print("---- PATCH END ----")
        return 0
    p = subprocess.run(cmd)
    if p.returncode != 0:
        print(f"git apply returned {p.returncode}. Patch file left at {path} for inspection.")
    return p.returncode

def main():
    ap = argparse.ArgumentParser(description="Stage or revert comment-only lines in git-managed files.")
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--stage', action='store_true', help='Stage changes except comment-only lines (apply to index)')
    group.add_argument('--revert-comments', action='store_true', help='Revert only comment-only changes back to HEAD in working tree')
    ap.add_argument('--dry-run', action='store_true', help='Do not apply, only show the filtered patch(s)')
    ap.add_argument('paths', nargs='+', help='Files or glob patterns (shell-expansion optional). Example: src/**/*.py tests/*.rb')
    args = ap.parse_args()

    paths = find_paths_from_args(args.paths)
    if not paths:
        print("No paths matched. Exiting.")
        sys.exit(0)

    # Get patch for all paths in one diff (HEAD..working tree)
    try:
        patch_full = git_diff_for_paths(paths)
    except subprocess.CalledProcessError as e:
        print("Error while running git diff:", e.stderr.decode() if e.stderr else e)
        sys.exit(2)

    if not patch_full.strip():
        print("No differences found for the specified paths.")
        sys.exit(0)

    if args.stage:
        # keep non-comment changes -> keep_comments=False; apply to index (--cached)
        filtered = parse_and_filter_patch(patch_full, keep_comments=False)
        if not filtered.strip():
            print("After filtering, no non-comment changes remain to stage.")
            sys.exit(0)
        rc = apply_patch(filtered, to_cached=True, reverse=False, dry_run=args.dry_run)
        if rc == 0:
            print("Done. Use 'git diff --cached' to inspect staged changes.")
        else:
            sys.exit(rc)

    elif args.revert_comments:
        # keep only comment changes, then reverse-apply to working tree
        filtered_comments = parse_and_filter_patch(patch_full, keep_comments=True)
        if not filtered_comments.strip():
            print("No comment-only changes detected. Nothing to revert.")
            sys.exit(0)
        rc = apply_patch(filtered_comments, to_cached=False, reverse=True, dry_run=args.dry_run)
        if rc == 0:
            print("Comment-only changes reverted in working tree.")
        else:
            sys.exit(rc)

if __name__ == '__main__':
    main()
