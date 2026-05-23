#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_STATE = Path('local/brew-review.jsonl')
DEFAULT_BREWFILE = Path('homebrew/Brewfile')


@dataclass(frozen=True)
class Package:
    kind: str
    name: str

    @property
    def key(self) -> str:
        return f'{self.kind}:{self.name}'


def brew_env() -> dict[str, str]:
    return {**os.environ, 'HOMEBREW_NO_INSTALL_FROM_API': '1'}


def run_brew(args: list[str]) -> list[str]:
    result = subprocess.run(
        ['brew', *args],
        env=brew_env(),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        raise SystemExit(result.returncode)
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def brewfile_packages(path: Path) -> set[str]:
    if not path.exists():
        return set()

    packages: set[str] = set()
    prefixes = {
        'formula': 'brew "',
        'cask': 'cask "',
    }
    for line in path.read_text(encoding='utf-8').splitlines():
        stripped = line.strip()
        for kind, prefix in prefixes.items():
            if stripped.startswith(prefix):
                name = stripped[len(prefix):].split('"', 1)[0]
                packages.add(Package(kind, name).key)
    return packages


def load_state(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}

    state: dict[str, str] = {}
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        kind = row.get('kind', 'formula')
        state[Package(kind, row['name']).key] = row['decision']
    return state


def append_decision(path: Path, package: Package, decision: str, status: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    row = {
        'kind': package.kind,
        'name': package.name,
        'decision': decision,
        'status': status,
        'decided_at': datetime.now(timezone.utc).isoformat(),
    }
    with path.open('a', encoding='utf-8') as file:
        file.write(json.dumps(row, sort_keys=True) + '\n')


def leaf_formulae() -> list[str]:
    return sorted(run_brew(['leaves']))


def casks() -> list[str]:
    return sorted(run_brew(['list', '--cask']))


def review_packages() -> list[Package]:
    formulae = [Package('formula', name) for name in leaf_formulae()]
    installed_casks = [Package('cask', name) for name in casks()]
    return formulae + installed_casks


def dependents_for_formula(name: str) -> tuple[str, ...]:
    return tuple(sorted(run_brew(['uses', '--installed', name])))


def package_description(package: Package) -> str:
    result = subprocess.run(
        ['brew', 'desc', f'--{package.kind}', package.name],
        env=brew_env(),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0:
        return ''

    output = result.stdout.strip()
    prefix = f'{package.name}: '
    if output.startswith(prefix):
        return output[len(prefix):].strip()
    return output


def prompt(package: Package, in_brewfile: bool, index: int, total: int) -> str:
    print()
    print(f'[{index}/{total}] {package.name} ({package.kind})', flush=True)
    description = package_description(package)
    if description:
        print(f'  Description: {description}', flush=True)
    else:
        print('  Description: unavailable', flush=True)
    print(f'  Brewfile: {"yes" if in_brewfile else "no"}', flush=True)

    while True:
        try:
            answer = input('  [k]eep [r]emove [s]kip [q]uit [?]help > ').strip().lower()
        except EOFError:
            print()
            return 'quit'
        if answer in {'k', 'keep'}:
            return 'keep'
        if answer in {'r', 'remove'}:
            return 'remove'
        if answer in {'s', 'skip', ''}:
            return 'skip'
        if answer in {'q', 'quit'}:
            return 'quit'
        if answer in {'?', 'h', 'help'}:
            print('  keep: mark as intentionally installed')
            print('  remove: uninstall now and record the result')
            print('  skip: leave undecided for a future run')
            print('  quit: stop now and keep saved decisions')


def can_uninstall(package: Package) -> bool:
    if package.kind == 'cask':
        return True

    dependents = dependents_for_formula(package.name)
    if not dependents:
        return True

    print(f'  Cannot uninstall: {package.name} is required by: {", ".join(dependents)}')
    return False


def uninstall_package(package: Package) -> bool:
    result = subprocess.run(
        ['brew', 'uninstall', f'--{package.kind}', package.name],
        env=brew_env(),
        check=False,
    )
    return result.returncode == 0


def print_summary(state_path: Path) -> None:
    state = load_state(state_path)
    removed = sorted(key for key, decision in state.items() if decision == 'remove')
    keep = sorted(key for key, decision in state.items() if decision == 'keep')

    print()
    print(f'Saved decisions: {state_path}')
    print(f'Keep: {len(keep)}')
    print(f'Remove: {len(removed)}')


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Interactively review Homebrew leaf formulae and casks.'
    )
    parser.add_argument('--state', type=Path, default=DEFAULT_STATE)
    parser.add_argument('--brewfile', type=Path, default=DEFAULT_BREWFILE)
    parser.add_argument(
        '--all',
        action='store_true',
        help='Review packages that already have a saved decision too.',
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    state = load_state(args.state)
    in_brewfile = brewfile_packages(args.brewfile)
    packages = review_packages()
    pending = [package for package in packages if args.all or package.key not in state]

    if not pending:
        print('No packages left to review.')
        print_summary(args.state)
        return 0

    total = len(pending)
    for index, package in enumerate(pending, 1):
        decision = prompt(package, package.key in in_brewfile, index, total)
        if decision == 'quit':
            break
        if decision == 'remove':
            if can_uninstall(package):
                status = 'uninstalled' if uninstall_package(package) else 'failed'
            else:
                status = 'blocked'
        else:
            status = 'recorded'
        append_decision(args.state, package, decision, status)

    print_summary(args.state)
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
