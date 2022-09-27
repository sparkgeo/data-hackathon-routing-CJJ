import { useState } from 'react'
import './App.css'
import BottomNav from './BottomNav'
import Sheet from 'react-modal-sheet';
import Map from './Map';

export default function App() {
  const [showSheet, setShowSheet] = useState(false)

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
            <Sheet.Header />
            <Sheet.Content>
              <div class="container mx-auto">
                <h1 class="text-xl leading-7">Cycle routes</h1>
                <input type="text" placeholder="Starting point" className="input w-full max-w-xs" />
                <input type="text" placeholder="Destination" className="input w-full max-w-xs" />
              </div>
            </Sheet.Content>
          </Sheet.Container>
          <Sheet.Backdrop />
      </Sheet>
    </>
  );
}
