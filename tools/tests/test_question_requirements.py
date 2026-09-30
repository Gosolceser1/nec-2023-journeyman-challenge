"""The table/formula guard: data/question_requirements.json against the bank,
and the NEC calculation helpers in tools/pipeline/nec_calc.py."""
from __future__ import annotations

import copy
import importlib.util
import json
import math
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PIPELINE = ROOT / "tools" / "pipeline"
sys.path.insert(0, str(PIPELINE))


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, PIPELINE / f"{name}.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


nec_calc = _load("nec_calc")
check_requirements = _load("check_requirements")
check_worked_solutions = _load("check_worked_solutions")

BANK = json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
REQUIREMENTS = json.loads((ROOT / "data" / "question_requirements.json").read_text(encoding="utf-8"))


class BankRequirementsTests(unittest.TestCase):
    def test_every_table_and_calc_record_has_its_table_hint_and_check(self):
        self.assertEqual(check_requirements.check(BANK, REQUIREMENTS), [])

    def test_every_record_is_classified(self):
        ids = {r["id"] for r in BANK["records"]}
        self.assertEqual(ids, set(REQUIREMENTS["records"]))

    def test_worked_solutions_and_arithmetic_chains(self):
        self.assertEqual(check_worked_solutions.main_for(BANK["records"]), [])


class WorkedSolutionTests(unittest.TestCase):
    def scan(self, text):
        problems = []
        check_worked_solutions.scan_text("q-001", "worked", text, problems)
        return problems

    def test_parentheses_and_chained_results_are_evaluated_as_written(self):
        for text in ("(2 + 1) × 1500 VA = 4500 VA", "(4 + 4 + 5) kW × 0.55 = 7.15 kW",
                     "6 x 0.0437 + 2 x 0.0590 = 0.2622 + 0.1180 = 0.3802 square inches.",
                     "0.355 − 9 × 0.0181 = 0.355 − 0.1629 = 0.1921",
                     "4 in × 0.5 in = 2 sq in × 1,000 A = 2,000 A", "60/100 = 6/10 = 3/5"):
            self.assertEqual(self.scan(text), [], text)

    def test_wrong_arithmetic_is_still_reported(self):
        for text in ("(2 + 1) × 1500 VA = 3000 VA", "6 x 0.0437 + 2 x 0.0590 = 0.2622 + 0.1180 = 0.3902",
                     "60/100 = 6/10 = 2/5", "(10 / 125) × 100 = 9%"):
            self.assertEqual(len(self.scan(text)), 1, text)

    def test_formula_record_needs_a_recomputation(self):
        record = {"id": "q-001", "answers": ["20 A", "25 A"], "correct_index": 0, "formula": "I = P / E"}
        missing = check_worked_solutions.main_for([record], {"records": {}})
        self.assertEqual(missing, ["q-001: has formula/worked text but no check in question_requirements.json"])
        for req in ({"class": "calc", "check": {"kind": "quotient", "a": 2400, "b": 120}}, {"class": "table"}):
            self.assertEqual(check_worked_solutions.main_for([record], {"records": {"q-001": req}}), [])
        self.assertEqual(len(check_worked_solutions.main_for([record], {"records": {"q-001": {"class": "calc"}}})), 1)


class GuardRuleTests(unittest.TestCase):
    """Each rule fails a record that breaks it."""

    def setUp(self):
        self.record = {
            "id": "q-001", "answers": ["6,500", "8,000"], "correct_index": 0,
            "formula": "Multiply the floor area by the unit load.", "worked": "5,000 × 1.3 = 6,500 VA.",
            "reference_table": [["Type", "VA/ft²"], ["Office", "1.3"]], "reference_text": "Table 220.42(A)",
        }
        self.req = {"class": "table+calc", "tables": ["Table 220.42(A)"], "steps": ["5,000 × 1.3"],
                    "pre_answer_table": True,
                    "check": {"kind": "unit_load", "area_ft2": 5000, "occupancy": "office"}}

    def problems(self, record=None, req=None):
        bank = {"records": [record or self.record]}
        return check_requirements.check(bank, {"records": {"q-001": req or self.req}})

    def test_a_complete_record_passes(self):
        self.assertEqual(self.problems(), [])

    def test_unclassified_record_fails(self):
        self.assertTrue(check_requirements.check({"records": [self.record]}, {"records": {}}))

    def test_calc_without_formula_hint_fails(self):
        record = dict(self.record, formula="")
        self.assertIn("no formula hint", " ".join(self.problems(record)))

    def test_table_record_without_table_fails(self):
        record = dict(self.record, reference_table=[])
        self.assertIn("no table", " ".join(self.problems(record)))

    def test_tabbed_provision_counts_as_a_table(self):
        record = dict(self.record, reference_table=[], reference_text="Table X\nA\tB\n1\t2")
        req = dict(self.req, pre_answer_table=None)
        self.assertEqual(self.problems(record, req), [])

    def test_revealing_pre_answer_table_fails(self):
        req = dict(self.req, pre_answer_table=False)
        self.assertIn("gives the answer away", " ".join(self.problems(None, req)))

    def test_missing_pre_answer_table_fails(self):
        record = dict(self.record, table_after_answer=True)
        self.assertIn("pre-answer lookup table", " ".join(self.problems(record)))

    def test_wrong_keyed_answer_fails(self):
        record = dict(self.record, correct_index=1)
        self.assertIn("keyed answer", " ".join(self.problems(record)))

    def test_worked_solution_ending_elsewhere_fails(self):
        record = dict(self.record, worked="5,000 × 1.3 = 6,000 VA.")
        self.assertIn("worked solution ends at", " ".join(self.problems(record)))

    def test_calc_without_check_fails(self):
        req = copy.deepcopy(self.req)
        del req["check"]
        self.assertIn("no check", " ".join(self.problems(None, req)))

    def test_decimal_answer_without_leading_zero_is_read_as_a_decimal(self):
        self.assertEqual(check_requirements.as_number(".6875"), 0.6875)
        self.assertTrue(check_requirements.same_value(0.6875, ".6875"))
        self.assertEqual(check_requirements.as_number("1.5 m (5 ft)"), 1.5)


