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
variable {α : Type*} [FieldAxioms α]

-- 1.14 --
-- (a) --
theorem add_left_cancel (x y z : α) : x + y = x + z -> y = z := by
  intro h
  rw [← A4 y, ← A5 x, A2 x (-x), A3, h, ← A3, A2 (-x) x, A5, A4]

-- (b) --
theorem add_left_cancel_zero {y : α} (x : α) : x + y = x -> y = 0 := by
  intro h
  rw [← A4 y, ← A5 x, A2 x (-x), A3, h]

-- (c) --
theorem eq_neg_of_add_eq_zero {x y : α} : x + y = 0 -> y = -x := by
  intro h
  rw [← A4 y, ← A5 x, A2 x (-x), A3, h, A2, A4]

-- (d) --
theorem neg_neg {x : α} : - -x = x := by
  rw [← A4 (- -x), ← A5 x, A3, A5, A2, A4]

-- 1.15 --
-- (a) --
theorem mul_left_cancel {x y z : α}
  : x ≠ 0 -> x * y = x * z -> y = z := by
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
theorem mul_left_cancel_one {x y : α}
  : x ≠ 0 -> x * y = x -> y = 1 := by
  intro xneq0 h
  rw [
    ← M4.right y,
    ← M5 x xneq0,
    M2 x x⁻¹,
    M3,
    h,
  ]

-- (c) --
example {x y : α}
  : x ≠ 0 -> x * y = 1 -> y = x⁻¹ := by
  intro xneq0 h
  rw [← M5 x xneq0] at h
  exact mul_left_cancel xneq0 h

-- (d) --
theorem add_left_congr {y z : α} (x : α) : y = z -> x + y = x + z := by
  intro h
  rw [h]
theorem add_right_congr {y z : α} (x : α) : y = z -> y + x = z + x := by
  intro h
  rw [h]
theorem x0_eq_0 (x : α) : x * 0 = 0 := by
  rw [add_left_cancel (x * 0) (x * 0) 0]
  nth_rw 2 [A2]
  rw [A4]
  rw [← D]
  rw [A4]


theorem inv_inv {x : α} : x ≠ 0 -> x⁻¹⁻¹ = x := by
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

-- 1.16 --
theorem mul_ne_zero_of_ne_zero {x y : α} :
  x ≠ 0 -> y ≠ 0 -> x * y ≠ 0 := by
    intro xneq0 yneq0
    by_contra
    rw [← x0_eq_0 x] at this
    have := mul_left_cancel xneq0 this
    contradiction

theorem neg_mul (x y : α) :
  -x * y = -(x * y) := by
    apply eq_neg_of_add_eq_zero
    rw [M2, M2 (-x)]
    rw [← D, A5, x0_eq_0]

theorem mul_neg (x y : α) :
  x * -y = -(x * y) := by
    rw [M2, neg_mul, M2]

end FieldAxioms
end

-- 1.17 --
class OrderedField (α : Type*) extends
  LinearOrder α, FieldAxioms α where
    add_lt_add_left : ∀ x y z : α, y < z -> x + y < x + z
    mul_pos_of_pos : ∀ x y : α, 0 < x -> 0 < y -> 0 < x * y

-- Rational Field is exactly a ordered field.
instance : OrderedField ℚ where
  add_lt_add_left := by
    intro x y z yltz
    exact Rat.add_lt_add_left.mpr yltz
  mul_pos_of_pos := by
    intro x y xpos ypos
    exact (Rat.mul_pos_iff_of_pos_left xpos).mpr ypos

section -- 1.18 --
open FieldAxioms OrderedField
namespace OrderedField
variable {α : Type*} [OrderedField α]

theorem mul_neg_one (x : α) : -(1 : α) * x = -x := by
  rw [neg_mul (1 : α) x]
  rw [M4.right]

theorem neg_lt_zero_of_pos {x : α} : 0 < x -> -x < 0 := by
  intro xpos
  -- rw [← mul_neg_one]
  have := add_lt_add_left (-x) 0 x xpos
  rw [A2] at this
  rw [A4, A2, A5] at this
  exact this

theorem mul_lt_mul_left_of_pos {x y z : α} : 0 < x -> y < z -> x * y < x * z := by
  intro xpos yltz
  rw [
    ← A4 (x * y), ← A4 (x * z),
    ← A5 (x * y),
    A2, A3,
  ]
  apply OrderedField.add_lt_add_left
  rw [A5, ← FieldAxioms.mul_neg, ← D]
  have : -y + z > 0 := by
    have := OrderedField.add_lt_add_left (-y) y z yltz
    rw [A2, A5] at this
    exact this
  exact mul_pos_of_pos x (-y + z) xpos this

