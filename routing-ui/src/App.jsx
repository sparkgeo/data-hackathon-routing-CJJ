import { useState } from 'react'
import './App.css'
import BottomNav from './BottomNav'
import Sheet from 'react-modal-sheet';
import Map from './Map';
import LocationAutocomplete from './LocationAutocomplete';

export default function App() {
  const [showSheet, setShowSheet] = useState(false)
  const [startLocation, setStartLocation] = useState()
  const [endLocation, setEndLocation] = useState()

  const handleClickDirections = () => {
    setShowSheet(true)
  }

  return (
    <>
      <Map />
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
                <h1 className="text-xl mb-6">Cycle routes</h1>
                <form className="columns-1 md:columns-2">
                  <div className="mb-4 break-after-auto" >
                    <LocationAutocomplete placeholder="Start location" setLocation={setStartLocation}/>
                  </div>
                  <div className="mb-4">
                    <LocationAutocomplete placeholder="Destination" setLocation={setEndLocation}/>
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