class CalcHelperTests(unittest.TestCase):
    """Textbook cases worked by hand from the NEC 2023 tables."""

    def test_box_fill(self):
        # 4 x 12 AWG, one device, internal clamps, EGCs: (4 + 2 + 1 + 1) x 2.25 in3
        self.assertAlmostEqual(nec_calc.box_fill_in3({"12": 4}, devices=1, clamps=True, egc=True), 18.0)
        # mixed sizes: allowances use the largest conductor
        self.assertAlmostEqual(nec_calc.box_fill_in3({"14": 2, "12": 2}, devices=1), 2 * 2.0 + 2 * 2.25 + 2 * 2.25)
        # a 21.0 in3 box holds ten 14 AWG (21 / 2.00 = 10.5)
        self.assertEqual(nec_calc.box_max_conductors(21.0, "14"), 10)

    def test_conduit_fill_matches_annex_c(self):
        emt, thhn = nec_calc.CH9_T4_EMT_IN2, nec_calc.CH9_T5_THHN_IN2
        self.assertEqual(nec_calc.conduit_max_conductors(emt["1/2"], thhn["14"]), 12)
        self.assertEqual(nec_calc.conduit_max_conductors(emt["1/2"], thhn["12"]), 9)
        self.assertEqual(nec_calc.conduit_max_conductors(emt["3/4"], thhn["12"]), 16)
        self.assertEqual(nec_calc.conduit_max_conductors(emt["1"], thhn["10"]), 16)
        self.assertAlmostEqual(nec_calc.conduit_fill_percent(emt["1/2"], [thhn["12"]] * 9), 39.375, places=2)

    def test_voltage_drop(self):
        self.assertAlmostEqual(nec_calc.voltage_drop(16, 100, "12"), 6.336, places=3)
        self.assertAlmostEqual(nec_calc.voltage_drop(16, 100, "12", k=nec_calc.K_COPPER), 6.322, places=3)
        self.assertAlmostEqual(nec_calc.voltage_drop(20, 150, "10", phases=3), math.sqrt(3) * 1.24 * 20 * 150 / 1000)

    def test_dwelling_general_lighting_demand(self):
        # 2,000 ft2: 6,000 + 3,000 small appliance + 1,500 laundry = 10,500 VA
        # 3,000 at 100 % + 7,500 at 35 % = 5,625 VA
        self.assertAlmostEqual(nec_calc.dwelling_lighting_demand_va(2000), 5625)
        self.assertAlmostEqual(nec_calc.dwelling_lighting_demand_va(50000),
                               3000 + 117000 * 0.35 + (154500 - 120000) * 0.25)

    def test_demand_tables(self):
        self.assertEqual(nec_calc.dryer_demand_pct(5), 85)
        self.assertEqual(nec_calc.dryer_demand_pct(12), 46)
        self.assertEqual(nec_calc.dryer_demand_pct(24), 34.5)
        self.assertEqual(nec_calc.dryer_demand_pct(43), 25)
        self.assertAlmostEqual(nec_calc.range_demand_kw(14), 8.8)
        self.assertAlmostEqual(nec_calc.range_demand_kw(12.5), 8.0)
        self.assertAlmostEqual(nec_calc.range_demand_kw(12.6), 8.4)

    def test_sizing(self):
        self.assertEqual(nec_calc.next_standard(86), 90)
        self.assertEqual(nec_calc.egc_cu(50), "10")
        self.assertAlmostEqual(nec_calc.ampacity(25, 1.0, 4), 20)
        self.assertAlmostEqual(nec_calc.evaluate(
            {"kind": "ampacity", "awg": "12", "column_c": 60, "ambient_f": 75, "ccc": 3}), 21.6)
        self.assertEqual(nec_calc.multioutlet_va(12), 540)
        self.assertEqual(nec_calc.multioutlet_va(12, simultaneous=True), 2160)

    def test_tables_come_from_the_edition_folder(self):
        import pipeline_paths
        edition = pipeline_paths.edition()
        self.assertEqual(nec_calc.nec_data("tables.json").parent, ROOT / "data" / edition["dir"])
        self.assertEqual(str(nec_calc.NEC["edition"]), str(edition["year"]))


if __name__ == "__main__":
    unittest.main()
