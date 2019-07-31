-- find out which os 10km sq the field falls within
CREATE TABLE zonal.scotland_full_training_w_os10kmsq AS
SELECT
a.gid, a.field_id as fid_1, a.training_f as lcgroup, a.training_1 as lctype, b.TILE_NAME::text,a.geom
FROM
zonal.scotland_full_training a,
geocrud.os_10km_grid b
where st_contains(b.geom, st_centroid(a.geom));
