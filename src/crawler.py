import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

class ANACCrawler:
    def __init__(self, base_url):
        self.base_url = base_url

    def buscar_links_anos(self):
        res = requests.get(self.base_url)
        soup = BeautifulSoup(res.text, 'html.parser')
        anos = []
        for link in soup.find_all('a'):
            href = link.get('href', '').strip('/')
            if href.isdigit() and len(href) == 4:
                anos.append(urljoin(self.base_url, link.get('href')))
        return anos

    def buscar_links_meses(self, url_ano):
        res = requests.get(url_ano)
        soup = BeautifulSoup(res.text, 'html.parser')
        return [urljoin(url_ano, a.get('href')) for a in soup.find_all('a') if " - " in a.get('href', '')]

    def buscar_arquivos_csv(self, url_mes):
        res = requests.get(url_mes)
        soup = BeautifulSoup(res.text, 'html.parser')
        return [urljoin(url_mes, a.get('href')) for a in soup.find_all('a') if a.get('href', '').lower().endswith('.csv')]
