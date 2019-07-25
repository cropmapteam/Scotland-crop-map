import csv
import urllib
import pprint

def fetch_suburls():

    jncc_urls = []
    sub_urls = []

    with open("/home/james/serviceDelivery/CropMaps/theProject/Scotland-crop-map/zonal_experiments/data/Sentinel1_TotalProcessedScenes_20190712.csv", "r") as inpf:
        my_reader = csv.DictReader(inpf)
        for r in my_reader:
            cedaLocationPerDate = r["CEDALocationPerDate"]
            jncc_urls.append(cedaLocationPerDate)

    for jncc_url in jncc_urls:
        url = urllib.request.urlopen(jncc_url)
        #print(jncc_url)
        for l in url.readlines():
            if "SpkRL" in str(l):
                s1_folder = str(l)
                s1_folder = s1_folder[s1_folder.find("<a "):s1_folder.find("</a>")]
                s1_folder = (s1_folder[s1_folder.find("href="):s1_folder.find("/")]).replace('href="','')

                s1_folder_url = jncc_url + s1_folder
                #print("\t {}".format(s1_folder_url))
                sub_urls.append(s1_folder_url)

    return sub_urls

sub_urls = fetch_suburls()

img_urls = []

#base_url = "http://gws-access.ceda.ac.uk/public/defra_eo/sentinel/1/processed/ard/backscatter/2018"
base_url = ""

for sub_url in sub_urls:
    s_url = urllib.request.urlopen(sub_url)
    for i in s_url.readlines():
        if "tif" in str(i):
            link_to_tif = str(i)
            link_to_tif = (link_to_tif[link_to_tif.find("href"): (link_to_tif.find(".tif")+4)]).replace('href="','')
            link_to_tif_url = base_url + sub_url + "/" + link_to_tif
            img_urls.append([link_to_tif_url])

with open("/home/james/Desktop/image_urls.csv", "w") as outpf:
    my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    my_writer.writerows(img_urls)