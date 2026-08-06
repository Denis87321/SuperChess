import zipfile
import os
from collections import defaultdict

apk = r"build\app\outputs\flutter-apk\app-release.apk"
z = zipfile.ZipFile(apk)
rows = [(i.file_size, i.filename) for i in z.infolist()]
rows.sort(reverse=True)
print("Top files:")
for sz, name in rows[:25]:
    print(f"{sz/1024/1024:7.2f} MB  {name}")
folders = defaultdict(int)
for sz, name in rows:
    parts = name.split("/")
    key = "/".join(parts[:2]) if len(parts) > 1 else parts[0]
    folders[key] += sz
print("\nBy folder:")
for k, v in sorted(folders.items(), key=lambda x: -x[1])[:15]:
    print(f"{v/1024/1024:7.2f} MB  {k}")
print(f"\nTotal uncompressed: {sum(s for s, _ in rows)/1024/1024:.1f} MB")
print(f"APK file size: {os.path.getsize(apk)/1024/1024:.1f} MB")
