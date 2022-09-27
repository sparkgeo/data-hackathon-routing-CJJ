-- load data with ogr2ogr

-- setup pgr
alter table public_streets_staging add column source int;
alter table public_streets_staging add column target int;
alter table public_streets_staging add column length float8;

select pgr_createTopology('public_streets_staging', 0.0000001, 'wkb_geometry', 'ogc_fid') -- create public_streets_staging_vertices_pgr

update public_streets_staging set length = st_length(wkb_geometry::geography);

-- setup addresses to align with intersections
alter table addressess_staging add column routing_vert int;
update addressess_staging a set routing_vert = v.id
	from public_streets_staging_vertices_pgr v where st_dwithin(a.wkb_geometry, v.the_geom, 0.001)

-- full text search setup
alter table addressess_staging add column fts tsvector generated always as (to_tsvector('english', civic_number || ' ' || std_street);

select * from addressess_staging a where fts @@ to_tsquery('1116 & Bute')

CREATE TABLE public.tsquery_rewrite (
	target tsquery NULL,
	substitution tsquery NULL,
	id serial4 NOT NULL,
	CONSTRAINT tsquery_rewrite_pkey PRIMARY KEY (id)
);

INSERT INTO public.tsquery_rewrite (target,substitution) VALUES
	 ('''rd''','''road'''),
	 ('''avenue''','''av'''),
	 ('''street''','''st'''),
	 ('''drv''','''drive'''),
	 ('''hwy''','''highway'''),
	 ('''crt''','''court'''),
	 ('''N''','''north'''),
	 ('''S''','''south''');

select ts_rewrite(to_tsquery('Drummond & Drv'), $$ select target,substitution from tsquery_rewrite $$)

SELECT civic_number, std_street  FROM addressess WHERE fts @@  '''46'':* & ''drum'':*'::tsquery;
SELECT civic_number, std_street  FROM addressess WHERE fts @@  to_tsquery('46:* & drum:*');
SELECT civic_number, std_street  FROM addressess WHERE fts @@ plainto_tsquery('4677 Drum');
SELECT civic_number, std_street  FROM addressess WHERE fts @@ unbounded_tsquery('46 Drum');



select websearch_to_tsquery ('4677 Drum');

select unbounded_tsquery('46 Drum')::tsquery;

drop function unbounded_tsquery(text); 
create or replace function unbounded_tsquery(input text) 
returns tsquery 
as $$
select ('''' || array_to_string(string_to_array(lower(input), ' '), ''':* & ''') || ''':*')::tsquery;
$$
language sql;

select '''' || array_to_string(string_to_array('One Or Many', ' '), ''':* ''') || ''':*';

SELECT civic_number, std_street  FROM addressess WHERE fts @@ (array_to_string(string_to_array('46 Drum', ' '), ':* ') || ':*')::tsquery;

select lower('TEDS')



-- 
select * into addressess from addressess_staging;

create index addressess_fts on addressess using gin(fts);

select * into public_streets from public_streets_staging;
select * into public_streets_vertices from public_streets_staging_vertices_pgr;

--
-- example routing query
SELECT
    d.seq, d.node, d.edge, d.cost, e.wkb_geometry AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        $$ SELECT ogc_fid AS id, source, target, length AS cost FROM public_streets $$,
    -- source node
        (SELECT routing_vert FROM addressess WHERE fts @@ to_tsquery('4677 & Drummond')),
    -- target node                                                                                   
        (SELECT routing_vert FROM addressess WHERE fts @@ to_tsquery('1116 & Bute')),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets AS e ON d.edge = e.ogc_fid
ORDER BY d.seq;

------------
--- functions
------------

-- unbounded_tsQuery -> returns tsquery with wrapped :* to allow for all fuzzy finding
-- drop function unbounded_tsquery(text); 
create or replace function unbounded_tsquery(input text) 
returns tsquery 
as $$
select ('''' || array_to_string(string_to_array(lower(input), ' '), ''':* & ''') || ''':*')::tsquery;
$$
language sql;

-- route function from -> to
--drop function route;
create or replace function route(loc_from text, loc_to text)
returns table (seq int, node int, edge int, cost float, edge_geom geometry(geometry, 4326))
as $$
SELECT
    d.seq, d.node, d.edge, d.cost, e.wkb_geometry AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT ogc_fid AS id, source, target, length AS cost FROM public_streets',
    -- source node
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(loc_from)),
    -- target node                                                                                   
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(loc_to)),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets AS e ON d.edge = e.ogc_fid
ORDER BY d.seq;
$$
language 'sql';



select * from route('1311 E 18th', '1116 B');




--drop function route;
create or replace function route(loc_from text, loc_to text)
returns json
as $$
with query as (
SELECT
    d.seq, d.node, d.edge, d.cost, e.wkb_geometry AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT ogc_fid AS id, source, target, length AS cost FROM public_streets',
    -- source node
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(loc_from)),
    -- target node                                                                                   
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(loc_to)),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets AS e ON d.edge = e.ogc_fid where edge <> -1
ORDER BY d.seq
)
select json_build_object (
	'type', 'FeatureCollection',
	'features', json_agg(ST_AsGeoJson(query.*)::json)
) 
from query;
$$
language 'sql';


--- autocomplete address
drop function addressautocomplete;
create or replace function addressAutocomplete(search text)
returns table (civic_number text, std_street text, geometry jsonb)
as $$
	select civic_number, std_street, st_asgeojson(wkb_geometry)::jsonb from addressess where fts @@ unbounded_tsquery(search)
$$
language 'sql' immutable;


select addressAutocomplete('111 B');