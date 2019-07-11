"""
   resize a set of S1 tiff images to 64x64
"""
import os
import glob
import subprocess


def resize_images():
    src_path = "/home/james/geocrud/Clipped/Valid"
    dst_path = "/home/james/geocrud/Clipped/ValidResized"

    for fn in glob.glob(os.path.join(src_path, "*.tif")):
        base_name = os.path.split(fn)[-1]
        out_name = os.path.join(
            dst_path,
            base_name.replace(".tif", "_resized.tif")
        )

        cmd = "gdal_translate {} {} -outsize 64 64".format(
            fn, out_name
        )

        subprocess.call(cmd, shell=True)


def main():
    resize_images()


if __name__ == "__main__":
    main()