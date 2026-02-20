import csv
from pathlib import Path
BASE = Path(r"c:/Users/USerZ/Downloads/NutritionalHealth/NutritionalHealth/frontend/mobile/assets/csv/menuallcsv")

def load_energy_from_expanded():
    p = BASE / 'starbucks_drinkMenu_expanded.csv'
    if not p.exists(): return []
    out = []
    with p.open(encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        rows = list(reader)
        if not rows: return []
        header = [h.strip().lower() for h in rows[0]]
        # prefer exact beverage
        try:
            name_idx = header.index('beverage')
        except ValueError:
            name_idx = next((i for i,h in enumerate(header) if 'beverage' in h and 'category' not in h), 0)
        # calories
        cal_idx = next((i for i,h in enumerate(header) if 'calor' in h), -1)
        for r in rows[1:]:
            if len(r) <= name_idx: continue
            name = r[name_idx].strip()
            lower = name.lower()
            if 'smoothie' in lower: continue
            cal = 0
            try:
                cal = float(r[cal_idx]) if cal_idx>=0 and cal_idx < len(r) and r[cal_idx].strip()!='' else 0
            except:
                cal = 0
            # energy criteria
            if cal>=200 or lower.find('energy')!=-1 or lower.find('doubleshot')!=-1:
                out.append(name)
    return list(dict.fromkeys(out))


def load_weightloss_from_expanded():
    p = BASE / 'starbucks_drinkMenu_expanded.csv'
    if not p.exists(): return []
    out = []
    with p.open(encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        rows = list(reader)
        if not rows: return []
        header = [h.strip().lower() for h in rows[0]]
        try:
            name_idx = header.index('beverage')
        except ValueError:
            name_idx = next((i for i,h in enumerate(header) if 'beverage' in h and 'category' not in h), 0)
        cal_idx = next((i for i,h in enumerate(header) if 'calor' in h), -1)
        for r in rows[1:]:
            if len(r) <= name_idx: continue
            name = r[name_idx].strip()
            lower = name.lower()
            if 'smoothie' in lower: continue
            cal = None
            try:
                cal = float(r[cal_idx]) if cal_idx>=0 and cal_idx < len(r) and r[cal_idx].strip()!='' else None
            except:
                cal = None
            if cal is not None and cal<=80:
                out.append(name)
    return list(dict.fromkeys(out))

if __name__=='__main__':
    print('Energy candidates:', load_energy_from_expanded()[:20])
    print('Weight-loss candidates:', load_weightloss_from_expanded()[:20])
