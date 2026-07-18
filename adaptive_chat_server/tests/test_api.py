from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_start_conversation_returns_id_and_post_next():
    resp = client.post("/conversations")
    assert resp.status_code == 200
    body = resp.json()
    cid = body["conversationId"]
    assert cid.startswith("c_")
    assert body["links"]["postNext"] == f"/conversations/{cid}/interactions"
