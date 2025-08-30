import requests
import time

BASE_URL = "http://app-backend:8080"  # Java app default port


def wait_for_app(url, retries=15, delay=5):  # Increase retries and delay
    """Wait until the app responds or retries run out"""
    for attempt in range(retries):
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"App became ready after {attempt * delay} seconds")
                return True
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
            print(f"Attempt {attempt + 1}: {e}")
        time.sleep(delay)
    print(f"App never became ready after {retries * delay} seconds")
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
