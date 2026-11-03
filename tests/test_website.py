import unittest
import os
from urllib.request import urlopen
#if the enviorment var wasn't defined, use  8080
#we want this to make the test useful in more than one env(for example in 2 containers)
BASE_URL = os.environ.get("BASE_URL", "http://localhost:8080")

class WebsiteTests(unittest.TestCase):
    def test_homepage(self):
        with urlopen(BASE_URL, timeout=5) as response:
	# HTTP 200 means the request succeeded
            self.assertEqual(response.status, 200)

            html = response.read().decode("utf-8")
            self.assertIn("<h1>My first Linux website</h1>", html)


if __name__ == "__main__":
    unittest.main()
