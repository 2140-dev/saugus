#!/usr/bin/env python3

import argparse
import json
import pathlib
import shlex
import subprocess
import sys
from datetime import datetime, timezone


def run(command, dry_run):
    print("+ " + " ".join(shlex.quote(part) for part in command))
    if not dry_run:
        subprocess.run(command, check=True)


def write_json(path, data, dry_run):
    print(f"+ write {path}")
    if dry_run:
        print(json.dumps(data, indent=2, sort_keys=True))
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def replace_line(lines, predicate, replacement):
    for index, line in enumerate(lines):
        if predicate(line):
            lines[index] = replacement
            return
    raise RuntimeError(f"could not find line to replace with: {replacement.strip()}")


def update_flake_inputs(args, dry_run):
    source_url = f'git+https://github.com/{args.source_repo}.git?rev={args.source_rev}'
    ironworks_url = f"github:{args.ironworks_repo}/{args.ironworks_rev}"

    if dry_run:
        print(f"+ set flake input node = {source_url}")
        print(f"+ set flake input ironworks = {ironworks_url}")
        if args.nixpkgs_ref:
            print(f"+ set flake input nixpkgs = {args.nixpkgs_ref}")
        return

    flake = pathlib.Path("flake.nix")
    lines = flake.read_text().splitlines(keepends=True)

    if args.nixpkgs_ref:
        replace_line(
            lines,
            lambda line: line.strip().startswith("nixpkgs.url = "),
            f'    nixpkgs.url = "{args.nixpkgs_ref}";\n',
        )
    replace_line(
        lines,
        lambda line: line.strip().startswith("ironworks.url = "),
        f'    ironworks.url = "{ironworks_url}";\n',
    )

    in_node = False
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "node = {":
            in_node = True
            continue
        if in_node and stripped.startswith("url = "):
            lines[index] = f'      url = "{source_url}";\n'
            break
        if in_node and stripped == "};":
            raise RuntimeError("could not find node.url in flake.nix")
    else:
        raise RuntimeError("could not find node input in flake.nix")

    flake.write_text("".join(lines))


def metadata(args, stage, branch):
    data = {
        "stage": stage,
        "branch": branch,
        "source": {
            "repo": args.source_repo,
            "rev": args.source_rev,
        },
        "ironworks": {
            "repo": args.ironworks_repo,
            "rev": args.ironworks_rev,
        },
        "updatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }

    if args.nixpkgs_ref:
        data["nixpkgs"] = {"ref": args.nixpkgs_ref}

    if stage == "release":
        data["version"] = args.version

    return data


def write_hydra_stage(stage, jobset, dry_run):
    write_json(
        pathlib.Path("locks/hydra-stage.json"),
        {
            "stage": stage,
            "jobset": jobset,
        },
        dry_run,
    )


def update_lock(args, metadata_stage, branch, metadata_path, hydra_stage, hydra_jobset):
    if not args.no_switch:
        run(["git", "switch", "-C", branch], args.dry_run)

    update_flake_inputs(args, args.dry_run)
    run(["nix", "flake", "lock"], args.dry_run)
    write_json(metadata_path, metadata(args, metadata_stage, branch), args.dry_run)
    write_hydra_stage(hydra_stage, hydra_jobset, args.dry_run)
    run(
        [
            "git",
            "add",
            "flake.nix",
            "flake.lock",
            str(metadata_path),
            "locks/hydra-stage.json",
        ],
        args.dry_run,
    )

    if not args.no_commit:
        run(["git", "commit", "-m", f"Pin {metadata_stage} lock inputs"], args.dry_run)

    if args.push:
        run(["git", "push", "-u", "origin", branch], args.dry_run)


def parser():
    parser = argparse.ArgumentParser(
        description="Update Saugus lock branches for staging and release evaluation.",
    )
    parser.add_argument("--source-repo", default="2140-dev/bitcoin")
    parser.add_argument("--ironworks-repo", default="2140-dev/ironworks")
    parser.add_argument("--source-rev", required=True)
    parser.add_argument("--ironworks-rev", required=True)
    parser.add_argument("--nixpkgs-ref")
    parser.add_argument("--no-switch", action="store_true")
    parser.add_argument("--no-commit", action="store_true")
    parser.add_argument("--push", action="store_true")
    parser.add_argument("--dry-run", action="store_true")

    subparsers = parser.add_subparsers(dest="command", required=True)

    staging = subparsers.add_parser("staging")
    staging.add_argument("--branch", default="staging-lock")

    harden = subparsers.add_parser("harden")
    harden.add_argument("--branch", default="harden-lock")

    release = subparsers.add_parser("release")
    release.add_argument("--version", required=True)
    release.add_argument("--branch")

    return parser


def main():
    args = parser().parse_args()

    if args.command == "staging":
        update_lock(
            args,
            "staging",
            args.branch,
            pathlib.Path("locks/staging.json"),
            "forge",
            "staging",
        )
        return 0

    if args.command == "harden":
        update_lock(
            args,
            "harden",
            args.branch,
            pathlib.Path("locks/harden.json"),
            "harden",
            "scheduled",
        )
        return 0

    if args.command == "release":
        branch = args.branch or f"release-lock/{args.version}"
        update_lock(
            args,
            "release",
            branch,
            pathlib.Path("locks/release") / f"{args.version}.json",
            "temper",
            "release",
        )
        return 0

    return 2


if __name__ == "__main__":
    sys.exit(main())
