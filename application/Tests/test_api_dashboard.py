import requests
import time

BASE_URL = "http://localhost:8080/api"  # API base path

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
    """Verify /api/health endpoint"""
    assert wait_for_app(f"{BASE_URL}/health"), "App did not become ready in time"
    response = requests.get(f"{BASE_URL}/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"].upper() in ["OK", "UP", "HEALTHY"]


def test_deployments_list_endpoint():
    """Verify /api/deployments returns a valid response"""
    response = requests.get(f"{BASE_URL}/deployments")
    assert response.status_code == 200
    data = response.json()
    # Spring Data returns a Page object, verify keys exist
    assert "content" in data
    assert isinstance(data["content"], list)
    assert "totalElements" in data
    assert "totalPages" in data


def test_create_deployment():
    """Verify we can create a deployment (if service is wired)"""
    payload = {
        "name": "Test Deployment",
        "version": "1.0.0",
        "environment": "DEV"
    }
    response = requests.post(f"{BASE_URL}/deployments", json=payload)
    assert response.status_code in [200, 201]
    data = response.json()
    assert isinstance(data, dict)
    assert "id" in data  # Ensure ID exists
    # Optional: check that at least one of these keys exists
    assert any(key in data for key in ["name", "deploymentName", "deploymentId"])
