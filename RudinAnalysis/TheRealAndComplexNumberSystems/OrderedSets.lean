import RudinAnalysis.TheRealAndComplexNumberSystems.Import
import RudinAnalysis.TheRealAndComplexNumberSystems.Introduction

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace OrderedSets

open scoped BigOperators
open Set LinearOrder

/-
In this section, we will define and prove many property on Odered Sets,
including the bound-existing property.
We will show in later sections that ℚ doesn't have this property,
and ℝ is exactly a extend of ℚ which intend to satisfy this property.
-/

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
  use 4
  intro x xinA
  unfold A at xinA
  rcases xinA with ⟨xpos, xh⟩
  by_contra
  push Not at this
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
  constructor
  · unfold is_upper_bound
    intro x xinE
    unfold E₁ at xinE
    exact Rat.le_of_lt xinE
  · intro γ γneg
    unfold is_upper_bound
    push Not
    use γ/2
    constructor
    · unfold E₁
      grind
    · grind

example : 0 ∉ E₁ := by
  intro h
  unfold E₁ at h
  simp at h

example : is_supremum E₂ 0 := by
  constructor
  · unfold is_upper_bound
    intro x xinE
    unfold E₂ at xinE
    assumption
  · intro γ γneg
    unfold is_upper_bound
    push Not
    use γ/2
    constructor
    · unfold E₂
      grind
    · grind

example : 0 ∈ E₂ := by
  unfold E₂
  simp

-- (3) --

def E : Set ℚ := {q : ℚ | ∃ n : ℕ, 1 / (n : ℚ) = q}

#check Int.cast_natCast
example : is_infimum E 0 := by
  constructor

  · unfold is_lower_bound
    intro x xinE
    unfold E at xinE
    simp only [one_div, mem_setOf_eq] at xinE
    rcases xinE with ⟨n, neq⟩
    rw [← neq]
    apply Rat.inv_nonneg
    exact Rat.natCast_nonneg

  · intro γ γpos
    unfold is_lower_bound
    push Not
    unfold E
    simp only [one_div, mem_setOf_eq, exists_exists_eq_and]
    by_cases h : γ ≤ 1

    · set y := Nat.floor (γ⁻¹) + 1 with yeq
      use y

      have ha : (y : ℚ) > 0 := by
        refine Rat.natCast_pos.mpr ?_
        rw [yeq]
        exact Nat.zero_lt_succ ⌊γ⁻¹⌋₊

      apply (inv_lt_comm₀ ha γpos).mpr
      rw [yeq]
      push_cast
      exact Nat.lt_floor_add_one γ⁻¹

    · push Not at h
      use 1
      push_cast
      rw [inv_one]
      exact h

end

section -- 1.10
variable (α : Type*) [LinearOrder α]

def have_least_upper_bound_property : Prop :=
  ∀ E : Set α, E.Nonempty -> is_bounded_above E -> ∃ ub : α, is_supremum E ub

def have_greatest_lower_bound_property : Prop :=
  ∀ E : Set α, E.Nonempty -> is_bounded_below E -> ∃ lb : α, is_infimum E lb

