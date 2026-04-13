import RudinAnalysis.TheRealAndComplexNumberSystems.Import

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace TheRealField

open scoped BigOperators
open LinearOrder

/-
In this section,
we'll construct "real" real number,
through the Dedekind Cut.
-/

structure DedekindReal (α : Set ℚ) where
  nonempty : α.Nonempty
  not_univ : ∃ q : ℚ, q ∉ α
  downward_closed : ∀ p ∈ α, ∀ q : ℚ, q < p -> q ∈ α
  no_greatest : ∀ p ∈ α, ∃ r ∈ α, p < r

example (α : Set ℚ) (r : DedekindReal α) :
  ∀ p ∈ α, ∀ q ∉ α, p < q := by
    intro p pinα q qnotinα
    have dc := r.downward_closed p pinα
    have : p ≠ q := by
      exact ne_of_mem_of_not_mem pinα qnotinα
    by_contra h
    push Not at h
    have : q < p := by
      exact Rat.lt_of_le_of_ne h (id (Ne.symm this))
    have := dc q this
    contradiction

example (α : Set ℚ) (r : DedekindReal α) :
  ∀ r ∉ α, ∀ s : ℚ, r < s -> s ∉ α := by
    sorry

end TheRealField
