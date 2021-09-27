import app
import unittest
import mockfs


class TestServer(unittest.TestCase):

    def setUp(self):
        self.app = app.app.test_client()
        self.app.testing = True

        self.mfs = mockfs.replace_builtins()
        self.mfs.add_entries({
            "/var/visithist": """2021-9-27 10:7:56.212372 127.0.0.1
2021-9-27 10:7:56.212372 0.0.0.0
"""
        })

    def tearUp(self):
        mockfs.restore_builtins()

    def test_status_code(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)

    def test_visit_count(self):
        response = self.app.get('/visits')
        self.assertNotEqual(response.get_data(True).find(": 2"), -1)

    def test_visit_is_updated(self):
        self.test_status_code()
        response = self.app.get('/visits')
        self.assertNotEqual(response.get_data(True).find(": 3"), -1)
        self.assertEqual(len(response.get_data(True).splitlines()), 4)

        self.test_status_code()
        self.test_status_code()
        response = self.app.get('/visits')
        self.assertNotEqual(response.get_data(True).find(": 5"), -1)
        self.assertEqual(len(response.get_data(True).splitlines()), 6)

    def test_empty_visithist(self):
        mockfs.restore_builtins()
        self.mfs = mockfs.replace_builtins()
        self.mfs.add_entries({"/var/visithist": ""})

        response = self.app.get('/visits')
        self.assertEqual(response.status_code, 200)
        self.assertNotEqual(response.get_data(True).find(": 0"), -1)
        self.assertEqual(len(response.get_data(True).split('\n')), 2)


if __name__ == '__main__':
    unittest.main()
