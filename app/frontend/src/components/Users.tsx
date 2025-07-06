import React, { useState } from 'react';

interface User {
  _id: string;
  name: string;
  email: string;
}

interface UsersProps {
  users: User[];
  refreshUsers: () => void;
  loading: boolean;
}

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

const Users: React.FC<UsersProps> = ({ users, refreshUsers, loading }) => {
  const [error, setError] = useState('');
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [newUser, setNewUser] = useState({ name: '', email: '' });
  const [alreadyRegistered, setAlreadyRegistered] = useState(
    !!localStorage.getItem('registeredUser')
  );

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this user?')) return;
    setDeletingId(id);
    try {
      const res = await fetch(`${API_URL}/api/users/${id}`, { method: 'DELETE' });
      if (res.ok) {
        refreshUsers();
      } else {
        setError('Failed to delete user');
      }
    } catch {
      setError('Failed to delete user');
    }
    setDeletingId(null);
  };

  const handleAddUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUser.name || !newUser.email) return;
    if (alreadyRegistered) {
      setError('You have already registered a user from this computer.');
      return;
    }
    try {
      const res = await fetch(`${API_URL}/api/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newUser),
      });
      if (res.ok) {
        setNewUser({ name: '', email: '' });
        refreshUsers();
        localStorage.setItem('registeredUser', 'true');
        setAlreadyRegistered(true);
      } else {
        setError('Failed to add user');
      }
    } catch {
      setError('Failed to add user');
    }
  };

  if (loading) return <div>Loading users...</div>;
  if (error) return <div style={{ color: 'red' }}>{error}</div>;

  return (
    <div style={{ maxWidth: 600, margin: '2rem auto', padding: 24, background: '#fff', borderRadius: 8, boxShadow: '0 2px 8px #eee' }}>
      <h2 style={{ textAlign: 'center' }}>Users</h2>
      <form onSubmit={handleAddUser} style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <input
          type="text"
          placeholder="Name"
          value={newUser.name}
          onChange={e => setNewUser({ ...newUser, name: e.target.value })}
          required
          style={{ flex: 1, padding: 8 }}
          disabled={alreadyRegistered}
        />
        <input
          type="email"
          placeholder="Email"
          value={newUser.email}
          onChange={e => setNewUser({ ...newUser, email: e.target.value })}
          required
          style={{ flex: 1, padding: 8 }}
          disabled={alreadyRegistered}
        />
        <button
          type="submit"
          style={{ padding: '8px 16px', background: '#2ecc40', color: '#fff', border: 'none', borderRadius: 4 }}
          disabled={alreadyRegistered}
        >
          Add
        </button>
      </form>
      {alreadyRegistered && (
        <div style={{ color: 'red', marginBottom: 8 }}>
          You have already registered a user from this computer.
        </div>
      )}
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {users.map(user => (
          <li key={user._id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: 12, borderBottom: '1px solid #eee' }}>
            <span>
              <strong>{user.name}</strong> <span style={{ color: '#888' }}>({user.email})</span>
            </span>
            <button
              onClick={() => handleDelete(user._id)}
              disabled={deletingId === user._id}
              style={{
                background: '#e74c3c',
                color: '#fff',
                border: 'none',
                borderRadius: 4,
                padding: '6px 14px',
                cursor: 'pointer',
                opacity: deletingId === user._id ? 0.6 : 1
              }}
            >
              {deletingId === user._id ? 'Deleting...' : 'Delete'}
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default Users;
