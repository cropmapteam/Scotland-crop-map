/*
 * Pg/PostGIS SQL to create the image_bounds_meta view
 *
 */
CREATE OR REPLACE VIEW geocrud.image_bounds_meta AS
 SELECT s.path_to_image,
    s.image_name,
    (split_part(s.image_name, '_'::text, 5) || '_'::text) || split_part(s.image_name, '_'::text, 6) AS image_id,
    round(st_x(st_centroid(s.geom))::numeric, 0) AS img_centroid_x_bng,
    round(st_y(st_centroid(s.geom))::numeric, 0) AS img_centroid_y_bng,
    substr(split_part(s.image_name, '_'::text, 2), 1, 4) AS image_year,
    substr(split_part(s.image_name, '_'::text, 2), 5, 2) AS image_month,
    substr(split_part(s.image_name, '_'::text, 2), 7, 2) AS image_day,
    split_part(s.image_name, '_'::text, 1) AS sensor,
        CASE
            WHEN split_part(s.image_name, '_'::text, 4) = 'asc'::text THEN 'ascending'::text
            WHEN split_part(s.image_name, '_'::text, 4) = 'desc'::text THEN 'descending'::text
            ELSE NULL::text
        END AS orbit,
        CASE
            WHEN split_part(s.image_name, '_'::text, 7) = ANY (ARRAY['VH'::text, 'VV'::text]) THEN ('sub_band_'::text || split_part(s.image_name, '_'::text, 7)) || '_image'::text
            ELSE 'multiband_VH_VV_image'::text
        END AS image_type,
    s.geom AS geom_bng,
    st_transform(s.geom, 4326) AS geom_wgs84
   FROM ( SELECT image_bounds.path_to_image,
            (regexp_split_to_array(image_bounds.path_to_image, '\/'::text))[array_upper(regexp_split_to_array(image_bounds.path_to_image, '\/'::text), 1)] AS image_name,
            image_bounds.img_min_x,
            image_bounds.img_min_y,
            image_bounds.img_max_x,
            image_bounds.img_max_y,
            st_makeenvelope(image_bounds.img_min_x::double precision, image_bounds.img_min_y::double precision, image_bounds.img_max_x::double precision, image_bounds.img_max_y::double precision, 27700) AS geom
           FROM geocrud.image_bounds) s;



