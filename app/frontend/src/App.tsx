import React, { useEffect, useState } from 'react';
import Users from './components/Users';
import Chat from './components/Chat';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

function App() {
  const [users, setUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(true);

  const fetchUsers = async () => {
    setLoadingUsers(true);
    const res = await fetch(`${API_URL}/api/users`);
    const data = await res.json();
    setUsers(data);
    setLoadingUsers(false);
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return (
    <div>
      <Users users={users} refreshUsers={fetchUsers} loading={loadingUsers} />
      <Chat users={users} refreshUsers={fetchUsers} loading={loadingUsers} />
    </div>
  );
}

export default App;