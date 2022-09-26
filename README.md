# Data Hackathon 2022: Routing for Safety
Repo for Data Guild Hackathon 2022 - Team CJJ: Chloe, Joe and Justin

## Data
- Vancouver Addresses (Geocoder): https://opendata.vancouver.ca/explore/dataset/property-addresses/information/?location=19,49.27995,-123.12699
- Vancouver Public Streets: https://opendata.vancouver.ca/explore/dataset/public-streets/information/
- ICBC Accident Data: https://catalogue.data.gov.bc.ca/dataset/icbc-reported-crashes

## Backend
- Supabase: ref#: nzemrgdvuxghaitjyojn
    - PostGIS (3.1 USE_GEOS=1 USE_PROJ=1 USE_STATS=1), pgRouting (3.3.0)

## Frontend
- vite, react
- netlify
- leaflet


## Tasks
1. Collect data
   1. Streets
   2. Addresses
   3. ICBC Accident data2. Massage Data for PostGIS / pgRouting
   1. Crash location -> point snap? 
3. Frontend
   1. React setup
   2. Leaflet setup
   3. 