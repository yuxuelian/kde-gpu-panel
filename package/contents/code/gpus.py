import json
from pathlib import Path
import re
import shutil
import subprocess
import time


def intel_clients(devices):
    clients = {key: {} for key in devices}
    for path in Path('/proc').glob('[0-9]*/fdinfo/*'):
        try:
            fields = dict(line.split(':', 1) for line in path.read_text().splitlines()
                          if line.startswith('drm-') and ':' in line)
        except (OSError, UnicodeError):
            continue
        key = fields.get('drm-pdev', '').strip()
        client = fields.get('drm-client-id', '').strip()
        if key not in clients or not client or client in clients[key]:
            continue
        def value(name):
            parts = fields.get(name, '').split()
            if not parts:
                return None
            n = number(parts[0])
            return None if n is None else n * {'KiB': 1024, 'MiB': 1024**2}.get(parts[-1], 1)
        resident = [value(name) for name in fields
                    if re.fullmatch(r'drm-resident-(?:stolen-)?system\d*', name)]
        resident = [n for n in resident if n is not None]
        clients[key][client] = (value('drm-engine-render'), sum(resident) if resident else None)
    return clients


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


def gpu_temperature(device):
    # Only use sensors attached to this GPU, not CPU/package sensors.
    for hwmon in sorted((device / 'hwmon').glob('hwmon*')):
        sensor = hwmon / 'temp1_input'
        for label in sorted(hwmon.glob('temp*_label')):
            try:
                kind = label.read_text().strip().lower()
            except OSError:
                continue
            if kind in {'edge', 'gpu'}:
                sensor = label.with_name(label.name.replace('_label', '_input'))
                break
        value = read_int(sensor)
        if value is not None:
            return round(value / 1000)
    return None


def collect():
    cards = {}
    temperatures = {}
    intel = set()
    smi = shutil.which('nvidia-smi')
    if smi:
        try:
            output = subprocess.check_output([
                smi, '--query-gpu=pci.bus_id,utilization.gpu,memory.used,memory.total,temperature.gpu',
                '--format=csv,noheader,nounits'
            ], timeout=2, stderr=subprocess.DEVNULL, text=True)
        except (OSError, subprocess.SubprocessError):
            output = ''
        for line in output.splitlines():
            fields = [field.strip() for field in line.split(',')]
            if len(fields) == 5:
                key = fields[0].lower()[-12:]
                cards[key] = list(map(number, fields[1:4]))
                temperatures[key] = number(fields[4])

    # Include DRM GPUs even if their driver does not expose these counters.
    for card in Path('/sys/class/drm').glob('card*'):
        if not re.fullmatch(r'card\d+', card.name):
            continue
        device = card / 'device'
        if not device.exists():
            continue
        key = device.resolve().name.lower()
        if temperatures.get(key) is None:
            temperatures[key] = gpu_temperature(device)
        if (device / 'driver').resolve().name == 'i915':
            intel.add(key)
        cards.setdefault(key, [
            read_int(device / 'gpu_busy_percent'),
            to_mib(read_int(device / 'mem_info_vram_used')),
            to_mib(read_int(device / 'mem_info_vram_total')),
        ])
    sample_time = time.monotonic_ns()
    clients = intel_clients(intel) if intel else {}
    rows = []
    for key, metrics in sorted(cards.items()):
        row = {'id': key, 'metrics': metrics, 'temperature': temperatures.get(key)}
        if key in intel:
            entries = clients[key]
            resident = [mem for _, mem in entries.values() if mem is not None]
            row.update(shared=True, timestamp=sample_time,
                       engines={client: ns for client, (ns, _) in entries.items() if ns is not None},
                       metrics=[None, to_mib(sum(resident)) if resident else None, None])
        rows.append(row)
    return rows


if __name__ == '__main__':
    print(json.dumps(collect()))
