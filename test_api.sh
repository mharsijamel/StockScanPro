#!/bin/bash

# Test script to verify API endpoints
echo "Testing StockScan Pro API endpoints..."
echo "======================================"

BASE_URL="https://smart.webvue.tn"

echo "1. Testing health endpoint..."
curl -X GET "$BASE_URL/api/health" \
  -H "Content-Type: application/json" \
  -w "\nStatus: %{http_code}\n" \
  -s

echo -e "\n2. Testing database list endpoint..."
curl -X GET "$BASE_URL/api/databases" \
  -H "Content-Type: application/json" \
  -w "\nStatus: %{http_code}\n" \
  -s

echo -e "\n3. Testing auth endpoint with demo data..."
curl -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "X-Openerp-Database: SMARTTEST" \
  -d '{
    "username": "admin",
    "password": "admin"
  }' \
  -w "\nStatus: %{http_code}\n" \
  -s

echo -e "\n4. Testing pickings endpoint..."
curl -X POST "$BASE_URL/api/pickings" \
  -H "Content-Type: application/json" \
  -H "X-Openerp-Database: SMARTTEST" \
  -d '{
    "token": "dummy_token",
    "type": "in"
  }' \
  -w "\nStatus: %{http_code}\n" \
  -s

echo -e "\nTest completed!"