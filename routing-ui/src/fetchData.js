// Example POST method implementation:
export async function postData(url = '', data = {}) {
  // Default options are marked with *
  const response = await fetch(url, {
    method: 'POST', // *GET, POST, PUT, DELETE, etc.
    mode: 'cors', // no-cors, *cors, same-origin
    cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
    credentials: 'same-origin', // include, *same-origin, omit
    headers: {
      'Content-Type': 'application/json',
      // 'Content-Type': 'application/x-www-form-urlencoded',
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZW1yZ2R2dXhnaGFpdGp5b2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQyMDM3MzMsImV4cCI6MTk3OTc3OTczM30.hNB_yvwYCn-5b65jnTX6wCsm7B1JjzKIflIEtMvzgEM'
    },
    redirect: 'follow', // manual, *follow, error
    referrerPolicy: 'no-referrer', // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
    body: JSON.stringify(data) // body data type must match "Content-Type" header
  });
  if (response.ok) {
    return response.json();
  }

  const errorData = await response.json()

  throw new Error(errorData.message)
}

export async function getData(url = '') {
  // Default options are marked with *
  const response = await fetch(url, {
    method: 'GET', // *GET, POST, PUT, DELETE, etc.
    mode: 'cors', // no-cors, *cors, same-origin
    cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
    credentials: 'same-origin', // include, *same-origin, omit
    headers: {
      'Content-Type': 'application/json',
      // 'Content-Type': 'application/x-www-form-urlencoded',
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZW1yZ2R2dXhnaGFpdGp5b2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQyMDM3MzMsImV4cCI6MTk3OTc3OTczM30.hNB_yvwYCn-5b65jnTX6wCsm7B1JjzKIflIEtMvzgEM'
    },
    redirect: 'follow', // manual, *follow, error
    referrerPolicy: 'no-referrer', // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
    // body: JSON.stringify(data) // body data type must match "Content-Type" header
  });

  if (response.ok) {
    return response.json();
  }

  const errorData = await response.json()

  throw new Error(errorData.message)
}