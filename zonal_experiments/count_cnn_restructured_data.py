import os

counts = {"Train":{}, "Test":{}}

for root, folders, files in os.walk("/home/james/Desktop/KelsoGreyscaleRestructured"):
    for f in files:
        if os.path.splitext(f)[-1] == ".tif":
            test_or_train = (os.path.join(root, f)).split("/")[5]
            label = (os.path.join(root, f)).split("/")[6]

            print(os.path.join(root, f), test_or_train, label)

            if label not in counts[test_or_train]:
                counts[test_or_train][label] = 1
            else:
                counts[test_or_train][label] += 1


import pprint
pprint.pprint(counts)