theorem bound_property_iff :
  have_least_upper_bound_property α ↔ have_greatest_lower_bound_property α
   := by
    apply Iff.intro
    · intro hyp E Ene Ebh
      rcases Ene with ⟨default, default_in⟩
      rcases Ebh with ⟨lb, lbh⟩
      let e : Set α := {a : α | ∀ b ∈ E, a ≤ b}
      have e_is_noempty : e.Nonempty := by
        use lb
        exact lbh
      have e_is_bounded_above : is_bounded_above e := by
        use default
        intro x xine
        have := xine default default_in
        exact this
      have := hyp e e_is_noempty e_is_bounded_above

      rcases this with ⟨esup, esuph⟩
      rcases esuph with ⟨esup_is_ub, sup_uniq⟩

      have esup_in_e : ∀ b ∈ E, esup ≤ b := by
        intro b binE
        by_contra
        push Not at this
        have := sup_uniq b this
        unfold is_upper_bound at this
        push Not at this
        have : ¬ ∃ x ∈ e, b < x := by
          push Not
          intro x xine
          unfold e at xine
          exact xine b binE
        contradiction

      use esup
      constructor
      · unfold is_lower_bound
        exact esup_in_e
      · intro γ γgt γh
        have : γ ∈ e := by
          exact γh
        have := esup_is_ub γ this
        have : ¬ γ > esup := by
          push Not
          exact this
        contradiction

    · intro hyp E Ene Ebh
      rcases Ene with ⟨default, default_in⟩
      rcases Ebh with ⟨ub, ubh⟩
      let e : Set α := {a : α | ∀ b ∈ E, a ≥ b}
      have e_is_noempty : e.Nonempty := by
        use ub
        exact ubh
      have e_is_bounded_below : is_bounded_below e := by
        use default
        intro x xine
        have := xine default default_in
        exact this
      have := hyp e e_is_noempty e_is_bounded_below

      rcases this with ⟨einf, einfh⟩
      rcases einfh with ⟨einf_is_lb, inf_uniq⟩

      have einf_in_e : ∀ b ∈ E, einf ≥ b := by
        intro b binE
        by_contra
        push Not at this
        have := inf_uniq b this
        unfold is_lower_bound at this
        push Not at this
        have : ¬ ∃ x ∈ e, b > x := by
          push Not
          intro x xine
          unfold e at xine
          exact xine b binE
        contradiction

      use einf
      constructor
      · unfold is_upper_bound
        exact einf_in_e
      · intro γ γgt γh
        have : γ ∈ e := by
          exact γh
        have := einf_is_lb γ this
        have : ¬ γ < einf := by
          push Not
          exact this
        contradiction

class Completness where
  sup_exists : have_least_upper_bound_property α

theorem Completness.inf_exists [Completness α] : have_greatest_lower_bound_property α :=
  (bound_property_iff α).mp Completness.sup_exists

end

theorem the_1_11_l (S : Type*) [LinearOrder S] [Completness S]
  (B : Set S)
  (Bbb : is_bounded_below B)
  (Bne : B.Nonempty) :
  let L : Set S := {s : S | is_lower_bound B s};
  ∃ α : S, is_supremum L α ∧ is_infimum B α := by
    intro L
    have Lne : ∃ l : S, l ∈ L := by
      exact Bbb
    have Lbb : is_bounded_above L := by
      unfold is_bounded_above
      rcases Bne with ⟨b, bh⟩
      use b
      intro x xinL
      unfold L at xinL
      exact xinL b bh
    have L_have_sup := Completness.sup_exists L Lne Lbb
    rcases L_have_sup with ⟨α, αsup⟩
    use α
    constructor
    · exact αsup
    rcases αsup with ⟨hl, hr⟩
    unfold is_upper_bound at hr
    · constructor
      · intro b binB
        by_contra
        push Not at this
        have := hr b this
        push Not at this
        unfold L at this
        rcases this with ⟨x, xh, bltx⟩
        have := xh b binB
        have : ¬ b < x := by
          exact Std.not_lt.mpr (xh b binB)
        contradiction
      · unfold is_upper_bound at hl
        unfold L at hl
        intro γ γh h
        have := hl γ h
        have : ¬ γ > α := by
          exact Std.not_lt.mpr (hl γ h)
        contradiction

theorem the_1_11_r (S : Type*) [LinearOrder S] [Completness S]
  (B : Set S)
  (Bbb : is_bounded_above B)
  (Bne : B.Nonempty) :
  let U : Set S := {s : S | is_upper_bound B s};
  ∃ α : S, is_infimum U α ∧ is_supremum B α := by
    intro U
    have := Completness.sup_exists B Bne Bbb
    rcases this with ⟨α, αh⟩
    use α
    constructor
    · rcases αh with ⟨supl, supr⟩
      · constructor
        · intro u uinU
          by_contra
          push Not at this
          have := supr u this
          contradiction
        · intro γ γh γlbU
          have := γlbU α supl
          have : ¬ γ > α := by
            exact Std.not_lt.mpr (γlbU α supl)
          contradiction
    · exact αh

end OrderedSets
