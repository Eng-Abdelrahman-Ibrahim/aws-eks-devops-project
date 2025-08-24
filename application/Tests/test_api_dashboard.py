import requests
import time

BASE_URL = "http://localhost:8080"  # Java app default port

def wait_for_app(url, retries=10, delay=3):
    """Wait until the app responds or retries run out"""
    for i in range(retries):
        try:
            response = requests.get(url)
            if response.status_code == 200:
                return True
        except requests.exceptions.ConnectionError:
            pass
        time.sleep(delay)
    return False

def test_health_endpoint():
    """Verify /health endpoint (or actuator health)"""
    assert wait_for_app(f"{BASE_URL}/actuator/health"), "App did not become ready in time"
    response = requests.get(f"{BASE_URL}/actuator/health")
    assert response.status_code == 200
    assert "status" in response.json()
    assert response.json()["status"].upper() in ["UP", "OK", "HEALTHY"]


def test_metrics_endpoint():
    """Verify /metrics returns expected fields"""
    response = requests.get(f"{BASE_URL}/metrics")
    assert response.status_code == 200
    data = response.json()
    assert "cpuUsage" in data
    assert "memoryUsage" in data

def test_pipelines_endpoint():
    """Verify /pipelines returns a list"""
    response = requests.get(f"{BASE_URL}/pipelines")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_deployments_endpoint():
    """Verify /deployments returns a list"""
    response = requests.get(f"{BASE_URL}/deployments")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
