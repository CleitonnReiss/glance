#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import urllib.error
import subprocess

def get_token():
    cmd = "printf 'protocol=https\\nhost=github.com\\n' | git credential fill | grep password= | cut -d= -f2"
    token = subprocess.check_output(cmd, shell=True).decode().strip()
    if not token:
        raise ValueError("GitHub token could not be retrieved from git credentials.")
    return token

def api_request(url, method="GET", data=None, headers=None, token=None):
    if headers is None:
        headers = {}
    headers["Authorization"] = "Bearer " + token
    headers["Accept"] = "application/vnd.github+json"
    headers["User-Agent"] = "Glance-Deployer"
    
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req) as resp:
        content = resp.read()
        if content:
            return json.loads(content.decode())
        return None

def upload_asset(upload_url_template, file_path, token):
    file_name = os.path.basename(file_path)
    file_size = os.path.getsize(file_path)
    print(f"Uploading {file_name} ({file_size / (1024*1024):.2f} MB)...")
    
    base_url = upload_url_template.split("{")[0]
    upload_url = f"{base_url}?name={file_name}"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/octet-stream",
        "Content-Length": str(file_size),
        "User-Agent": "Glance-Deployer"
    }
    
    with open(file_path, "rb") as f:
        req = urllib.request.Request(upload_url, data=f.read(), headers=headers, method="POST")
        with urllib.request.urlopen(req) as resp:
            res = json.loads(resp.read().decode())
            print(f"  ✓ Uploaded successfully (ID: {res.get('id')})")
            return res

def main():
    repo = "cleitonnreiss/glance"
    token = get_token()
    dist_dir = os.path.abspath("dist")
    files_to_upload = [
        os.path.join(dist_dir, "Glance-macOS-Monterey.dmg"),
        os.path.join(dist_dir, "Glance-macOS-Monterey.pkg"),
        os.path.join(dist_dir, "Glance-macOS-Monterey.zip")
    ]
    
    for f in files_to_upload:
        if not os.path.exists(f):
            print(f"Error: {f} does not exist!")
            sys.exit(1)
            
    with open("RELEASE_NOTES.md", "r", encoding="utf-8") as f:
        release_notes = f.read()

    # 1. Fetch all releases
    print(f"Fetching all releases for {repo}...")
    releases = api_request(f"https://api.github.com/repos/{repo}/releases", token=token)
    
    # 2. Delete all existing releases so we leave only the single latest release
    for r in releases:
        print(f"Deleting older release: {r['name']} (tag: {r['tag_name']}, ID: {r['id']})...")
        try:
            api_request(
                f"https://api.github.com/repos/{repo}/releases/{r['id']}",
                method="DELETE",
                token=token
            )
            print(f"  ✓ Deleted release ID {r['id']}")
        except Exception as e:
            print(f"  ✗ Failed to delete release {r['id']}: {e}")

    # 3. Update git tag v1.0.0 locally and remotely
    print("Updating tag v1.0.0 to current HEAD...")
    subprocess.run(["git", "tag", "-d", "v1.0.0"], capture_output=True)
    subprocess.run(["git", "tag", "v1.0.0"], check=True)
    subprocess.run(["git", "push", "origin", "v1.0.0", "--force"], check=True)

    # 4. Create single clean release v1.0.0
    target_tag = "v1.0.0"
    target_name = "Glance para macOS (Monterey 12.0+) — v1.0.0"
    print(f"Creating clean single release {target_tag}...")
    
    payload = json.dumps({
        "tag_name": target_tag,
        "target_commitish": "main",
        "name": target_name,
        "body": release_notes,
        "draft": False,
        "prerelease": False,
        "make_latest": "true"
    }).encode("utf-8")
    
    headers = {"Content-Type": "application/json"}
    new_release = api_request(
        f"https://api.github.com/repos/{repo}/releases",
        method="POST",
        data=payload,
        headers=headers,
        token=token
    )
    print(f"✓ Release {target_tag} created successfully (ID: {new_release['id']})!")

    # 5. Upload installer assets
    for f in files_to_upload:
        upload_asset(new_release["upload_url"], f, token)

    print("\n🎉 Single clean release v1.0.0 deployed successfully with all installer assets!")

if __name__ == "__main__":
    main()
