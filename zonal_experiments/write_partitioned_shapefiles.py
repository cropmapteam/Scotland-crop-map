"""
    script to dump from PostGIS db as a new shapefile all of the polygons
    within each processing block
"""
from postgres import Postgres
import subprocess


def get_partition_tile_names(pg_conn_str):
    partition_tile_names = []
    db = Postgres(pg_conn_str)
    sql = "SELECT distinct(tile_name) FROM zonal.scotland_full_lpis_w_os10kmsq"
    rs = db.all(sql)
    for r in rs:
        partition_tile_names.append(r)

    return partition_tile_names


pg_conn_str=""
tile_names = get_partition_tile_names(pg_conn_str)

for tn in tile_names:
    db_host = ""
    db_user = ""
    db_pwd = ""
    # we need -r to ensure postgis gid`s are included in the output
    cmd = "pgsql2shp -r -f /home/james/geocrud/partitions/scotland_full_lpis_{0}.shp -h {2} -u {3} -P {4} cropmaps @SELECT * FROM zonal.scotland_full_lpis_w_os10kmsq WHERE tile_name='{1}'@".format(
        tn.lower(), tn, db_host, db_user, db_pwd)
    cmd = cmd.replace('@', '"')
    subprocess.call(cmd, shell=True)
