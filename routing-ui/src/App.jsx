import { useEffect, useState } from 'react'
import './App.css'
import BottomNav from './BottomNav'
import Sheet from 'react-modal-sheet';
import Map from './Map';
import LocationAutocomplete from './LocationAutocomplete';
import { postData } from './fetchData';

export default function App() {
  const [showSheet, setShowSheet] = useState(false)
  const [startLocation, setStartLocation] = useState()
  const [endLocation, setEndLocation] = useState()
  const [routeType, setRouteType] = useState('safest')
  const [routeGeoJSON, setRouteGeoJSON] = useState()

  const handleClickDirections = () => {
    setShowSheet(true)
  }

  useEffect(() => {
    const urlSuffix = routeType === 'safest' ? 'route' : 'route_nocost'

    if (startLocation && endLocation) {
      // Get a route
      postData(`https://nzemrgdvuxghaitjyojn.supabase.co/rest/v1/rpc/${urlSuffix}`,
      {
        "loc_from": `${startLocation.std_street} ${startLocation.std_street}`, 
        "loc_to": `${endLocation.std_street} ${endLocation.std_street}`
      })
        .then((data) => {
          console.log('setRouteGeoJSON', data)
          setRouteGeoJSON(data)
        })
        .catch(error => {
          setRouteGeoJSON()
          console.error(error)
        })
    }
  }, [startLocation, endLocation, routeType])


  return (
    <>
      <Map routeGeoJSON={routeGeoJSON}/>
      <BottomNav handleClickDirections={handleClickDirections}/>
      <Sheet
          isOpen={showSheet}
          onClose={() => setShowSheet(false)}
          snapPoints={[1, 0.75, 0.5, 0.25, 0]}
          initialSnap={2}
          >
          <Sheet.Container>
            <Sheet.Header/>
            <Sheet.Content>
              <div className="container mx-auto px-5 md:px-10 h-full">
                <h1 className="text-xl mb-6">Cycling directions</h1>
                <form>
                    <div className="columns-1 md:flex">
                      <div className="mb-4 md:w-full md:pr-3" >
                        <LocationAutocomplete placeholder="Start location" setLocation={setStartLocation}/>
                      </div>
                      <div className="mb-4 md:w-full md:pr-3">
                        <LocationAutocomplete placeholder="Destination" setLocation={setEndLocation}/>
                      </div>
                    </div>
                    <div className="columns-1 md:flex">
                      <div className="form-control">
                        <label className="label cursor-pointer">
                          <span className="label-text">Safest route</span> 
                          <input
                           type="radio" name="radio-6" className="radio checked:bg-blue-500" 
                           value="safest"
                           checked={routeType === "safest"}
                           onChange={(event) =>  setRouteType(event.target.value)}
                          />
                        </label>
                      </div>
                      <div className="form-control">
                        <label className="label cursor-pointer">
                          <span className="label-text">Shortest route</span> 
                          <input type="radio" name="radio-6" className="radio checked:bg-red-500"
                            value="shortest"
                            checked={routeType === "shortest"}
                            onChange={(event) =>  setRouteType(event.target.value)}
                          />
                        </label>
                      </div>
                    </div>

                </form>
              </div>
            </Sheet.Content>
          </Sheet.Container>
          {/* <Sheet.Backdrop /> */}
      </Sheet>
    </>
  );
}
