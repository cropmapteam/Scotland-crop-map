import csv

unq = []

wget_cmd = "wget -O {} {}"

with open("/home/james/Desktop/image_urls.csv", "r") as inpf:
    with open("/home/james/Desktop/fetch_just_images_we_need.sh", "w") as outpf:
        my_reader = csv.reader(inpf)
        for r in my_reader:
            img_fname = r[0].split("/")[-1]
            if img_fname not in unq:
                unq.append(img_fname)
                wget_cmd = "wget -O {} {}\n".format(img_fname, r[0])
                outpf.write(wget_cmd)
            else:
                print("Duplicate: {} {}".format(img_fname, r[0]))