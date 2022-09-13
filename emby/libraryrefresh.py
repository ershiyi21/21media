import requests

headers = {
    'accept': '*/*',
    'content-type': 'application/x-www-form-urlencoded',
}

params = {
    'api_key': '',
}

response = requests.post('url/emby/Library/Refresh', params=params, headers=headers)
