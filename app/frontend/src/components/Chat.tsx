import React, { useEffect, useState } from 'react';

interface User {
  _id: string;
  name: string;
  email: string;
}

interface ChatProps {
  users: User[];
  refreshUsers: () => void;
  loading: boolean;
}

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

const Chat: React.FC<ChatProps> = ({ users, loading }) => {
  const [messages, setMessages] = useState<any[]>([]);
  const [user, setUser] = useState('');
  const [text, setText] = useState('');

  const fetchMessages = async () => {
    const res = await fetch(`${API_URL}/messages`);
    const data = await res.json();
    setMessages(Array.isArray(data) ? data : []);
  };

  useEffect(() => {
    fetchMessages();
    // eslint-disable-next-line
  }, []);

  useEffect(() => {
    if (users.length > 0 && !user) setUser(users[0].name);
  }, [users, user]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !text) return;
    await fetch(`${API_URL}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user, text }),
    });
    setText('');
    fetchMessages();
  };

  if (loading) return <div>Loading chat...</div>;

  return (
    <div style={{ maxWidth: 500, margin: '2rem auto', padding: 24, background: '#f9f9f9', borderRadius: 8 }}>
      <h2>Chat</h2>
      <div style={{ maxHeight: 300, overflowY: 'auto', marginBottom: 16, background: '#fff', padding: 8, borderRadius: 4, border: '1px solid #eee' }}>
        {messages.map((msg, idx) => (
          <div key={idx} style={{ marginBottom: 8 }}>
            <strong>{msg.user}:</strong> {msg.text}
          </div>
        ))}
      </div>
      {users.length === 0 ? (
        <div style={{ color: 'red', textAlign: 'center' }}>No registered users. Please add a user before sending a message.</div>
      ) : (
        <form onSubmit={handleSend} style={{ display: 'flex', gap: 8 }}>
          <select
            value={user}
            onChange={e => setUser(e.target.value)}
            required
            style={{ flex: 1, padding: 8 }}
          >
            {users.map(u => (
              <option key={u._id} value={u.name}>{u.name}</option>
            ))}
          </select>
          <input
            type="text"
            placeholder="Message"
            value={text}
            onChange={e => setText(e.target.value)}
            required
            style={{ flex: 2, padding: 8 }}
          />
          <button type="submit" style={{ padding: '8px 16px', background: '#0074D9', color: '#fff', border: 'none', borderRadius: 4 }}>Send</button>
        </form>
      )}
    </div>
  );
};

export default Chat;