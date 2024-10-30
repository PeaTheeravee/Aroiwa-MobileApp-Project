from fastapi.testclient import TestClient
from aroiwa.main import create_app

app = create_app()
client = TestClient(app)

# test การเข้าอ่านสูตรอาหารทั้งหมด
# def test_read_recipes():
#     response = client.get("/recipes/all")
#     assert response.status_code == 200
#     assert "recipes" in response.json()

# test การสร้างสูตรอาหาร (ไม่มี user)
def test_create_recipe():
    response_create = client.post("/recipes/create")
    assert response_create.status_code == 401

# test การเข้าอ่านสูตรอาหารแบบเจาะจง (ยังไม่มีสูตรอาหาร)
def test_read_recipes_ID():
    response_id = client.get("/1")
    assert response_id.status_code == 404
    # assert "recipes" in response.json()