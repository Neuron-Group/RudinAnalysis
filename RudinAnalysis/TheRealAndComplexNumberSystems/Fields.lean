import RudinAnalysis.TheRealAndComplexNumberSystems.Import

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace Fields

open scoped BigOperators
open LinearOrder

-- Field Axioms
class FieldAxioms (α : Type*) extends
  Add α, Mul α, Zero α, One α, Neg α, Inv α where
  -- (A) Axioms of addition --
  A1 : ∀ x y : α, ∃ z : α, x + y = z
  A2 : ∀ x y : α, x + y = y + x
  A3 : ∀ x y z : α, x + y + z = x + (y + z)
  A4 : ∀ x : α, 0 + x = x
  A5 : ∀ x : α, x + (-x) = 0

  -- (M) Axioms of multiplication --
  M1 : ∀ x y : α, ∃ z : α, x * y = z
  M2 : ∀ x y : α, x * y = y * x
  M3 : ∀ x y z : α, x * y * z = x * (y * z)
  M4 : (1 : α) ≠ (0 : α) ∧ ∀ x : α, 1 * x = x
  M5 : ∀ x : α, x ≠ 0 -> x * x⁻¹ = 1

  -- (D) The distributive law --
  D  : ∀ x y z : α, x * (y + z) = x * y + x * z

-- 1.13, ℚ is exactly a Field --
instance : FieldAxioms ℚ where
  A1 := by
    intro x y
    use x + y
  A2 := by
    intro x y
    rw [add_comm]
  A3 := by
    intro x y z
    rw [add_assoc]
  A4 := by
    intro x
    rw [zero_add]
  A5 := by
    intro x
    rw [add_neg_cancel]

  M1 := by
    intro x y
    use x * y
  M2 := by
    intro x y
    rw [mul_comm]
  M3 := by
    intro x y z
    rw [mul_assoc]
  M4 := by
    constructor
    · decide
    · intro x
      rw [one_mul]
  M5 := by
    intro x xneq0
    exact Rat.mul_inv_cancel x xneq0

  D  := by
    intro x y z
    rw [mul_add]

section
open FieldAxioms
namespace FieldAxioms

-- 1.14 --
-- (a) --
theorem add_left_cancel {α : Type*} [FieldAxioms α] (x y z : α) : x + y = x + z -> y = z := by
  intro h
  rw [← A4 y, ← A5 x, A2 x (-x), A3, h, ← A3, A2 (-x) x, A5, A4]

-- (b) --
theorem add_left_cancel_zero {α : Type*} [FieldAxioms α] (x y : α) : x + y = x -> y = 0 := by
  intro h
  rw [← A4 y, ← A5 x, A2 x (-x), A3, h]

-- (c) --
theorem eq_neg_of_add_eq_zero {α : Type*} [FieldAxioms α] (x y : α) : x + y = 0 -> y = -x := by
  intro h
  rw [← A4 y, ← A5 x, A2 x (-x), A3, h, A2, A4]

-- (d) --
theorem neg_neg {α : Type*} [FieldAxioms α] (x : α) : - -x = x := by
  rw [← A4 (- -x), ← A5 x, A3, A5, A2, A4]

-- 1.15 --
-- (a) --
theorem mul_left_cancel {α : Type*} [FieldAxioms α]
    (x y z : α) : x ≠ 0 -> x * y = x * z -> y = z := by
  intro xneq0 h
  rw [
    ← M4.right y,
    ← M5 x xneq0,
    M2 x x⁻¹,
    M3,
    h,
    ← M3,
    M2 x⁻¹ x,
    M5 x xneq0,
    M4.right
  ]

-- (b) --
theorem mul_left_cancel_one {α : Type*} [FieldAxioms α]
    (x y : α) : x ≠ 0 -> x * y = x -> y = 1 := by
  intro xneq0 h
  rw [
    ← M4.right y,
    ← M5 x xneq0,
    M2 x x⁻¹,
    M3,
    h,
  ]

-- (c) --
example {α : Type*} [FieldAxioms α] (x y : α) : x ≠ 0 -> x * y = 1 -> y = x⁻¹ := by
  intro xneq0 h
  rw [← M5 x xneq0] at h
  exact mul_left_cancel x y x⁻¹ xneq0 h

-- (d) --
theorem add_left_congr {α : Type*} [FieldAxioms α] (x y z : α) : y = z -> x + y = x + z := by
  intro h
  rw [h]
theorem add_right_congr {α : Type*} [FieldAxioms α] (x y z : α) : y = z -> y + x = z + x := by
  intro h
  rw [h]
theorem x0_eq_0 {α : Type*} [FieldAxioms α] (x : α) : x * 0 = 0 := by
  rw [add_left_cancel (x * 0) (x * 0) 0]
  nth_rw 2 [A2]
  rw [A4]
  rw [← D]
  rw [A4]


theorem inv_inv {α : Type*} [FieldAxioms α] (x : α) : x ≠ 0 -> x⁻¹⁻¹ = x := by
  intro xneq0
  rw [
    ← M4.right x⁻¹⁻¹,
    ← M5 x xneq0,
    M3 x x⁻¹,
    M5,
    M2,
    M4.right x,
  ]
  intro ct
  have : x * x⁻¹ = 0 := by
    rw [ct, ← A4 0, D, A4, x0_eq_0, A4]
  rw [M5 x xneq0] at this
  have : (1 : α) ≠ (0 : α) := M4.left
  contradiction

end FieldAxioms
end

end Fields
