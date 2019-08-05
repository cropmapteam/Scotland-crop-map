CREATE TABLE zonal.scotland_full_lpis_w_os10kmsq AS
SELECT
a.gid, a.field_id as fid_1, NULL::text as lcgroup, NULL::text as lctype, b.TILE_NAME::text,a.geom
FROM
zonal.scotland_full_lpis a,
geocrud.os_10km_grid b
where st_contains(b.geom, st_centroid(a.geom));
