#!/usr/bin/env python3
"""Export a portable resource archive and its shell manifest (no game-specific paths)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import zipfile


def export(romfs, aoc, archive, manifest, title, version):
    roots = [('romfs', Path(romfs))]
    if aoc:
        roots.append(('aoc', Path(aoc)))
    archive, manifest = Path(archive), Path(manifest)
    for _, root in roots:
        if not root.is_dir() or root.is_symlink():
            raise ValueError(f'Not a resource directory: {root}')
        for output in (archive, manifest):
            if output.resolve().is_relative_to(root.resolve()):
                raise ValueError('Outputs must be outside resource directories')
    archive.parent.mkdir(parents=True, exist_ok=True)
    manifest.parent.mkdir(parents=True, exist_ok=True)
    temp = archive.with_suffix(archive.suffix + '.partial')
    entries = []
    try:
        with zipfile.ZipFile(temp, 'w', compression=zipfile.ZIP_STORED, allowZip64=True) as z:
            for prefix, root in roots:
                for path in sorted(root.rglob('*')):
                    if path.is_symlink():
                        raise ValueError(f'Symlinks are not supported: {path}')
                    if path.is_dir():
                        continue
                    if not path.is_file():
                        raise ValueError(f'Not a regular file: {path}')
                    rel = prefix + '/' + path.relative_to(root).as_posix()
                    before = path.stat()
                    digest = hashlib.sha256()
                    size = 0
                    with path.open('rb') as src, z.open(rel, 'w', force_zip64=True) as dst:
                        while chunk := src.read(1024 * 1024):
                            digest.update(chunk)
                            dst.write(chunk)
                            size += len(chunk)
                    after = path.stat()
                    if size != before.st_size or (before.st_size, before.st_mtime_ns, before.st_ctime_ns) != (after.st_size, after.st_mtime_ns, after.st_ctime_ns):
                        raise ValueError(f'Resource changed while exporting: {path}')
                    entries.append(dict(path=rel, size=size, sha256=digest.hexdigest()))
        if not any(e['path'].startswith('romfs/') for e in entries):
            raise ValueError('RomFS is empty')
        data = dict(schema=1, title_id=title, version=version, files=entries)
        mt = manifest.with_suffix('.partial')
        mt.write_text(json.dumps(data, indent=2) + '\n')
        os.replace(temp, archive)
        os.replace(mt, manifest)
        return data
    finally:
        temp.unlink(missing_ok=True)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('romfs', 'archive', 'manifest', 'title', 'version'):
        p.add_argument('--' + name, required=True)
    p.add_argument('--aoc')
    args = vars(p.parse_args())
    try:
        data = export(**args)
        print(f"Exported {len(data['files'])} resource files")
    except (OSError, ValueError) as e:
        p.exit(1, f'[RED] {e}\n')

if __name__ == '__main__':
    main()
