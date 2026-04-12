import RudinAnalysis.TheRealAndComplexNumberSystems.Import
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
