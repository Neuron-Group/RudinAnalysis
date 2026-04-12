import RudinAnalysis.TheRealAndComplexNumberSystems.Import
import RudinAnalysis.TheRealAndComplexNumberSystems.Introduction

set_option linter.style.lambdaSyntax false

open scoped BigOperators
open Set LinearOrder

section

variable {α : Type*} [LinearOrder α]

-- 1.7

def is_upper_bound : Set α -> α -> Prop
  := λ A a ↦ ∀ x ∈ A, x ≤ a

def is_lower_bound : Set α -> α -> Prop
  := λ A a ↦ ∀ x ∈ A, a ≤ x

def is_bounded_above : Set α -> Prop
  := λ A ↦ ∃ x, is_upper_bound A x

def is_bounded_below : Set α -> Prop
  := λ A ↦ ∃ x, is_lower_bound A x

-- 1.8

def is_supremum : Set α -> α -> Prop
  := λ A a ↦ is_upper_bound A a ∧ ∀ γ < a, ¬ is_upper_bound A γ

def is_infimum : Set α -> α -> Prop
  := λ A a ↦ is_lower_bound A a ∧ ∀ γ > a, ¬ is_lower_bound A γ

end

-- 1.9
section
open Introduction

#check A

-- (1) --
example : is_bounded_above A := by
  unfold is_bounded_above
  use 4
  unfold is_upper_bound
  intro x xinA
  unfold A at xinA
  simp at xinA
  rcases xinA with ⟨xpos, xh⟩
  by_contra
  push_neg at this
  have xh' : x ^ 2 > 2 := by
    calc
      x ^ 2 > 4 * 4 := by
        rw [pow_two]
        exact mul_lt_mul_of_pos' this this rfl xpos
      _ > _ := by norm_num
  have xh' : x ^ 2 ≥ 2 := by
    exact Rat.le_of_lt xh'
  have xh' : ¬ x ^ 2 < 2 := by
    exact Rat.not_lt.mpr xh'
  contradiction

-- (2) --
def E₁ : Set ℚ := {r : ℚ | r < 0}
def E₂ : Set ℚ := {r : ℚ | r ≤ 0}

example : is_supremum E₁ 0 := by
  unfold is_supremum
  constructor
  · unfold is_upper_bound
    intro x xinE
    unfold E₁ at xinE
    simp at xinE
    exact Rat.le_of_lt xinE
  · intro γ γneg
    unfold is_upper_bound
    push Not
    use γ/2
    constructor
    · unfold E₁
      simp
      grind
    · grind

example : is_supremum E₂ 0 := by
  unfold is_supremum
  constructor
  · unfold is_upper_bound
    intro x xinE
    unfold E₂ at xinE
    simp at xinE
    assumption
  · intro γ γneg
    unfold is_upper_bound
    push Not
    use γ/2
    constructor
    · unfold E₂
      simp
      grind
    · grind

end
