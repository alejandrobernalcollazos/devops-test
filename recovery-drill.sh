#!/bin/bash

# Simulate primary region failure
echo "Simulating primary region failure..."
aws route53 update-health-check --health-check-id <health check id> --inverted

# Wait for Route 53 failover
echo "Waiting for failover..."
sleep 120

# Test secondary region endpoint
echo "Testing secondary region..."
curl -I https://zealous.alejandroaws.com

# Re-enable primary region health check
echo "Restoring primary region health check..."
aws route53 update-health-check --health-check-id <health check id> --no-inverted

echo "Disaster recovery test complete!"