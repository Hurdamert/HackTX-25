# midi_downloader.py
import os
import requests
from bs4 import BeautifulSoup
from tqdm import tqdm

def download_midi(url, save_dir="backend/data/midi"):
    os.makedirs(save_dir, exist_ok=True)
    filename = os.path.basename(url)
    if not filename.endswith(".mid"):
        filename += ".mid"
    save_path = os.path.join(save_dir, filename)

    if os.path.exists(save_path):
        print(f"⏭️ Skipping (already exists): {filename}")
        return

    try:
        with requests.get(url, stream=True, timeout=20) as r:
            r.raise_for_status()
            total = int(r.headers.get("content-length", 0))
            with open(save_path, "wb") as f, tqdm(
                total=total, unit="B", unit_scale=True, desc=filename
            ) as bar:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
                    bar.update(len(chunk))
        print(f"✅ Downloaded: {filename}")
    except Exception as e:
        print(f"❌ Failed to download {url}: {e}")

def scrape_midi_links(base_url, save_dir="backend/data/midi"):
    response = requests.get(base_url)
    soup = BeautifulSoup(response.text, "html.parser")
    links = [a["href"] for a in soup.find_all("a", href=True) if a["href"].endswith(".mid")]
    for link in links:
        if not link.startswith("http"):
            link = base_url.rstrip("/") + "/" + link
        download_midi(link, save_dir)

def scrape_lakh():
    url = "http://hog.ee.columbia.edu/craffel/lmd/lmd_matched.tar.gz"
    save_path = "backend/data/lmd_matched.tar.gz"

    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(save_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)

    print("✅ Download complete: lmd_matched.tar.gz")

# download tar file from lakh
if __name__ == "__main__":
    scrape_midi_links("https://freemidi.org/videogames")
    # scrape_lakh()