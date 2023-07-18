import requests


def test_lamdba_handler(start_serverless_offline):
    response = requests.get("http://localhost:3000/dev", timeout=10)
    assert response.status_code == 200, str([line.decode("utf-8") for line in start_serverless_offline.stderr.readlines()])

