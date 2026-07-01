"""TAPD 데이터 수집 → GitHub 자동 push (토큰 0 소비 스크립트)"""
import subprocess, sys, os, json
from datetime import datetime, timezone, timedelta

BASE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(BASE, '..'))  # dashboards-repo/tapd → dashboards-repo
SCRIPT = os.path.join(BASE, 'fetch_tapd.py')

KST = timezone(timedelta(hours=9))
NOW = datetime.now(KST).strftime('%Y-%m-%d %H:%M:%S')

# 1. fetch_tapd.py 실행
print(f'[{NOW}] TAPD 데이터 수집 시작...')
r = subprocess.run([sys.executable, SCRIPT], capture_output=True, text=True, cwd=BASE, timeout=300)
if r.returncode != 0:
    print(f'ERROR: {r.stderr[:500]}')
    sys.exit(1)

# 2. 결과 확인
data_file = os.path.join(BASE, 'tapd_data.json')
with open(data_file, 'r', encoding='utf-8') as f:
    d = json.load(f)
total = d.get('meta', {}).get('total', '?')
fetched = d.get('meta', {}).get('fetched_at', '?')

# 3. git add + commit + push
print(f'✅ {total}건 수집 완료 ({fetched})')
os.chdir(REPO)
subprocess.run(['git', 'add', 'tapd/tapd_data.json'], capture_output=True)
r = subprocess.run(['git', 'commit', '-m', f'auto: TAPD 데이터 갱신 ({total}건)'], capture_output=True, text=True)
if 'nothing to commit' not in r.stdout:
    r2 = subprocess.run(['git', 'push'], capture_output=True, text=True)
    if r2.returncode == 0:
        print(f'[{NOW}] GitHub push 완료')
    else:
        print(f'PUSH ERROR: {r2.stderr[:200]}')
else:
    print(f'[{NOW}] 변경사항 없음')

print(f'[{NOW}] TAPD 자동 갱신 완료: {total}건')
