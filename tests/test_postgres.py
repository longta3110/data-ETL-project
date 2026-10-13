"""Run with RUN_POSTGRES_TESTS=1 and PG* variables pointing to a test database."""
import os
from pathlib import Path
import tempfile
import unittest
from datetime import datetime

from openpyxl import Workbook
from pipeline import HEADERS, run, load


@unittest.skipUnless(os.environ.get('RUN_POSTGRES_TESTS') == '1', 'PostgreSQL integration not enabled')
class PostgresTests(unittest.TestCase):
    def test_repeated_load_preserves_count_and_total(self):
        import psycopg
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            book = Workbook()
            book.active.append(HEADERS)
            book.active.append(['100001', '12345', 'Test', 2, datetime(2011, 1, 1), 3.5, None, 'UK'])
            book.active.append(['C100001', '12345', 'Test', -1, datetime(2011, 1, 2), 3.5, None, 'UK'])
            book.save(root / 'test.xlsx')
            report = run(root / 'test.xlsx', root / 'reports')
            try:
                load(root / 'reports', report)
                load(root / 'reports', report)
                with psycopg.connect('') as conn:
                    count = conn.execute('SELECT count(*) FROM retail.staging_line WHERE dataset_id=%s',
                                         (report['dataset_id'],)).fetchone()[0]
                    self.assertEqual(count, 2)
                self.assertTrue((root / 'reports/monthly_analysis.csv').exists())
            finally:
                with psycopg.connect('') as conn:
                    conn.execute('DELETE FROM retail.staging_line WHERE dataset_id=%s', (report['dataset_id'],))
                    conn.execute('DELETE FROM retail.dataset WHERE dataset_id=%s', (report['dataset_id'],))
