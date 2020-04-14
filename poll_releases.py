import requests
import sys

from github import Github

runtime = sys.argv[-1]
if runtime not in ("nodejs", "python"):
    print("::error file=poll_releases.py::Unsupported runtime value")
    sys.exit(1)

gh = Github()
repo = gh.get_repo("newrelic/newrelic-lambda-layers")
releases = repo.get_releases()
tag_names = [release.tag_name for release in releases]

if runtime == "nodejs":
    package = requests.get("https://libraries.io/api/npm/newrelic/").json()
elif runtime == "python":
    package = requests.get("https://libraries.io/api/pypi/newrelic/").json()

latest_version = "v%s" % package["latest_release_number"]
tag_name = "%s_%s" % (latest_version, runtime)

if tag_name in tag_names:
    print("::error file=poll_releases.py::Tag already exists")
    sys.exit(1)

print("::set-env name=latest_version::%s" % latest_version)
print("::set-env name=tag_name::%s" % tag_name)

print("::set-output name=latest_version::%s" % latest_version)
print("::set-output name=tag_name::%s" % tag_name)
