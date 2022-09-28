import { useState } from 'react'
import Downshift from 'downshift'
import { getData } from '../fetchData'

const LocationAutocomplete = ({placeholder, setLocation}) => {
  const [inputItems, setInputItems] = useState([])

  return (
    <Downshift
    onChange={(selection) => setLocation(selection)}
    itemToString={(item) => {
      return (item ? `${item.civic_number} ${item.std_street}` : '')
    }}
    onInputValueChange={async (value) => {
      getData(`https://nzemrgdvuxghaitjyojn.supabase.co/rest/v1/rpc/addressautocomplete?search=${value}&limit=5`)
        .then(data => {
          setInputItems(data)
        })
        .catch(error => {
            setInputItems([])
            console.error(error)
        })
     
    }}
  >
    {({
      getInputProps,
      getItemProps,
      // getLabelProps,
      getMenuProps,
      // getToggleButtonProps,
      isOpen,
      inputValue,
      highlightedIndex,
      selectedItem,
      getRootProps,
    }) => {
      return (
      <div>
        {/* <label {...getLabelProps()}>Enter a fruit:</label> */}
        <div
          // style={comboboxStyles}
          {...getRootProps({}, {suppressRefError: true})}
        >
          <input {...getInputProps()}
            type="text"
            placeholder={placeholder}
            className="input bg-gray-50 border-gray-300 text-sm block w-full p-2.5"
          />
        </div>
        <ul {...getMenuProps()} 
          // style={menuStyles}
          className={`menu menu-normal lg:menu-normal bg-base-100 w-full h-full position: relative ${isOpen && 'border-solid border-2'}`}
        >
          {isOpen
            ? inputItems
                // .filter((item) => !inputValue || item.value.includes(inputValue))
                .map((item, index) => (
                  <li
                    {...getItemProps({
                      key: `${index}-${item.civic_number}`,
                      index,
                      item,
                      // style: {
                      //   backgroundColor:
                      //   highlightedIndex === index ? 'lightgray' : 'white',
                      //   fontWeight: selectedItem === item ? 'bold' : 'normal',
                      // },
                    })}
                  >
                    <a>
                      {`${item.civic_number} ${item.std_street}`}
                    </a>
                  </li>
                ))
            : null}
        </ul>
      </div>
    )}
    }
  </Downshift>
  )
}

export default LocationAutocomplete

    {/* <input
      type="text"
      placeholder="Starting point"
      className="input bg-gray-50 border-gray-300 text-sm block w-full p-2.5"
    /> */}