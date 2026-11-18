import json
from pathlib import Path
import re
import shutil
import subprocess


def number(text):
    try:
        return int(text)
    except ValueError:
        return None


def read_int(path):
    try:
        return number(path.read_text().strip())
    except OSError:
        return None


def to_mib(value):
    return None if value is None else value / (1024 ** 2)


def collect():
    cards = {}
    smi = shutil.which('nvidia-smi')
    if smi:
        try:
            output = subprocess.check_output([
                smi, '--query-gpu=pci.bus_id,utilization.gpu,memory.used,memory.total',
                '--format=csv,noheader,nounits'
            ], timeout=2, stderr=subprocess.DEVNULL, text=True)
        except (OSError, subprocess.SubprocessError):
            output = ''
        for line in output.splitlines():
            fields = [field.strip() for field in line.split(',')]
            if len(fields) == 4:
                cards[fields[0].lower()[-12:]] = list(map(number, fields[1:]))

    # Include DRM GPUs even if their driver does not expose these counters.
    for card in Path('/sys/class/drm').glob('card*'):
        if not re.fullmatch(r'card\d+', card.name):
            continue
        device = card / 'device'
        if not device.exists():
            continue
        key = device.resolve().name.lower()
        cards.setdefault(key, [
            read_int(device / 'gpu_busy_percent'),
            to_mib(read_int(device / 'mem_info_vram_used')),
            to_mib(read_int(device / 'mem_info_vram_total')),
        ])
    return [{'id': key, 'metrics': values} for key, values in sorted(cards.items())]


if __name__ == '__main__':
    print(json.dumps(collect()))
