const BottomNav = ({handleClickDirections}) => {
  return (
    <div className="btm-nav">
      <button onClick={handleClickDirections}>
      <svg xmlns="http://www.w3.org/2000/svg" height="48" width="48"><path d="M16 30h3v-6.5h9.2v4.25L34 22l-5.8-5.8v4.3H17.5q-.65 0-1.075.425Q16 21.35 16 22Zm8 14.15q-.6 0-1.175-.2-.575-.2-.975-.6l-17.2-17.2q-.4-.4-.6-.975-.2-.575-.2-1.175 0-.6.2-1.175.2-.575.6-.975l17.2-17.2q.4-.4.975-.6.575-.2 1.175-.2.6 0 1.175.2.575.2.975.6l17.2 17.2q.4.4.6.975.2.575.2 1.175 0 .6-.2 1.175-.2.575-.6.975l-17.2 17.2q-.4.4-.975.6-.575.2-1.175.2ZM15.4 32.6l8.6 8.6L41.2 24 24 6.8 6.8 24ZM24 24Z"/></svg>
      </button>
      <button className="active">
        (other buttons here?)
      </button>

    </div>
  )
}

export default BottomNav