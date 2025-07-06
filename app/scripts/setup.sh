#!/bin/bash

echo "🔧 Checking & Installing dependencies..."


if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y docker.io
else
  echo "✅ Docker already installed."
fi


if ! command -v docker-compose &> /dev/null; then
  echo "📦 Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "✅ Docker Compose already installed."
fi