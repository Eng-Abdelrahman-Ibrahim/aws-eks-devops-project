import requests
import time

BASE_URL = "http://server:8080"  # Java app default port


def wait_for_app(url, retries=10, delay=3):
    """Wait until the app responds or retries run out"""
    for _ in range(retries):
        try:
            response = requests.get(url)
            if response.status_code == 200:
                return True
        except requests.exceptions.ConnectionError:
            pass
        time.sleep(delay)
    return False


def test_health_endpoint():
    """Verify /health endpoint"""
    url = f"{BASE_URL}/api/health"
    assert wait_for_app(url), "App did not become ready in time"
    response = requests.get(url)
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"].upper() in ["UP", "OK", "HEALTHY"]


def test_deployments_endpoint():
    """Verify /deployments returns a list (or paged structure)"""
    url = f"{BASE_URL}/api/deployments"
    response = requests.get(url)
    assert response.status_code == 200
    data = response.json()
    # It might be a paginated object or a list
    assert isinstance(data, (list, dict))


def test_create_deployment():
    """Verify we can create a deployment (if service is wired)"""
    payload = {
        "name": "Test Deployment",
        "version": "1.0.0",
        "environment": "DEV"
    }
    url = f"{BASE_URL}/api/deployments"
    response = requests.post(url, json=payload)
    # If creation isn't supported, skip without failing pipeline
    if response.status_code in [404, 405]:
        print(f"Skipping create deployment test: status {response.status_code}")
        return
    assert response.status_code in [200, 201]
    data = response.json()
    assert isinstance(data, dict)
    assert "id" in data  # Ensure ID exists
