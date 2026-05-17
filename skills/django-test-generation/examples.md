# Examples (Django Test Generation)

These are *patterns* to emulate (shortened for readability).

## Example 1: Endpoint happy path + auth requirement

**Target behavior**: authenticated user can fetch their own profile; unauthenticated gets 401.

**Test shape**:

```python
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from api.users.factories import UserFactory


class TestAuthMe(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = UserFactory()

    def test_get_me(self):
        """GET /api/users/auth/me/ requires authentication."""
        # Unauthenticated
        response = self.client.get("/api/users/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        # Authenticated
        """GET /api/users/auth/me/ returns current user info."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get("/api/users/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data["id"], self.user.id)
        self.assertEqual(data["username"], self.user.username)
```

## Example 2: Permissions matrix (admin vs member vs non-member)

**Target behavior**: an “admin-only” action returns 204 for admins, 403 for members, 404 for non-members.

**Test shape**:

```python
def test_delete_something(self):
    """DELETE /api/.../:id/delete/ — admin 204; member 403; non-member 404."""
    # Admin: 204 + side effect
    self.client.force_authenticate(user=self.admin_user)
    response = self.client.delete(f"/api/.../{obj_id}/delete/")
    self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
    self.assertFalse(Model.objects.filter(pk=obj_id).exists())

    # Member: 403 + message
    self.client.force_authenticate(user=self.member_user)
    response = self.client.delete(f"/api/.../{obj_id}/delete/")
    self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    self.assertEqual(response.json(), {"detail": "You must be an admin of this <Thing>."})

    # Non-member: 404 + message
    self.client.force_authenticate(user=self.other_user)
    response = self.client.delete(f"/api/.../{obj_id}/delete/")
    self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
```

