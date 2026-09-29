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
    headers["Authorization"] = f"Bearer {token}"
    headers["Accept"] = "application/vnd.github+json"
    headers["User-Agent"] = "Glance-Monterey-Deployer"
    
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
    
    # upload_url_template is like https://uploads.github.com/repos/owner/repo/releases/ID/assets{?name,label}
    base_url = upload_url_template.split("{")[0]
    upload_url = f"{base_url}?name={file_name}"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/octet-stream",
        "Content-Length": str(file_size),
        "User-Agent": "Glance-Monterey-Deployer"
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

    # 1. Fetch releases
    print(f"Fetching releases for {repo}...")
    releases = api_request(f"https://api.github.com/repos/{repo}/releases", token=token)
    
    target_tag = "v1.0.1-monterey"
    target_name = "Glance para macOS Monterey (12.0+) — v1.0.1"
    
    existing_target = None
    for r in releases:
        if r["tag_name"] == target_tag:
            existing_target = r
            break
            
    if not existing_target:
        print(f"Creating release {target_tag}...")
        payload = json.dumps({
            "tag_name": target_tag,
            "target_commitish": "main",
            "name": target_name,
            "body": release_notes,
            "draft": False,
            "prerelease": False
        }).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        existing_target = api_request(
            f"https://api.github.com/repos/{repo}/releases",
            method="POST",
            data=payload,
            headers=headers,
            token=token
        )
        print(f"Release {target_tag} created successfully (ID: {existing_target['id']})!")
    else:
        print(f"Release {target_tag} already exists (ID: {existing_target['id']}). Updating body...")
        payload = json.dumps({
            "name": target_name,
            "body": release_notes
        }).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        api_request(
            f"https://api.github.com/repos/{repo}/releases/{existing_target['id']}",
            method="PATCH",
            data=payload,
            headers=headers,
            token=token
        )
        
    # Delete old assets in target release if any
    current_assets = existing_target.get("assets", [])
    for a in current_assets:
        print(f"Deleting previous asset {a['name']} (ID: {a['id']}) in {target_tag}...")
        api_request(
            f"https://api.github.com/repos/{repo}/releases/assets/{a['id']}",
            method="DELETE",
            token=token
        )
        
    # Upload new assets to target release
    for f in files_to_upload:
        upload_asset(existing_target["upload_url"], f, token)

    # 2. Also update v1.0.0-monterey assets if present, so both are up-to-date
    for r in releases:
        if r["tag_name"] == "v1.0.0-monterey":
            print("\nUpdating assets in v1.0.0-monterey as well...")
            for a in r.get("assets", []):
                print(f"Deleting older asset {a['name']} (ID: {a['id']}) in v1.0.0-monterey...")
                api_request(
                    f"https://api.github.com/repos/{repo}/releases/assets/{a['id']}",
                    method="DELETE",
                    token=token
                )
            for f in files_to_upload:
                upload_asset(r["upload_url"], f, token)
            break

    print("\n🎉 All release assets deployed and updated successfully!")

if __name__ == "__main__":
    main()
