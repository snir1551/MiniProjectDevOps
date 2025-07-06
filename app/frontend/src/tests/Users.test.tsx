import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Users from '../components/Users';

// Mock fetch
beforeEach(() => {
  global.fetch = jest.fn((url, options) => {
    if (url?.toString().endsWith('/api/users') && (!options || options.method === 'GET')) {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve([
          { _id: '1', name: 'Danny', email: 'danny@example.com', createdAt: new Date().toISOString() },
        ]),
      }) as any;
    }
    if (url?.toString().endsWith('/api/users') && options?.method === 'POST') {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ _id: '2', name: 'Sarah', email: 'sarah@example.com', createdAt: new Date().toISOString() }),
      }) as any;
    }
    return Promise.reject(new Error('not found'));
  });
});
afterEach(() => {
  jest.resetAllMocks();
});


const mockUsers = [
  { _id: '1', name: 'Danny', email: 'danny@example.com' }
];
const mockRefreshUsers = jest.fn();

test('renders user list and add user form', async () => {
  render(
    <Users
      users={mockUsers}
      refreshUsers={mockRefreshUsers}
      loading={false}
    />
  );
  expect(screen.getByText('Users')).toBeInTheDocument();
  expect(await screen.findByText('Danny')).toBeInTheDocument();
  expect(screen.getByPlaceholderText('Name')).toBeInTheDocument();
});

test('can add a new user', async () => {
  render(
    <Users
      users={mockUsers}
      refreshUsers={mockRefreshUsers}
      loading={false}
    />
  );
  fireEvent.change(screen.getByPlaceholderText('Name'), { target: { value: 'Sarah' } });
  fireEvent.change(screen.getByPlaceholderText('Email'), { target: { value: 'sarah@example.com' } });
  fireEvent.click(screen.getByText('Add'));
  await waitFor(() => expect(global.fetch).toHaveBeenCalledWith(
    expect.stringContaining('/api/users'),
    expect.objectContaining({ method: 'POST' })
  ));
});
