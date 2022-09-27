# Data Hackathon 2022: Routing for Safety
Repo for Data Guild Hackathon 2022 - Team CJJ: Chloe, Joe and Justin

## Data
- Vancouver Addresses (Geocoder): https://opendata.vancouver.ca/explore/dataset/property-addresses/information/?location=19,49.27995,-123.12699
- Vancouver Public Streets: https://opendata.vancouver.ca/explore/dataset/public-streets/information/
- ICBC Accident Data: https://catalogue.data.gov.bc.ca/dataset/icbc-reported-crashes

## Backend
- Supabase: ref#: nzemrgdvuxghaitjyojn
    - PostGIS (3.1 USE_GEOS=1 USE_PROJ=1 USE_STATS=1), pgRouting (3.3.0)
- data loaded with ogr2ogr: `ogr2ogr -f "PostgreSQL" PG:"host=db.nzemrgdvuxghaitjyojn.supabase.co user=postgres dbname=postgres password=hunter2" "public-streets.geojson" -nln public_streets_staging`

## Frontend
- vite, react
- github pages
- leaflet


## API Requests:
### Get a Route
Returns geojson, current properties (seq = sequence order, node = node id, edge = edge id, cost = combined cost of segment)

```http
POST https://nzemrgdvuxghaitjyojn.supabase.co/rest/v1/rpc/route
Content-Type: application/json
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZW1yZ2R2dXhnaGFpdGp5b2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQyMDM3MzMsImV4cCI6MTk3OTc3OTczM30.hNB_yvwYCn-5b65jnTX6wCsm7B1JjzKIflIEtMvzgEM

{
  "loc_from": "1311 E 18th", 
  "loc_to": "1116 Bute" 
}
```

```js
const loc_from = '1311 E 18th'
const loc_to = '1116 Bute'

let { data, error } = await supabase
  .rpc('route', {
    loc_from, 
    loc_to
  })

if (error) console.error(error)
else console.log(data)
```

### Get a route without costs
```http
POST https://nzemrgdvuxghaitjyojn.supabase.co/rest/v1/rpc/route_nocost
Content-Type: application/json
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZW1yZ2R2dXhnaGFpdGp5b2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQyMDM3MzMsImV4cCI6MTk3OTc3OTczM30.hNB_yvwYCn-5b65jnTX6wCsm7B1JjzKIflIEtMvzgEM

{
  "loc_from": "1311 E 18th", 
  "loc_to": "1116 Bute" 
}
```

### Query Addresses
```http
GET https://nzemrgdvuxghaitjyojn.supabase.co/rest/v1/addressess
  ?select=civic_number,std_street
  &fts=wfts.1116 Bute
Content-Type: application/json
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZW1yZ2R2dXhnaGFpdGp5b2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQyMDM3MzMsImV4cCI6MTk3OTc3OTczM30.hNB_yvwYCn-5b65jnTX6wCsm7B1JjzKIflIEtMvzgEM
```

```js
let { data: addressess, error } = await supabase
   .from('addressess')
   .select('civic_number,std_street')
   .textSearch('fts', '1116 Bute', {
      type: 'websearch'
   })
```

With `fts=wfts.${QUERY TEXT}` where ${QUERY TEXT} is your address lookup. This is not a 'Fuzzy autocompletable query' 

#### Autocomplete / Geocode
Fast, supports partial matches in all components

```http
GET https://nzemrgdvuxghaitjyojn.supabase.co/rest/v1/rpc/addressautocomplete?search=11%20But
Content-Type: application/json
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZW1yZ2R2dXhnaGFpdGp5b2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQyMDM3MzMsImV4cCI6MTk3OTc3OTczM30.hNB_yvwYCn-5b65jnTX6wCsm7B1JjzKIflIEtMvzgEM
```

```js
let {data, error} = await supabase
   .rpc('addressautocomplete', {
      search: '11 But'
   })

if (error) console.error(error)
else console.log(data)
```

## Tasks
1. Collect data
   1. Streets
   2. Addresses
   3. ICBC Accident data
2. Massage Data for PostGIS / pgRouting
   5. Crash location -> point snap? 
2. Frontend
   1. React setup
   2. Leaflet setup
   3. 