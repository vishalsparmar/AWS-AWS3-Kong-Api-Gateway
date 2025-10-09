#!/bin/bash

# Kong Konnect Service and Route Creator
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-kong-config.yaml}"
KONNECT_TOKEN="${KONNECT_TOKEN}"

if [[ -z "$KONNECT_TOKEN" ]]; then
    echo "Error: KONNECT_TOKEN environment variable is required"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file $CONFIG_FILE not found"
    exit 1
fi

# Parse configuration
CONTROL_PLANE_ID=$(yq e '.control_plane_id' "$CONFIG_FILE")
REGION=$(yq e '.region' "$CONFIG_FILE")
BASE_URL="https://$REGION.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core/entities"

echo "🚀 Deploying to Kong Konnect Control Plane: $CONTROL_PLANE_ID"
echo "📍 Region: $REGION"
echo "📁 Config: $CONFIG_FILE"

# Function to make API requests
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    curl -s -X "$method" \
        -H "Authorization: Bearer $KONNECT_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$data" \
        "$BASE_URL/$endpoint"
}

# Function to check if entity exists
entity_exists() {
    local entity_type=$1
    local entity_name=$2
    
    response=$(curl -s -H "Authorization: Bearer $KONNECT_TOKEN" \
        "$BASE_URL/$entity_type")
    
    echo "$response" | jq -e --arg name "$entity_name" \
        '.data[] | select(.name == $name)' > /dev/null 2>&1
}

# Create service
create_service() {
    local service_config=$1
    
    local name=$(echo "$service_config" | yq e '.name' -)
    local host=$(echo "$service_config" | yq e '.host' -)
    local port=$(echo "$service_config" | yq e '.port' -)
    local protocol=$(echo "$service_config" | yq e '.protocol' -)
    local path=$(echo "$service_config" | yq e '.path' -)
    local tags=$(echo "$service_config" | yq e '.tags | join(",")' -)
    
    echo "📦 Creating service: $name"
    
    # Check if service already exists
    if entity_exists "services" "$name"; then
        echo "⚠️  Service $name already exists, skipping..."
        return 0
    fi
    
    service_data=$(jq -n \
        --arg name "$name" \
        --arg host "$host" \
        --arg port "$port" \
        --arg protocol "$protocol" \
        --arg path "$path" \
        --arg tags "$tags" \
        '{
            name: $name,
            host: $host,
            port: ($port | tonumber),
            protocol: $protocol,
            path: $path,
            tags: ($tags | split(","))
        }')
    
    response=$(api_request "POST" "services" "$service_data")
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local service_id=$(echo "$response" | jq -r '.id')
        echo "✅ Service created: $name (ID: $service_id)"
        return 0
    else
        echo "❌ Failed to create service: $name"
        echo "Response: $response"
        return 1
    fi
}

# Create route for service
create_route() {
    local service_name=$1
    local route_config=$2
    
    local route_name=$(echo "$route_config" | yq e '.name' -)
    local paths=$(echo "$route_config" | yq e '.paths | join(",")' -)
    local methods=$(echo "$route_config" | yq e '.methods | join(",")' -)
    local strip_path=$(echo "$route_config" | yq e '.strip_path // "true"' -)
    local tags=$(echo "$route_config" | yq e '.tags | join(",")' -)
    
    echo "  🛣️  Creating route: $route_name"
    
    # Check if route already exists
    if entity_exists "routes" "$route_name"; then
        echo "  ⚠️  Route $route_name already exists, skipping..."
        return 0
    fi
    
    # Get service ID
    service_response=$(curl -s -H "Authorization: Bearer $KONNECT_TOKEN" \
        "$BASE_URL/services")
    service_id=$(echo "$service_response" | jq -r --arg name "$service_name" \
        '.data[] | select(.name == $name) | .id')
    
    if [[ -z "$service_id" ]]; then
        echo "  ❌ Service $service_name not found"
        return 1
    fi
    
    route_data=$(jq -n \
        --arg name "$route_name" \
        --arg service_id "$service_id" \
        --arg paths "$paths" \
        --arg methods "$methods" \
        --argjson strip_path "$strip_path" \
        --arg tags "$tags" \
        '{
            name: $name,
            service: { id: $service_id },
            paths: ($paths | split(",")),
            methods: ($methods | split(",")),
            strip_path: $strip_path,
            tags: ($tags | split(","))
        }')
    
    response=$(api_request "POST" "routes" "$route_data")
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local route_id=$(echo "$response" | jq -r '.id')
        echo "  ✅ Route created: $route_name (ID: $route_id)"
        return 0
    else
        echo "  ❌ Failed to create route: $route_name"
        echo "  Response: $response"
        return 1
    fi
}

# Main deployment function
deploy_configuration() {
    local services_count=$(yq e '.services | length' "$CONFIG_FILE")
    echo "📊 Found $services_count services to deploy"
    
    for i in $(seq 0 $((services_count - 1))); do
        service_config=$(yq e ".services[$i]" "$CONFIG_FILE" -o json)
        service_name=$(echo "$service_config" | jq -r '.name')
        
        # Create service
        if create_service "$service_config"; then
            # Create routes for this service
            routes_count=$(echo "$service_config" | jq -r '.routes | length')
            for j in $(seq 0 $((routes_count - 1))); do
                route_config=$(echo "$service_config" | jq -r ".routes[$j]")
                create_route "$service_name" "$route_config"
            done
        fi
        echo ""
    done
}

# Run deployment
deploy_configuration

echo "🎉 Deployment completed!"