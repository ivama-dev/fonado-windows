"""Export three fixed public SDK revisions. Never execute fetched content."""
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import tempfile

SOURCES = (
    ("rnnoise", "https://gitlab.linphone.org/BC/public/external/rnnoise.git", "d107462bff3bcda43d8115487959d1e66da905dc"),
    ("xerces-c", "https://gitlab.linphone.org/BC/public/external/xerces-c.git", "cb8467f9e4ed31e3af9474f439af98182bf64728"),
    ("mbedtls", "https://gitlab.linphone.org/BC/public/external/mbedtls.git", "857ff3a350861584a9aaaf8a6ada7a8714c20135"),
)
OUTPUT = Path("artifacts/sdk-source-probe")
ENV = dict(os.environ, GIT_TERMINAL_PROMPT="0", GIT_ASKPASS="/bin/false")
GIT = ["git", "-c", "credential.helper=", "-c", "credential.interactive=false",
       "-c", "http.sslVerify=true", "-c", "http.followRedirects=false",
       "-c", "http.lowSpeedLimit=1024", "-c", "http.lowSpeedTime=30"]
GATE_PATTERN = (
    r"anubis|captcha|challenge|not a bot|forbidden|access denied|authentication|"
    r"terminal prompts disabled|redirect|HTTP[^\n]*(401|403)|error:\s*(401|403)|"
    r"not valid: is this a git repository|unexpected content.type|bad line length|"
    r"invalid (ref )?advertisement|expected.*flush"
)


def git(repo, *arguments, seconds=60):
    process = subprocess.Popen(GIT + ["-C", str(repo), *arguments], env=ENV,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               start_new_session=True)
    try:
        out, err = process.communicate(timeout=seconds)
        return process.returncode, out.decode("utf-8", "replace"), err.decode("utf-8", "replace")
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.communicate()
        return 124, "", ""


def failure(code, error):
    # Do not solve Anubis/CAPTCHA, authenticate, change identity, or try another route.
    if re.search(GATE_PATTERN, error, re.I):
        return "access_gate_stop", True
    if re.search(r"SSL certificate|certificate verify failed|certificate verification failed", error, re.I):
        return "tls_verification_failure_stop", True
    if code == 124 or re.search(r"could not resolve|failed to connect|could not connect|timed out|connection reset|SSL_ERROR_SYSCALL", error, re.I):
        return "connection_unavailable_stop", True
    return "revision_unavailable_or_fetch_failed", False


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report = {
        "sdk_tag": "5.5.39", "sdk_commit": "4d00285c92511acbeba7b2c7c9c621599192584f",
        "method": "anonymous HTTPS git fetch, strict object check, git archive; no checkout of vendor code",
        "complete_corresponding_source_bundle": False,
        "raw_network_logs_included": False,
        "sources": [{"name": name, "url": url, "expected_commit": sha, "status": "not_attempted"}
                    for name, url, sha in SOURCES],
    }

    def save():
        report["all_requested_revisions_archived"] = all(s["status"] == "archived_exact_commit" for s in report["sources"])
        (OUTPUT / "inventory.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    save()
    stop = False
    with tempfile.TemporaryDirectory(prefix="sdk-source-probe-") as workspace:
        for item in report["sources"]:
            if stop:
                item["status"] = "not_attempted_after_host_stop"
                continue
            repo = Path(workspace) / item["name"]
            repo.mkdir()
            code, _, _ = git(repo, "init", "--quiet", seconds=10)
            if code:
                item["status"] = "local_git_init_failed"
                stop = True
                continue
            code, _, error = git(repo, "fetch", "--quiet", "--no-tags", "--depth=1", item["url"], item["expected_commit"])
            if code:
                item["status"], stop = failure(code, error)
                item["git_exit_code"] = code
            else:
                code, commit, _ = git(repo, "rev-parse", "FETCH_HEAD", seconds=10)
                if code or commit.strip() != item["expected_commit"]:
                    item["status"], stop = "commit_mismatch_stop", True
                else:
                    code, _, _ = git(repo, "fsck", "--full", "--strict", "--no-reflogs", "--no-dangling", item["expected_commit"])
                    if code:
                        item["status"], stop = "object_integrity_failure_stop", True
                    else:
                        code, tree, _ = git(repo, "ls-tree", "-r", item["expected_commit"], seconds=15)
                        if code:
                            item["status"], stop = "tree_inspection_failed_stop", True
                            save()
                            continue
                        item["nested_gitlinks"] = [{"commit": line.split()[2], "path": line.split("\t", 1)[1]}
                                                  for line in tree.splitlines() if line.startswith("160000 ")]
                        archive = Path(workspace) / (item["name"] + "-" + item["expected_commit"] + ".zip")
                        code, _, _ = git(repo, "-c", "core.autocrlf=false", "-c", "core.eol=lf", "archive", "--format=zip", "--output=" + str(archive), item["expected_commit"])
                        if code:
                            item["status"] = "archive_failed"
                        else:
                            item.update(status="archived_exact_commit", archive=archive.name,
                                        archive_sha256=hashlib.sha256(archive.read_bytes()).hexdigest())
                            archive.replace(OUTPUT / archive.name)
            print(item["name"] + ": " + item["status"])
            save()
    save()
    return 0 if report["all_requested_revisions_archived"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