theorem mul_lt_mul_left_of_neg {x y z : α} : x < 0 -> y < z -> x * z < x * y := by
  intro xneg yltz
  have nxpos : 0 < -x := by
    have := OrderedField.add_lt_add_left (-x) x 0 xneg
    rw [A2, A5, A2, A4] at this
    exact this
  have zaddnegypos : 0 < z + -y := by
    have := add_lt_add_left (-y) y z yltz
    rw [A2, A5, A2] at this
    exact this
  have := mul_pos_of_pos (-x) (z + -y) nxpos zaddnegypos
  rw [D] at this
  nth_rw 1 [FieldAxioms.neg_mul x (-y)] at this
  nth_rw 1 [FieldAxioms.mul_neg x y] at this
  rw [FieldAxioms.neg_neg] at this
  have := add_lt_add_left (x * z) 0 (-x * z + x * y) this
  rw [
    A2, A4, ← A3,
    FieldAxioms.neg_mul x z,
    A5, A4
  ] at this
  exact this

theorem mul_self_pos {x : α} : x ≠ 0 -> 0 < x * x := by
  intro xneq0
  by_cases h : 0 < x
  · exact mul_pos_of_pos x x h h
  · push Not at h
    have : x < 0 := by
      exact Std.lt_of_le_of_ne h xneq0
    have : 0 < -x := by
      have := add_lt_add_left (-x) x 0 this
      rw [A2, A5, A2, A4] at this
      exact this
    have := mul_pos_of_pos (-x) (-x) this this
    rw [FieldAxioms.neg_mul, FieldAxioms.mul_neg, FieldAxioms.neg_neg] at this
    exact this

theorem one_mul_one : (1 : α) * (1 : α) = (1 : α) := by
  rw [M4.right]

theorem zero_lt_one : (0 : α) < (1 : α) := by
  have one_neq_0 : (1 : α) ≠ (0 : α) := M4.left
  have := mul_self_pos one_neq_0
  rw [one_mul_one] at this
  exact this

theorem inv_pos_of_pos {x : α} : 0 < x -> 0 < x⁻¹ := by
  intro xpos
  by_contra
  push Not at this
  by_cases h : x⁻¹ = 0
  · have : 0 < (1 : α) := zero_lt_one
    have x_neq_0 : x ≠ 0 := Ne.symm (Std.ne_of_lt xpos)
    rw [← M5 _ x_neq_0, h] at this
    rw [x0_eq_0] at this
    exact (lt_self_iff_false 0).mp this
  · have : x⁻¹ < 0 := by
      exact Std.lt_of_le_of_ne this h
    have := mul_lt_mul_left_of_pos xpos this
    rw [M5, x0_eq_0] at this
    · have : ¬ 1 < (0 : α) := by
        push Not
        have : 0 < (1 : α) := zero_lt_one
        exact Std.le_of_lt this
      contradiction
    exact Ne.symm (Std.ne_of_lt xpos)


theorem inv_lt_inv_of_pos {x y : α} : 0 < x -> x < y -> 0 < y⁻¹ ∧ y⁻¹ < x⁻¹ := by
  intro xpos xlty
  constructor
  · have ypos : 0 < y := xpos.trans xlty
    have : (0 : α) < 1 := zero_lt_one
    rw [← M5 y] at this
    · by_contra ct
      push Not at ct
      have : y⁻¹ ≠ 0 := by
        intro h
        rw [h, x0_eq_0] at this
        exact (lt_self_iff_false 0).mp this
      have : y⁻¹ < 0 := by
        exact Std.lt_of_le_of_ne ct this
      have := OrderedField.mul_lt_mul_left_of_neg this ypos
      rw [x0_eq_0, M2, M5] at this
      · have ct : 1 > (0 : α) := zero_lt_one
        have ct : 1 ≥ (0 : α) := by
          exact Std.le_of_lt ct
        have ct : ¬ 1 < (0 : α) := by
          exact Std.not_lt.mpr ct
        contradiction
      exact Ne.symm (Std.ne_of_lt ypos)
    exact Ne.symm (Std.ne_of_lt ypos)
  rw [
    ← M4.right y⁻¹, ← M4.right x⁻¹,
    ← M5 x,
  ]
  · nth_rw 1 [M2]
    nth_rw 3 [M2]
    rw [← M3, ← M3, M2, M3]
    have : 0 < x⁻¹ := inv_pos_of_pos xpos
    apply mul_lt_mul_left_of_pos this
    rw [M5, ← M5 y]
    · nth_rw 2 [M2]
      have ypos : 0 < y := xpos.trans xlty
      have : y⁻¹ > 0 := inv_pos_of_pos ypos
      apply mul_lt_mul_left_of_pos this
      exact xlty
    · have ypos : 0 < y := xpos.trans xlty
      exact Ne.symm (Std.ne_of_lt ypos)
    exact Ne.symm (Std.ne_of_lt xpos)
  exact Ne.symm (Std.ne_of_lt xpos)

end OrderedField
end

end Fields
