import os
import sys
import subprocess

import json
import typing
import urllib.error
import urllib.parse
import urllib.request
from email.message import Message

from packaging import version

release_url = "https://api.github.com/repos/mario33881/test_appimage/releases/latest"
__version__ = "1.3.0"


class Response(typing.NamedTuple):
    body: str
    headers: Message
    status: int
    error_count: int = 0

    def json(self) -> typing.Any:
        """
        Decode body's JSON.
        Returns:
            Pythonic representation of the JSON object
        """
        try:
            output = json.loads(self.body)
        except json.JSONDecodeError:
            output = ""
        return output


def request(
    url: str,
    data: dict = None,
    params: dict = None,
    headers: dict = None,
    method: str = "GET",
    data_as_json: bool = True,
    error_count: int = 0,
) -> Response:
    """
    Make a request without non-standard libraries
    """
    if not url.casefold().startswith("http"):
        raise urllib.error.URLError("Incorrect and possibly insecure protocol in url")
    method = method.upper()
    request_data = None
    headers = headers or {}
    data = data or {}
    params = params or {}
    headers = {"Accept": "application/json", **headers}

    if method == "GET":
        params = {**params, **data}
        data = None

    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True, safe="/")

    if data:
        if data_as_json:
            request_data = json.dumps(data).encode()
            headers["Content-Type"] = "application/json; charset=UTF-8"
        else:
            request_data = urllib.parse.urlencode(data).encode()

    httprequest = urllib.request.Request(
        url, data=request_data, headers=headers, method=method
    )

    try:
        with urllib.request.urlopen(httprequest) as httpresponse:
            response = Response(
                headers=httpresponse.headers,
                status=httpresponse.status,
                body=httpresponse.read().decode(
                    httpresponse.headers.get_content_charset("utf-8")
                ),
            )
    except urllib.error.HTTPError as e:
        response = Response(
            body=str(e.reason),
            headers=e.headers,
            status=e.code,
            error_count=error_count + 1,
        )

    return response


def main():
    args = sys.argv
    if len(args) == 2:
        if sys.argv[1] == "--update":
            print("looking for updates")
            if "PATH" in os.environ:
                print("path environment variable: ", os.environ["PATH"])
            try:
                if "APPIMAGE" in os.environ and "APPDIR" in os.environ:
                    aiut_path = os.path.join(os.environ["APPDIR"], "usr", "bin")
                    aiut_executable = os.path.join(aiut_path, "appimageupdate")
                    print("{} contains these files:".format(os.environ["APPDIR"]))
                    for file in os.listdir(os.environ["APPDIR"]):
                        print(file)
                    print("{} contains these files:".format(aiut_path))
                    for file in os.listdir(aiut_path):
                        print(file)

                    print("Executing '{}' on '{}'".format(aiut_executable, os.environ["APPIMAGE"]))
                    subprocess.Popen([aiut_executable, os.environ["APPIMAGE"]])
                else:
                    print("Can't check for updates: it looks like you didn't build the appimage yet")
            except Exception as e:
                print("Something went wrong:", e)
        else:
            print("Invalid flag: call with --update or no flags")
            print("> You used these flags: ", args)
    else:
        print("Currently using version ", __version__)
        req = request(release_url)
        json_data = req.json()
        latest_version = None

        if not isinstance(json_data, str):
            for asset in json_data["assets"]:
                if asset["name"] == "version.txt":
                    target_url = asset["browser_download_url"]
                    for line in urllib.request.urlopen(target_url):
                        latest_version = line.decode('utf-8').strip()
                        break
                    break

            if latest_version is not None:
                print("latest version:", latest_version)
                if version.parse(latest_version) > version.parse(__version__):
                    print("new update is available")
                else:
                    print("NO updates available")
        else:
            print("No releases")


if __name__ == "__main__":
    main()