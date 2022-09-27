
-- load data with ogr2ogr

------------------------
-- setup pgr on streets
------------------------
alter table public_streets_staging add column source int;
alter table public_streets_staging add column target int;
alter table public_streets_staging add column length float8;

select pgr_createTopology('public_streets_staging', 0.0000001, 'wkb_geometry', 'ogc_fid') -- create public_streets_staging_vertices_pgr

update public_streets_staging set length = st_length(wkb_geometry::geography);


-- don't eff it up
-- drop table public_streets_topology_staging;
create table public_streets_topology_staging as select row_number () over () as id, * from public_streets_crash_staging;

alter table public_streets_topology_staging add column source int;
alter table public_streets_topology_staging add column target int;
alter table public_streets_topology_staging add column length float8;

-- update public_streets_topology_staging set source = null;
-- update public_streets_topology_staging set target = null;

table public_streets_topology_staging;
select pgr_createTopology('public_streets_topology_staging', 0.0000001, 'geom', 'id')


update public_streets_topology_staging set length = st_length(geom::geography);


create index public_streets_topology_staging_sidx on public_streets_topology_staging using gist(geom);
cluster public_streets_topology_staging using public_streets_topology_staging_sidx;


------------------------
--- weighting properties
------------------------

alter table public_streets_staging add column streetrank int;

begin;
-- drop table streetrank;
create temp table streetrank (use text, rank int);
insert into streetrank values 
('Arterial', 0),
('Secondary Arterial', 2),
('Collector', 4),
('Residential', 5 ),
('Recreational', 8),
('Closed', 10),
('Leased', 10);

begin;
update public_streets_topology_staging s set streetrank = r.rank
from streetrank r where r.use = s.streetuse;

table public_streets_topology_staging;

rollback;
commit;


-------------------------
---- crash data
-------------------------
table crashdata_staging ;

with rollup as (
select count(*), 
	   sum(count::int), 
  	   location,
  	   st_transform(st_buffer(st_transform(st_union(wkb_geometry), 3005), 10), 3857)
  from crashdata_staging cs where type = 'Casualty'
group by location
order by sum desc
) 
select floor(sum/10)*10 as bin_floor, count(*) from rollup group by 1 order by 1;

with rollup as (
select row_number () over (),
	   count(*), 
	   sum(count::int), 
  	   location,
  	   st_transform(st_buffer(st_transform(st_union(wkb_geometry), 3005), 10), 4326) as wkb_geometry
  from crashdata_staging cs where type = 'Casualty'
group by location
order by sum desc
) select st_split(s.wkb_geometry, r.wkb_geometry)  from public_streets_staging s, rollup r ;


with rollup as (
select row_number () over (),
	   count(*), 
	   sum(count::int), 
  	   location,
  	   st_union(wkb_geometry) as wkb_geometry
  from crashdata_staging cs where type = 'Casualty'
group by location
order by sum desc
) 



select c.id, c.wkb_geometry from crash_buffer_staging c;

select st_closestpoint(s.wkb_geometry, c.wkb_geometry) from (select st_collect(wkb_geometry) as wkb_geometry from public_streets_staging) s, crashdata_staging c limit 10;

begin;
select * from crashdata_staging;

select * from crash_buffer_staging cbs ;

alter table crashdata_staging add column snap_wkb_geometry geometry(point, 4326);

update crashdata_staging set snap_wkb_geometry = st_closestpoint(s.wkb_geometry, c.wkb_geometry) 
from (select st_collect(wkb_geometry) as wkb_geometry from public_streets_staging) s, crashdata_staging c;

rollback;
commit;


--------
-- Buffered Crash Points
--------

-- drop table crash_buffer_staging;
with c as
(
select *, st_transform(st_buffer(st_transform(wkb_geometry, 3005), 5), 4326) as buffer_geom from crashdata_staging c
)
select row_number () over () as id, 
	   count(*), 
	   sum(count::int), 
  	   location,
  	   st_union(buffer_geom) as wkb_geometry
  from c where type = 'Casualty'
group by location
order by sum desc;

alter table crash_buffer_staging add primary key (id);
create index crash_buffer_staging_sidx on crash_buffer_staging using gist(wkb_geometry);



select *, 
	   st_transform(st_buffer(st_transform(wkb_geometry, 3005), 5), 4326) as buffer_geom 
from crashdata_staging c


------------------------------
-------- Intersecting Regions
------------------------------


create temp table buffered_crashes as (
select sum(count::int) as casualties, 
	   wkb_geometry,
	   st_transform(st_buffer(st_transform(wkb_geometry, 3005), 8), 4326) as buffer_geom 
from crashdata_staging c  
where type = 'Casualty' 
group by wkb_geometry
order by 1 desc)

create temp table buffered_crashes_sp as 
select st_buffer(st_collect(buffer_geom), 0) as wkb_geometry from buffered_crashes

-- drop table public_streets_crash_staging
create table public_streets_crash_staging as
select s.ogc_fid,
	   s.streetuse,
	   s.streetrank,
	   s.hblock,
	   c.casualties, 
	   st_intersection(s.wkb_geometry, c.buffer_geom) as geom
from public_streets_staging s, buffered_crashes c 
where st_intersects(s.wkb_geometry, c.buffer_geom);

insert into public_streets_crash_staging 
select s.ogc_fid,
	   s.streetuse,
	   s.streetrank,
	   s.hblock,
	   -1 as casualties,
	  st_difference(s.wkb_geometry, g.wkb_geometry) as geom
from buffered_crashes_sp as g, public_streets_staging s where ogc_fid between 16001 and 18000; -- need range requests due to supabase query runlength limitations



------------------------
-- setup addresses to align with intersections
------------------------

