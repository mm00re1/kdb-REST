import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import './Navbar.css';

const Navbar = () => {
  const [selectedPage, setSelectedPage] = useState('snapshot'); // Default to 'home' or whichever page

  const handlePageSelect = (page) => {
    setSelectedPage(page);
  };

  return (
    <nav className="navbar">
      <ul className="navbar-list">
        <li
          onClick={() => handlePageSelect('snapshot')}
          className={selectedPage === 'snapshot' ? 'navbar-item-bold' : 'navbar-item'}
        >
          <Link to="/">Snapshot</Link></li>
        <li
          onClick={() => handlePageSelect('live')}
          className={selectedPage === 'snapshot' ? 'navbar-item' : 'navbar-item-bold'}
        >
          <Link to="/live">Live</Link></li>
      </ul>
    </nav>
  );
};

export default Navbar;
