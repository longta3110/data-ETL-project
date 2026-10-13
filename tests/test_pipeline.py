import unittest
from datetime import datetime
from decimal import Decimal
from pathlib import Path
import tempfile

from openpyxl import Workbook
from pipeline import HEADERS, validate, run


class ValidationTests(unittest.TestCase):
    def row(self, **changes):
        row = dict(zip(HEADERS, ['100001', '12345', 'Gift', 2, datetime(2011, 1, 1), 3.5, 12345, 'UK']))
        row.update(changes)
        return list(row.values())

    def test_sale(self):
        r, errors, warnings = validate(self.row())
        self.assertEqual(errors, [])
        self.assertEqual(r[-1], 'sale')

    def test_cancellation_retained(self):
        r, errors, _ = validate(self.row(InvoiceNo='C100001', Quantity=-2))
        self.assertEqual(errors, [])
        self.assertEqual(r[-1], 'cancellation')

    def test_missing_customer_is_warning(self):
        _, errors, warnings = validate(self.row(CustomerID=None))
        self.assertEqual(errors, [])
        self.assertIn('missing_customer_id', warnings)

    def test_invalid_values(self):
        for changes in [dict(UnitPrice=-1), dict(UnitPrice=float('nan')),
                        dict(Quantity=0), dict(Quantity=1.5), dict(InvoiceDate='bad'),
                        dict(InvoiceNo=''), dict(Quantity=-1), dict(InvoiceNo='C1')]:
            with self.subTest(changes=changes):
                self.assertTrue(validate(self.row(**changes))[1])

    def test_reconciliation_and_repeatability(self):
        with tempfile.TemporaryDirectory() as d:
            source, output = Path(d) / 'test.xlsx', Path(d) / 'out'
            book = Workbook()
            book.active.append(HEADERS)
            for row in [self.row(), self.row(), self.row(InvoiceNo='C1', Quantity=-1), self.row(UnitPrice=0)]:
                book.active.append(row)
            book.save(source)
            a, b = run(source, output), run(source, output)
            self.assertEqual(a, b)
            self.assertEqual(a['counts'], {'source_rows': 4, 'accepted_rows': 3, 'quarantined_rows': 1})
            self.assertEqual(a['warnings']['duplicate_candidate'], 1)
            self.assertEqual(Decimal(a['net_transaction_value_gbp']), Decimal('10.5'))


if __name__ == '__main__':
    unittest.main()