alter table addressess_staging add column routing_vert int;
update addressess_staging a set routing_vert = v.id
	from public_streets_staging_vertices_pgr v where st_dwithin(a.wkb_geometry, v.the_geom, 0.001);

-- new routing with crash data
alter table addressess_staging add column crash_routing_vert int;
update addressess_staging a set crash_routing_vert = v.id
	from public_streets_topology_staging_vertices_pgr v where st_dwithin(a.wkb_geometry, v.the_geom, 0.001);
	
------------------------
-- full text search setup
------------------------
	
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
create index addressess_wkb_geometry on addressess using gist(wkb_geometry);
create index addressess_routing_vert on addressess (routing_vert);

select * into public_streets from public_streets_staging;
create index public_steets_wkb_geometry on public_streets using gist(wkb_geometry);
alter table public_streets add primary key (ogc_fid);


select * into public_streets_vertices from public_streets_staging_vertices_pgr;
alter table public_streets_vertices add primary key (id);
create index public_streets_verticies on public_streets_vertices using gist(the_geom);


---
create index addressess_staging_fts on addressess_staging using gin(fts);
create index addressess_staging_wkb_geometry on addressess_staging using gist(wkb_geometry);
create index addressess_staging_routing_vert on addressess_staging (crash_routing_vert);

select * into public_streets from public_streets_staging;
create index public_steets_wkb_geometry on public_streets using gist(wkb_geometry);




--
-- example routing query
SELECT
    d.seq, d.node, d.edge, d.cost, e.wkb_geometry AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT ogc_fid AS id, source, target, length AS cost FROM public_streets',
    -- source node
        (SELECT routing_vert FROM addressess WHERE fts @@ to_tsquery('4677 & Drummond')),
    -- target node                                                                                   
        (SELECT routing_vert FROM addressess WHERE fts @@ to_tsquery('1116 & Bute')),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets AS e ON d.edge = e.ogc_fid
ORDER BY d.seq;





--
-- new routing query
SELECT
    d.seq, d.node, d.edge, d.cost, e.geom AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        $$ SELECT id, source, target, (length/10 + streetrank*2 + (casualties/369::float)*655) AS cost FROM public_streets_topology_staging where source is not null $$,
    -- source node
        (SELECT crash_routing_vert FROM addressess_staging  WHERE fts @@ to_tsquery('4677 & Drummond')),
    -- target node                                                                                   
        (SELECT crash_routing_vert FROM addressess_staging WHERE fts @@ to_tsquery('1116 & Bute')),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets_topology_staging AS e ON d.edge = e.id
ORDER BY d.seq;


select  from public_streets_topology_staging;



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



---- OLD ROUTING FUNCTION
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



--- NEW ROUTING FUNCTION WITH COSTS

create or replace function route(loc_from text, loc_to text)
returns json
as $$
with query as (
SELECT
    d.seq, d.node, d.edge, d.cost, e.geom AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT id, source, target, (length/10 + streetrank*2 + (casualties/369::float)*655) AS cost FROM public_streets_topology_staging where source is not null',
    -- source node
        (SELECT crash_routing_vert FROM addressess_staging  WHERE fts @@ to_tsquery('4677 & Drummond')),
    -- target node                                                                                   
        (SELECT crash_routing_vert FROM addressess_staging WHERE fts @@ to_tsquery('1116 & Bute')),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets_topology_staging AS e ON d.edge = e.id
ORDER BY d.seq
)
select json_build_object (
	'type', 'FeatureCollection',
	'features', json_agg(ST_AsGeoJson(query.*)::json)
) 
from query;
$$
language 'sql';


--- Routing with no costs
create or replace function route_nocost(loc_from text, loc_to text)
returns json
as $$
with query as (
SELECT
    d.seq, d.node, d.edge, d.cost, e.geom AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT id, source, target, length AS cost FROM public_streets_topology_staging where source is not null',
    -- source node
        (SELECT crash_routing_vert FROM addressess_staging  WHERE fts @@ to_tsquery('4677 & Drummond')),
    -- target node                                                                                   
        (SELECT crash_routing_vert FROM addressess_staging WHERE fts @@ to_tsquery('1116 & Bute')),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets_topology_staging AS e ON d.edge = e.id
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
	select civic_number, std_street, st_asgeojson(wkb_geometry)::jsonb from addressess_staging where fts @@ unbounded_tsquery(search)
$$
language 'sql' immutable;


select addressAutocomplete('111 B');

----
with query as (
SELECT
    d.seq, d.node, d.edge, d.cost, e.wkb_geometry AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT ogc_fid AS id, source, target, length AS cost FROM public_streets',
    -- source node
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(:loc_from)),
    -- target node                                                                                   
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(:loc_to)),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets AS e ON d.edge = e.ogc_fid
ORDER BY d.seq
)
select json_build_object (
	'type', 'FeatureCollection',
	'features', json_agg(ST_AsGeoJson(query.*)::json)
) 
from query;


with query as (
SELECT
    d.seq, d.node, d.edge, d.cost, e.wkb_geometry AS edge_geom
FROM                                                                        
    pgr_dijkstra(
    -- edges
        'SELECT ogc_fid AS id, source, target, length AS cost FROM public_streets',
    -- source node
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(:loc_from)),
    -- target node                                                                                   
        (SELECT routing_vert FROM addressess WHERE fts @@ unbounded_tsquery(:loc_to)),
        FALSE
    ) as d                                        
    LEFT JOIN public_streets AS e ON d.edge = e.ogc_fid
ORDER BY d.seq
)
select jsonb_build_object (
	'type', 'FeatureCollection',
	'features', jsonb_agg(ST_AsGeoJson(query.*)::json)
)
from query;


