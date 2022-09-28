import { MapContainer, TileLayer, GeoJSON } from 'react-leaflet'

const Map = ({routeGeoJSON}) => {
  return(  <MapContainer center={[49.2827, -123.1207]} zoom={11} scrollWheelZoom={true}>
    <TileLayer
      attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
    />
    {!!routeGeoJSON && <GeoJSON data={routeGeoJSON}/>}
    </MapContainer>)
}

export default Map