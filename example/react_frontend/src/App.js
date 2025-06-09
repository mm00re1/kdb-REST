import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import SnapshotPage from './pages/SnapshotPage';
import LivePage from './pages/LivePage';
import './App.css';

function App() {
  return (
    <Router>
      <Navbar />
      <Routes>
        <Route path="/" element={<SnapshotPage />} />
        <Route path="/live" element={<LivePage />} />
      </Routes>
    </Router>
  );
}

export default App;
