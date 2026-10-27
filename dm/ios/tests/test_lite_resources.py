import importlib.util
import tempfile
import unittest
import zipfile
import hashlib
from pathlib import Path
spec = importlib.util.spec_from_file_location('lite', Path(__file__).parents[1]/'tools/lite_resources.py')
lite = importlib.util.module_from_spec(spec); spec.loader.exec_module(lite)

class LiteResourcesTests(unittest.TestCase):
    def test_export_and_reject_symlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); r=p/'romfs'; r.mkdir(); (r/'nested').mkdir(); (r/'nested/data').write_bytes(b'example')
            a=p/'aoc'; a.mkdir(); (a/'1').mkdir(); (a/'1/data').write_bytes(b'dlc')
            for dlc in (None, a):
                m=lite.export(r,dlc,p/'data.zip',p/'manifest.json','0100000000000000','1.0')
                with zipfile.ZipFile(p/'data.zip') as z:
                    self.assertEqual(len(z.namelist()),2 if dlc else 1)
                    for e in m['files']:
                        d=z.read(e['path']); self.assertEqual(len(d),e['size']); self.assertEqual(hashlib.sha256(d).hexdigest(),e['sha256'])
            (r/'escape').symlink_to(p/'manifest.json')
            with self.assertRaises(ValueError): lite.export(r,None,p/'bad.zip',p/'bad.json','test','1')
            self.assertFalse((p/'bad.zip').exists())
    def test_output_inside_resource_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)
            with self.assertRaises(ValueError): lite.export(p,None,p/'data.zip',p/'manifest.json','test','1')

if __name__=='__main__': unittest.main()
