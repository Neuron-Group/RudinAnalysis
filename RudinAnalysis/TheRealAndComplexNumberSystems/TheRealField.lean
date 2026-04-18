import RudinAnalysis.TheRealAndComplexNumberSystems.Import
import RudinAnalysis.TheRealAndComplexNumberSystems.OrderedSets
import RudinAnalysis.TheRealAndComplexNumberSystems.Fields

import Mathlib.Tactic.Linarith
import Mathlib.Tactic.SplitIfs

open Lean Parser Tactic in
syntax (name := simp_ifs) "simp_ifs" : tactic

macro_rules
| `(tactic| simp_ifs) => `(tactic|
    try split_ifs; all_goals try linarith; all_goals try simp only [*, if_true, if_false]
  )

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

-- step 1 --
@[ext]
structure DedekindCut (α : Set ℚ) where
  nonempty : α.Nonempty
  not_univ : ∃ q : ℚ, q ∉ α
  downward_closed : ∀ p ∈ α, ∀ q : ℚ, q < p -> q ∈ α
  no_greatest : ∀ p ∈ α, ∃ r ∈ α, p < r

namespace DedekindCut
open OrderedSets

theorem lt_of_mem_of_not_mem {α : Set ℚ} (r : DedekindCut α) :
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

theorem upward_closed_compl {α : Set ℚ} (r : DedekindCut α) :
  ∀ r ∉ α, ∀ s : ℚ, r < s -> s ∉ α := by
  intro p ph q qh qina
  have := r.downward_closed q qina p qh
  contradiction

theorem is_bounded_above {α : Set ℚ} (r : DedekindCut α) :
  is_bounded_above α := by
    obtain ⟨q, qninα⟩ := r.not_univ
    use q
    intro a xinα
    have := lt_of_mem_of_not_mem r a xinα q qninα
    exact Rat.le_of_lt this

theorem ssubset_of_exists_mem_not_mem {α β : Set ℚ}
  (ra : DedekindCut α) (rb : DedekindCut β)
  : (∃ x, x ∈ α ∧ x ∉ β) -> β ⊂ α := by
    intro h
    obtain ⟨s, sinα, sninβ⟩ := h
    refine Set.ssubset_iff_subset_ne.mpr ?_
    constructor
    · intro b binβ
      by_contra bninα
      have h1 := rb.lt_of_mem_of_not_mem b binβ s sninβ
      have h2 := ra.lt_of_mem_of_not_mem s sinα b bninα
      have : s ≤ b := by
        exact Rat.le_of_lt h2
      have : ¬ b < s := by
        exact Rat.not_lt.mpr this
      contradiction
    · exact Ne.symm (ne_of_mem_of_not_mem' sinα sninβ)

theorem exists_mem_add_not_mem {α : Set ℚ} (rα : DedekindCut α) :
  ∀ r > 0, ∃ p ∈ α, p + r ∉ α := by
  intro r rpos
  by_contra h
  push Not at h

  obtain ⟨p₀, hp₀⟩ := rα.nonempty
  obtain ⟨q, hq⟩ := rα.is_bounded_above  -- hq : ∀ x ∈ α, x ≤ q

  have h_all : ∀ n : ℕ, p₀ + (n : ℚ) * r ∈ α := by
    intro n
    induction n with
    | zero => simpa using hp₀
    | succ n ih =>
        have step := h (p₀ + n * r) ih
        push_cast
        rw [add_mul, one_mul, ← add_assoc]
        exact step

  have archi : ∃ n : ℕ, (q - p₀) / r < n :=
    exists_nat_gt ((q - p₀) / r)

  obtain ⟨n, hn⟩ := archi
  have h_ineq : p₀ + n * r > q := by
    have rpos : 0 < r := rpos
    rw [← sub_pos] at rpos
    simp only [sub_zero] at rpos
    have : q - p₀ < ↑n * r := by
      calc
        q - p₀ = ((q - p₀) / r) * r := by field_simp [rpos.ne']
        _ < n * r := mul_lt_mul_of_pos_right hn rpos
    rw [← sub_pos] at this
    linarith
  exact not_le_of_gt h_ineq (hq (p₀ + n * r) (h_all n))

theorem exists_ratio_le_of_positive_and_eps_gt_one {α : Set ℚ} (rα : DedekindCut α) :
    (∃ x ∈ α, 0 < x) → ∀ ε > 1, ∃ r ∈ α, ∃ s ∉ α, 0 < r ∧ s / r ≤ ε := by
  intro hpos ε hε
  by_contra h
  push Not at h

  rcases hpos with ⟨a₀, ha₀, ha₀_pos⟩
  obtain ⟨q, hq⟩ := rα.is_bounded_above

  set δ := ε - 1 with del_df
  have del_pos : 0 < δ := by linarith

  have h : ∀ r ∈ α, 0 < r -> r + δ * r ∈ α := by
    rw [del_df]
    intro r rinα rpos
    specialize h r rinα
    ring_nf
    by_contra
    specialize h (r * ε) this
    ring_nf at h
    rw [
      mul_assoc,
      mul_comm ε,
      ← mul_assoc,
      Rat.mul_inv_cancel r,
      one_mul,
    ] at h
    · exact (lt_self_iff_false ε).mp (h rpos)
    · by_contra h
      rw [h] at this
      ring_nf at this
      have := rα.upward_closed_compl 0 this a₀ ha₀_pos
      contradiction

  have a'inα : ∀ n : ℕ, a₀ + ↑n * δ * a₀ ∈ α := by
    intro n
    induction n with
    | zero =>
      simp only [Nat.cast_zero, zero_mul, add_zero]
      assumption
    | succ n hn =>
      have : 0 < a₀ + ↑n * δ * a₀ := by
        have : 0 ≤ n := Nat.zero_le n
        have : (0 : ℚ) ≤ ↑n := Rat.natCast_nonneg
        have : 0 ≤ ↑n * δ := (mul_nonneg_iff_of_pos_right del_pos).mpr this
        have : 0 ≤ ↑n * δ * a₀ := (mul_nonneg_iff_of_pos_right ha₀_pos).mpr this
        exact Right.add_pos_of_pos_of_nonneg ha₀_pos this
      specialize h (a₀ + ↑n * δ * a₀) hn this
      ring_nf at h
      push_cast
      ring_nf
      have : a₀ * ↑n * δ ^ 2 ≥ 0 := by
        have nnonneg : 0 ≤ n := Nat.zero_le n
        have nnonneg : (0 : ℚ) ≤ ↑n := Rat.natCast_nonneg
        have δsqnonneg : 0 ≤ δ ^ 2 := sq_nonneg δ
        have : a₀ * ↑n ≥ 0 := by
          exact (mul_nonneg_iff_of_pos_left ha₀_pos).mpr nnonneg
        exact Rat.mul_nonneg this δsqnonneg

      have : a₀ + a₀ * ↑n * δ + a₀ * δ ≤ a₀ + a₀ * ↑n * δ + a₀ * ↑n * δ ^ 2 + a₀ * δ := by
        simp only [add_le_add_iff_right, le_add_iff_nonneg_right]; exact this

      by_cases eq : a₀ + a₀ * ↑n * δ + a₀ * δ = a₀ + a₀ * ↑n * δ + a₀ * ↑n * δ ^ 2 + a₀ * δ
      · rw [eq]
        exact h
      · set p := a₀ + a₀ * ↑n * δ + a₀ * ↑n * δ ^ 2 + a₀ * δ with pdf
        set q := a₀ + a₀ * ↑n * δ + a₀ * δ with qdf
        have lt : q < p := Rat.lt_of_le_of_ne this eq
        exact rα.downward_closed p h q lt

  obtain ⟨n, nh⟩ : ∃ n : ℕ, (q - a₀) / (δ * a₀) < ↑n :=
    exists_nat_gt ((q - a₀) / (δ * a₀))

  specialize a'inα n
  set a' := a₀ + ↑n * δ * a₀ with a'df

  have nh : a' > q := by
    rw [a'df]
    have : (q - a₀) < ↑n * (δ * a₀) := by
      refine (Rat.div_lt_iff ?_).mp nh
      exact (Rat.mul_pos_iff_of_pos_left del_pos).mpr ha₀_pos
    ring_nf at this
    linarith

  have nh : ¬ a' ≤ q := by
    exact Rat.not_le.mpr nh

  unfold is_upper_bound at hq
  specialize hq a' a'inα

  contradiction

theorem exists_ratio_lt_of_positive_and_eps_gt_one {α : Set ℚ} (rα : DedekindCut α) :
    (∃ x ∈ α, 0 < x) → ∀ ε > 1, ∃ r ∈ α, ∃ s ∉ α, 0 < r ∧ s / r < ε := by
      intro hyp ε εlt1
      set ε' := ε - (ε - 1) / 2 with df
      have ε'lt1 : 1 < ε' := by
        rw [df]
        ring_nf
        linarith
      have ⟨r, rinα, s, sninα, le⟩ := rα.exists_ratio_le_of_positive_and_eps_gt_one hyp ε' ε'lt1
      have ε'ltε : ε' < ε := by
        rw [df]
        simp only [sub_lt_self_iff, Nat.ofNat_pos, div_pos_iff_of_pos_right, sub_pos]
        assumption
      use r; use rinα; use s; use sninα
      exact ⟨le.left, Std.lt_of_le_of_lt le.right ε'ltε⟩

end DedekindCut

def DedekindReal := {α : Set ℚ // DedekindCut α}
#check DedekindReal

-- step 2 --
instance : LT DedekindReal where
  lt := λ α β ↦ α.val ⊂ β.val

instance : LE DedekindReal where
  le := λ α β ↦ α.val ⊆ β.val

open Classical in
noncomputable instance : LinearOrder DedekindReal where
  le_refl       := by
    intro α
    dsimp [LE.le]
    exact LE.le.subset fun ⦃a⦄ a_1 ↦ a_1

  le_trans      := by
    intro α β γ αleβ βleγ
    dsimp [LE.le] at αleβ βleγ
    exact ge_iff_le.mp fun ⦃a⦄ a_1 ↦ βleγ (αleβ a_1)

  le_antisymm   := by
    intro α β αleβ βleα
    dsimp [LE.le] at αleβ βleα
    apply Subtype.ext
    exact Set.Subset.antisymm αleβ βleα

  le_total      := by
    intro α β
    dsimp [LE.le]
    obtain ⟨A, Ah⟩ := α
    obtain ⟨B, Bh⟩ := β
    by_cases h : A ⊆ B
    · left
      exact h
    · right
      rw [Set.not_subset] at h
      rcases h with ⟨a, ainA, aninB⟩
      intro b binB
      by_contra bninA
      have := DedekindCut.lt_of_mem_of_not_mem Ah a ainA b bninA
      have := DedekindCut.upward_closed_compl Bh a aninB b this
      contradiction

  toDecidableLE := λ α β ↦
    propDecidable (α ≤ β)

section
variable (α β : DedekindReal)
#check (α = β : Prop)
end

-- step 3 --
section
open OrderedSets
open Set

#check iUnion

instance : Completness DedekindReal where
  sup_exists := by
    rintro A Ane ⟨β, βuA⟩
    let index : DedekindReal -> Set ℚ :=
      λ α ↦ α.val
    let y := ⋃ r ∈ A, index r

    -- y is not an empty set
    have yne : y.Nonempty := by
      obtain ⟨α', αinA⟩ := Ane
      set α := index α' with αdef
      have : α.Nonempty := by
        rw [αdef]
        exact α'.property.nonempty
      obtain ⟨a, ainα⟩ := this
      use a
      unfold y
      rw [Set.mem_iUnion]
      use α'
      rw [← αdef]
      simp only [mem_iUnion, exists_prop]
      exact ⟨αinA, ainα⟩

    -- y is not a univ set
    -- ∀ α ∈ A, α ⊆ β
    -- y := ⋃ α ∈ A, α
    -----------------------
    -- y ⊆ β
    have ynu : ∃ q : ℚ, q ∉ y := by
      have : ∀ α ∈ A, α.val ⊆ β.val := by
        unfold is_upper_bound at βuA
        intro α αh
        have := βuA α αh
        dsimp [LE.le] at this
        exact this
      have : y ⊆ β.val := by
        exact iUnion₂_subset_iff.mpr βuA
      obtain ⟨β, βh⟩ := β
      obtain ⟨q, β_not_univ⟩:= βh.not_univ
      use q
      exact (mem_compl_iff y q).mp fun a ↦ β_not_univ (this a)

    -- ∀ p ∈ y, ∃ α ∈ A, p ∈ α  (Union's property)
    -- ∀ q < p, q ∈ α           (downward_closed of α)
    -- ∀ α ∈ A, α ⊆ y           (Union's definition)
    -- q ∈ α                    (Union's trans property)
    have downward_closed: ∀ p ∈ y, ∀ q < p, q ∈ y := by
      intro p piny q qltp
      have : ∃ α ∈ A, p ∈ index α := by
        unfold y at piny
        obtain ⟨α, αh⟩ := mem_iUnion.mp piny
        simp only [mem_iUnion, exists_prop] at αh
        exact ⟨α, αh⟩
      rcases this with ⟨⟨α, αh⟩, αinA, pinα⟩
      have := αh.downward_closed p pinα q qltp
      simp only [mem_iUnion, exists_prop, y, index]
      use ⟨α, αh⟩

    -- ∀ p ∈ y, ∃ α ∈ A, p ∈ α  (Union's property)
    -- ∃ r ∈ α, p < r           (no_greatest statment)
    -- ∀ α ∈ A, α ⊆ y           (Union's definition)
    -- r ∈ y                    (trans)
    have no_greatest : ∀ p ∈ y, ∃ r ∈ y, p < r := by
      intro p piny

      obtain ⟨α, αinA, pinα⟩: ∃ α ∈ A, p ∈ α.val := by
        simp only [mem_iUnion, exists_prop, y] at piny
        obtain ⟨α, αh⟩ := piny
        simp [index] at αh
        use α

      obtain ⟨r, rinα, pltr⟩ : ∃ r ∈ α.val, p < r := by
        obtain ⟨r, rinα, pltr⟩
          := α.property.no_greatest p pinα
        use r

      simp only [mem_iUnion, exists_prop, y, index]
      use r
      constructor
      · use α
      · assumption

    set γ : DedekindReal := (by
      use y
      exact ⟨
        yne,
        ynu,
        downward_closed,
        no_greatest
      ⟩
    ) with γdef

    use γ
    constructor

    -- It is clear that every α in A
    --    are a subset of y...
    · intro α αinA
      rw [γdef]
      exact subset_biUnion_of_mem αinA

    -- ∀ δ < γ
    -- δ ⊂ γ                    (defination of LT)
    -- ∃ s ∈ γ, s ∉ δ           (defination of property subset)
    -- ∃ α ∈ A, s ∈ α           (Union's property)
    -- ∃ s ∉ δ ∧ s ∈ α => δ ⊂ α (defination of property subset)
    -- δ < α, α ∈ A
    · intro δ δltγ
      unfold is_upper_bound
      push Not
      obtain ⟨s, siny, sninδ⟩ : ∃ s ∈ γ.val, s ∉ δ.val
        := exists_of_ssubset δltγ
      simp only [mem_iUnion, exists_prop, y, γ] at siny
      obtain ⟨α, αinA, sinα⟩ := siny
      have
        := DedekindCut.ssubset_of_exists_mem_not_mem
          α.property δ.property ⟨s, ⟨sinα, sninδ⟩⟩
      have δltα : δ < α := by
        exact this
      use α

end

section -- step 4 --
open Set

instance : Zero DedekindReal where
  zero := ⟨
    {q : ℚ | q < 0},
    ⟨
      ⟨(-1 : ℚ),      mem_setOf.mpr rfl ⟩,
      ⟨( 1 : ℚ), of_decide_eq_false rfl ⟩,
      λ p ph q qltp ↦ Std.lt_trans qltp ph,
      λ p ph ↦ ⟨p / 2, ⟨
        (by
          simp only [mem_setOf_eq] at ph ⊢
          exact div_neg_of_neg_of_pos ph rfl
        ),
        (by
          simp at ph
          linarith
        )
      ⟩⟩,
    ⟩
  ⟩

section

#check (0 : DedekindReal)

end

-- (A1) --
instance : Add DedekindReal where
  add := by
    rintro ⟨A, Ah⟩ ⟨B, Bh⟩
    let C : Set ℚ := {c : ℚ | ∃ a ∈ A, ∃ b ∈ B, c = a + b}
    use C
    exact ⟨
      (by
        obtain ⟨a, ah⟩ := Ah.nonempty
        obtain ⟨b, bh⟩ := Bh.nonempty
        use a + b
        unfold C
        use a; use ah; use b;
      ),
      (by
        obtain ⟨a', ah'⟩ := Ah.not_univ
        obtain ⟨b', bh'⟩ := Bh.not_univ
        have : ∀ a ∈ A, ∀ b ∈ B, a + b < a' + b' := by
          intro a ainA b binB
          have alta' : a < a'
            := Ah.lt_of_mem_of_not_mem a ainA a' ah'
          have bltb' : b < b'
            := Bh.lt_of_mem_of_not_mem b binB b' bh'
          exact add_lt_add alta' bltb'
        use a' + b'
        simp only [mem_setOf_eq, not_exists, not_and, C]
        intro a ainA b binB
        have := this a ainA b binB
        exact Rat.ne_of_gt this
      ),
      (by
        intro p pinC

        obtain ⟨r, rinA, s, sinB, p_eq_r_plus_s⟩ := pinC

        intro q qltp
        have : q - s < r := by linarith
        have q_sub_s_in_A := Ah.downward_closed r rinA (q - s) this

        use q - s
        use q_sub_s_in_A
        use s
        use sinB
        ring
      ),
      (by
        intro p pinC
        obtain ⟨r, rh, s, sh, h⟩ := pinC
        obtain ⟨r', r'h, rltr'⟩ := Ah.no_greatest r rh
        have : p < r' + s := by linarith
        use r' + s
        constructor
        · use r'
          use r'h
          use s
        · exact this
      )
    ⟩

instance : HAdd DedekindReal DedekindReal DedekindReal where
  hAdd := λ α β ↦ Add.add α β

-- (A2) --
theorem dedekindreal_add_comm :
  (α β : DedekindReal) -> α + β = β + α := by
    rintro ⟨α, αh⟩ ⟨β, βh⟩
    dsimp [HAdd.hAdd, Add.add]
    apply Subtype.ext
    ext x
    simp only [Set.mem_setOf_eq]
    constructor
    <;> rintro ⟨a, ha, b, hb, rfl⟩
    <;> exact ⟨b, hb, a, ha, add_comm a b⟩

-- (A3) --
theorem dedekindreal_add_assoc :
  (α β γ : DedekindReal) -> α + β + γ = α + (β + γ) := by
    rintro ⟨α, αh⟩ ⟨β, βh⟩ ⟨γ, γh⟩
    dsimp [HAdd.hAdd, Add.add]
    apply Subtype.ext
    ext q
    simp only [Set.mem_setOf_eq]
    constructor
    · rintro ⟨ab, ⟨a, ha, b, hb, rfl⟩, c, hc, rfl⟩
      use a, ha, b + c, ⟨b, hb, c, hc, rfl⟩
      have : a + b + c = a + (b + c) := by ring
      exact this
    · rintro ⟨a, ha, bc, ⟨b, hb, c, hc, rfl⟩, rfl⟩
      use a + b, ⟨a, ha, b, hb, rfl⟩, c, hc
      have : a + (b + c) = a + b + c := by ring
      exact this

-- (A4) --
theorem dedekindreal_zero_add :
  (x : DedekindReal) -> 0 + x = x := by
    change ∀ (x : DedekindReal), Zero.zero + x = x
    rintro ⟨α, αh⟩
    apply Subtype.ext
    ext a
    constructor
    · intro h
      simp only [HAdd.hAdd, Add.add, Zero.zero, Set.mem_setOf_eq] at h
      obtain ⟨a', a'neg, b, binα, aeq⟩ := h
      have aeq : a = a' + b := aeq
      have : a < b := by linarith
      exact αh.downward_closed b binα a this
    · intro ainα
      have ⟨a', a'inα, alta'⟩ := αh.no_greatest a ainα
      use a - a'
      use sub_neg.mpr alta'
      use a'
      use a'inα
      have : a = (a - a') + a' := by ring
      exact this

theorem dedekindreal_add_zero :
  (x : DedekindReal) -> x + 0 = x := by
    intro x
    rw [dedekindreal_add_comm]
    rw [dedekindreal_zero_add]

section
variable (α β : DedekindReal)

#check α + β

end

-- (A5) --
instance : Neg DedekindReal where
  neg := λ α ↦ ⟨
    {p : ℚ | ∃ r > 0, -p - r ∉ α.val},
    ⟨
      (by
        obtain ⟨α, αh⟩ :=  α
        obtain ⟨p, pinα⟩ := αh.not_univ
        use -p - 1
        use 1
        constructor
        · norm_num
        · simp only [neg_sub, sub_neg_eq_add, add_sub_cancel_left]
          exact pinα
      ),
      (by
        obtain ⟨α, αh⟩ := α
        simp only [gt_iff_lt, mem_setOf_eq, not_exists, not_and, not_not]
        obtain ⟨q, qh⟩ := αh.nonempty
        use -q
        intro x xpos
        have : - -q - x < q := by linarith
        exact αh.downward_closed q qh (- -q - x) this
      ),
      (by
        obtain ⟨α, αh⟩ := α
        simp only [gt_iff_lt, mem_setOf_eq, forall_exists_index, and_imp]
        intro p r rpos negprninα q qltp
        have : -q - r > -p - r := by linarith
        have : -q - r ∉ α
          := αh.upward_closed_compl
            (-p - r) negprninα (-q - r) this
        use r
      ),
      (by
        obtain ⟨α, αh⟩ := α
        simp only [gt_iff_lt, mem_setOf_eq, forall_exists_index, and_imp]
        intro p r rpos negprninα
        set t := p + (r / 2) with tdef
        use t
        constructor
        · use r / 2
          constructor
          · linarith
          · rw [tdef]
            have : -(p + r / 2) - r / 2 = -p - r := by
              linarith
            rw [this]
            exact negprninα
        · linarith
      ),
    ⟩
  ⟩

theorem dedekindreal_add_neg_cancel :
  (x : DedekindReal) -> x + -x = 0 := by
    change ∀ (x : DedekindReal), x + -x = Zero.zero
    rintro ⟨α, αh⟩
    apply Subtype.ext
    simp only [HAdd.hAdd, Add.add, Neg.neg, gt_iff_lt, Set.mem_setOf_eq, Zero.zero]
    ext q
    simp only [Set.mem_setOf_eq]
    constructor
    · rintro ⟨r, rinα, s, ⟨s', s'pos, neg_s_neg_s'_nin_α⟩, eq⟩
      have eq : q = r + s := eq
      have neg_s_neg_s'_nin_α : -s - s' ∉ α := neg_s_neg_s'_nin_α
      have : -s - s' < -s := by linarith
      have := αh.upward_closed_compl
        (-s - s') neg_s_neg_s'_nin_α (-s) this
      have := αh.lt_of_mem_of_not_mem r rinα (-s) this
      have : r + s < 0 := by linarith
      rw [← eq] at this
      exact this
    · rename ℚ => v
      intro vneg
      set w := - v / (2 : ℚ) with wdf
      obtain ⟨n, nwinα, nsuccwninα⟩ : ∃ n, n * w ∈ α ∧ (n + 1) * w ∉ α := by
        have wpos : 0 < w := by linarith
        obtain ⟨a, ainα, aaddninα⟩ := αh.exists_mem_add_not_mem w wpos
        use a / w
        constructor
        · grind
        · grind
      set p := -(n + 2) * w with pdf
      use n * w
      use nwinα
      use p
      constructor
      · use w
        constructor
        · linarith
        · have : -p - w ∉ α := by
            rw [pdf]
            ring_nf
            have : n * w + w = (n + 1) * w := by linarith
            rw [this]
            exact nsuccwninα
          exact this
      · have : v = n * w + p := by
          simp [wdf, pdf]
          ring
        exact this

section
variable (α : DedekindReal)

#check -α

end

--  α : Set ℚ
-- -α : Set ℚ := {q : ℚ | ∃ r > 0, -q - r ∉ α }
--  0 : Set ℚ := {q : ℚ | q < 0               }

end

section -- step 5 --
open Set

theorem dedekindreal_neg_neg :
  (x : DedekindReal) -> -(-x) = x := by
    intro x
    rw [
      ← dedekindreal_zero_add (- -x),
      ← dedekindreal_add_neg_cancel x,
      dedekindreal_add_assoc,
      dedekindreal_add_neg_cancel,
      dedekindreal_add_zero
    ]

theorem add_lt_add_left :
  (α β γ : DedekindReal) -> β < γ -> α + β < α + γ := by
    intro ⟨α, αh⟩ ⟨β, βh⟩ ⟨γ, γh⟩ lt
    simp only [LT.lt, HAdd.hAdd, Add.add] at lt ⊢
    refine Set.ssubset_iff_subset_ne.mpr ?_
    constructor
    · intro c
      simp only [mem_setOf_eq, forall_exists_index, and_imp]
      intro a ainα b binβ ceq
      exact ⟨a, ainα, b, lt.left binβ, ceq⟩
    · obtain ⟨y, yinγ , yninβ⟩ := exists_of_ssubset lt
        -- Hint:
        -- We need to cook up some c
        --  that belongs to α + γ but stays out of α + β.
        -- We already have a y ∈ γ
        --  that's not in β
        --    (that's our witness for β < γ).
        -- Since γ has no largest element,
        --  we can bump y up a bit to some y' ∈ γ with y < y'.
        -- Let's call the gap ε = y' - y (so ε > 0).
        -- Now here's a useful fact about Dedekind reals:
        --  for any ε > 0, we can always find an a' ∈ α
        --    such that a' + ε ∉ α.
        -- Intuitively, a' is "within ε" of the top.
        -- Now take c = a' + y'.
        -- Obviously c ∈ α + γ because a' ∈ α and y' ∈ γ.
        -- The real question: why isn't c in α + β?
        -- Take any a ∈ α and b ∈ β. We know two things:
        --   • a < a' + ε (because a' + ε is outside α but a is inside)
        --   • b < y (since y ∉ β and b ∈ β)
        -- So let's add them up:
        --   a + b < (a' + ε) + b = a' + (ε + b) = a' + ((y' - y) + b)
        -- But b < y, so (y' - y) + b < (y' - y) + y = y'.
        -- Therefore a + b < a' + y' = c.
        -- Since a + b is strictly less than c
        --  for every possible a ∈ α and b ∈ β,
        -- c can't be expressed as a + b with a ∈ α, b ∈ β.
        -- So c ∉ α + β. Done!
      obtain ⟨c, c_in_αγ, c_nin_αβ⟩ : ∃ c ∈ {c | ∃ a ∈ α, ∃ b ∈ γ, c = a.add b},
        c ∉ {c | ∃ a ∈ α, ∃ b ∈ β, c = a.add b} := by
          simp only [mem_setOf_eq, not_exists, not_and, ↓existsAndEq, and_true]
          obtain ⟨y', y'inγ, ylty'⟩ := γh.no_greatest y yinγ
          set ε := y' - y with εdf
          have εpos : 0 < ε := by linarith
          obtain ⟨a', a'inα, a'h⟩ := αh.exists_mem_add_not_mem ε εpos
          use a'
          use y'
          use ⟨a'inα, y'inγ⟩
          intro a ainα b binβ
          have : a + b < a' + y' :=
            calc
              a + b < ε + a' + b := by
                refine Rat.add_lt_add_right.mpr ?_
                rw [add_comm]
                exact αh.lt_of_mem_of_not_mem a ainα (a' + ε) a'h
              _ < _ := by
                rw [add_comm ε, add_assoc]
                refine Rat.add_lt_add_left.mpr ?_
                rw [εdf]
                have : b < y := by
                  exact βh.lt_of_mem_of_not_mem b binβ y yninβ
                linarith
          exact Rat.ne_of_gt this
      exact Ne.symm (ne_of_mem_of_not_mem' c_in_αγ c_nin_αβ)

theorem neg_lt_zero_of_pos {α : DedekindReal} :
  (0 < α) -> (-α < 0) := by
    intro αpos
    have := add_lt_add_left (-α) 0 α αpos
    rw [
      dedekindreal_add_zero,
      dedekindreal_add_comm,
      dedekindreal_add_neg_cancel
    ] at this
    exact this

theorem zero_lt_neg_of_neg {α : DedekindReal} :
  (α < 0) -> (0 < -α) := by
    intro αneg
    have := add_lt_add_left (-α) α 0 αneg
    rw [
      dedekindreal_add_zero,
      dedekindreal_add_comm,
      dedekindreal_add_neg_cancel,
    ] at this
    exact this

@[simp]
theorem zero20 : (Zero.zero : DedekindReal) = 0 := by
  rfl

@[simp]
theorem neg_zero : (-0 : DedekindReal) = 0 := by
  rw [
    ← dedekindreal_zero_add (-0),
    dedekindreal_add_neg_cancel,
  ]

end

section -- step 6 --
open Set

/-
We shall give the definition for Real Multiplication now.
As the multiplication of negative real is not as simple as addition,
We shall confine our condition to the positive real number first.
-/

def multiplication_of_positive_two_real_numbers' :
  (α β : DedekindReal) -> (Zero.zero < α) -> (Zero.zero < β) -> DedekindReal :=
    λ α β αpos βpos ↦ ⟨
      {p | ∃ r ∈ α.val, ∃ s ∈ β.val, r > 0 ∧ s > 0 ∧ p ≤ r * s},
      ⟨
        (by
          obtain ⟨α, αh⟩ := α
          obtain ⟨β, βh⟩ := β
          unfold Set.Nonempty
          obtain ⟨r, rinα, rnin0⟩ := exists_of_ssubset αpos
          obtain ⟨s, sinβ, snin0⟩ := exists_of_ssubset βpos
          simp only [Zero.zero, mem_setOf_eq, not_lt] at rnin0 snin0
          obtain ⟨r', r'inα, r'pos⟩ := αh.no_greatest r rinα
          obtain ⟨s', s'inβ, s'pos⟩ := βh.no_greatest s sinβ
          use r' * s'
          use r'
          use r'inα
          use s'
          use s'inβ
          exact ⟨
            calc
              0 ≤ r := rnin0
              _ < _ := r'pos,
            calc
              0 ≤ s := snin0
              _ < _ := s'pos,
            Rat.le_refl
          ⟩
        ),
        (by
          obtain ⟨α, αh⟩ := α
          obtain ⟨β, βh⟩ := β
          simp only [
            Zero.zero,
            LT.lt,
            gt_iff_lt,
            mem_setOf_eq,
            not_exists,
            not_and,
            not_le
          ] at αpos βpos ⊢
          obtain ⟨r', r'ninα⟩ := αh.not_univ
          obtain ⟨s', s'ninβ⟩ := βh.not_univ
          use r' * s'
          intro r rinα s sinβ rpos spos
          have rltr' : r < r'
            := αh.lt_of_mem_of_not_mem r rinα r' r'ninα
          have slts' : s < s'
            := βh.lt_of_mem_of_not_mem s sinβ s' s'ninβ
          have : r * s < r' * s' := by
            refine mul_lt_mul_of_pos_of_nonneg' rltr' ?_ spos ?_
            · exact Rat.le_of_lt slts'
            · calc
                _ ≤ r := Rat.le_of_lt rpos
                _ ≤ _ := Rat.le_of_lt rltr'
          exact this
        ),
        (by
          obtain ⟨α, αh⟩ := α
          obtain ⟨β, βh⟩ := β
          intro p pinα q qltp
          obtain ⟨r, rinα, s, sinβ, rpos, spos, ple⟩
            := pinα
          use r
          use rinα
          use s
          use sinβ
          use rpos
          use spos
          calc
            q ≤ p := Rat.le_of_lt qltp
            p ≤ r * s := ple
        ),
        (by
          obtain ⟨α, αh⟩ := α
          obtain ⟨β, βh⟩ := β
          intro p pinα
          obtain ⟨r, rinα, s, sinβ, rpos, spos, ple⟩ := pinα
          obtain ⟨r', r'inα, rltr'⟩ := αh.no_greatest r rinα
          use r' * s
          constructor
          · use r'
            use r'inα
            use s
            use sinβ
            constructor
            · calc
                _ < r := rpos
                _ < _ := rltr'
            constructor
            · exact spos
            · exact Rat.le_refl
          calc
            _ ≤  r * s  := ple
            _ < r' * s  := (Rat.mul_lt_mul_right spos).mpr rltr'
        ),
      ⟩
    ⟩

lemma multiplication_of_positive_two_real_numbers_is_communicative'
  (α β : DedekindReal) (αpos : Zero.zero < α) (βpos : Zero.zero < β) :
    multiplication_of_positive_two_real_numbers' α β αpos βpos
     = multiplication_of_positive_two_real_numbers' β α βpos αpos := by
      obtain ⟨α, αh⟩ := α
      obtain ⟨β, βh⟩ := β
      simp only [
        LT.lt,
        Zero.zero,
        multiplication_of_positive_two_real_numbers',
        gt_iff_lt
      ] at αpos βpos ⊢
      apply Subtype.ext
      ext p
      constructor
      <;> rintro ⟨r, rinα, s, sinβ, rpos, spos, ple⟩
      <;> exact ⟨s, sinβ, r, rinα, spos, rpos, (by linarith)⟩

/-
Before the prove of positive multiplication associative,
we shall first prove the multiplication of two positive real
is still a positive real.
-/
theorem pos_of_pos_mul_pos {α β : DedekindReal}
  (αpos : Zero.zero < α) (βpos : Zero.zero < β) :
    Zero.zero < multiplication_of_positive_two_real_numbers' α β αpos βpos := by
      obtain ⟨α, αh⟩ := α
      obtain ⟨β, βh⟩ := β
      simp only [
        LT.lt,
        multiplication_of_positive_two_real_numbers',
        Zero.zero,
      ] at αpos βpos ⊢

      obtain ⟨a, ainα, anin0⟩ := exists_of_ssubset αpos
      obtain ⟨b, binβ, bnin0⟩ := exists_of_ssubset βpos

      /-
      Which was replied by LEAN4 automatically
      I can hardly give a comment.
      -/
      simp only [Rat.blt, Rat.num_neg, Rat.num_ofNat, Std.le_refl, decide_true, Bool.and_true,
        decide_eq_true_eq, Rat.num_eq_zero, lt_self_iff_false, decide_false, Rat.num_pos,
        Rat.den_ofNat, Nat.cast_one, mul_one, zero_mul, Bool.if_false_left, Bool.if_true_left,
        Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
        decide_eq_false_iff_not, not_lt, mem_setOf_eq, not_or, not_and] at anin0 bnin0

      have anin0 : 0 ≤ a := by grind
      have bnin0 : 0 ≤ b := by grind
      obtain ⟨a', a'inα, alta'⟩ := αh.no_greatest a ainα
      obtain ⟨b', b'inβ, bltb'⟩ := βh.no_greatest b binβ
      have a'pos : 0 < a' := by linarith [anin0, alta']
      have b'pos : 0 < b' := by linarith [bnin0, bltb']
      have : 0 < a' * b' := (Rat.mul_pos_iff_of_pos_left a'pos).mpr b'pos

      refine Set.ssubset_iff_subset_ne.mpr ?_
      constructor
      · intro q qneg
        have qneg : q < 0 := qneg
        use a'
        use a'inα
        use b'
        use b'inβ
        use a'pos
        use b'pos
        linarith [qneg, this]
      · set q := a' * b' with qdf
        have h1 : q ∉ {q | q.blt 0 = true} := by
          simp only [mem_setOf_eq, Bool.not_eq_true]
          rw [qdf]
          have : a' * b' ≥ 0 := Rat.le_of_lt this
          exact this
        have h2 : q ∈ {p | ∃ r ∈ α, ∃ s ∈ β, r > 0 ∧ s > 0 ∧ p ≤ r * s} := by
          use a'
          use a'inα
          use b'
        exact Ne.symm (ne_of_mem_of_not_mem' h2 h1)

lemma multiplication_of_positive_two_real_never_be_neg'
  {α β : DedekindReal} (αpos : Zero.zero < α) (βpos : Zero.zero < β) :
    multiplication_of_positive_two_real_numbers' α β αpos βpos < Zero.zero -> False := by
      intro h
      have := pos_of_pos_mul_pos αpos βpos
      grind

lemma multiplication_of_positive_three_real_numbers_is_associative'
  {α β γ : DedekindReal}
  (αpos : Zero.zero < α) (βpos : Zero.zero < β) (γpos : Zero.zero < γ) :
  multiplication_of_positive_two_real_numbers'
    (multiplication_of_positive_two_real_numbers' α β αpos βpos) γ
    (pos_of_pos_mul_pos αpos βpos) γpos
   =
  multiplication_of_positive_two_real_numbers'
    α (multiplication_of_positive_two_real_numbers' β γ βpos γpos)
    αpos (pos_of_pos_mul_pos βpos γpos) := by
  obtain ⟨α, αh⟩ := α
  obtain ⟨β, βh⟩ := β
  obtain ⟨γ, γh⟩ := γ
  simp only [
    LT.lt,
    Zero.zero,
    multiplication_of_positive_two_real_numbers'
  ] at αpos βpos γpos ⊢
  apply Subtype.ext
  ext x
  constructor
  · rintro ⟨
      a,
      ⟨r, rinα, s, sinβ, rpos, spos, ale⟩,
      ⟨y, yinγ, apos, ypos, xle⟩
    ⟩
    use r
    use rinα
    use s * y
    use ⟨s, sinβ, y, yinγ, spos, ypos, le_refl (s * y)⟩
    have spos : 0 < s := spos
    have ypos : 0 < y := ypos
    have s_mul_y_pos : 0 < s * y := (Rat.mul_pos_iff_of_pos_left spos).mpr ypos
    have : x ≤ r * (s * y) := by
      ring_nf
      have : a * y ≤ r * s * y := (mul_le_mul_iff_of_pos_right ypos).mpr ale
      linarith
    exact ⟨rpos, s_mul_y_pos, this⟩
  · rintro ⟨r, rinα, a, ⟨s, sinβ, y, yinγ, spos, ypos, ale⟩, rpos, apos, xle⟩
    use r * s
    use ⟨r, rinα, s, sinβ, rpos, spos, le_refl (r * s)⟩
    use y
    use yinγ
    have spos : 0 < s := spos
    have rpos : 0 < r := rpos
    have r_mul_s_pos : 0 < r * s := (Rat.mul_pos_iff_of_pos_left rpos).mpr spos
    have : x ≤ r * s * y := by
      have : r * a ≤ r * (s * y) := (mul_le_mul_iff_of_pos_left rpos).mpr ale
      have : r * a ≤ r * s * y := by linarith [this]
      linarith [xle, this]
    exact ⟨r_mul_s_pos, ypos, this⟩

end

section -- step 7 --

/-
We complete the definition of multiplication by setting:

  α * 0 = 0
  0 * α = 0

  α > 0, β > 0 => α    *    β
  α < 0, β < 0 => (-α) * (-β)
  α < 0, β > 0 => -((-α) * β)
  α > 0, β < 0 => -(α * (-β))
-/

inductive Sign : Type
  | Neg | Zero | Pos

noncomputable def sign : DedekindReal -> Sign
  := λ α ↦ dite (Zero.zero < α)
    (λ _ ↦ Sign.Pos)
    (λ _ ↦ dite (α < Zero.zero)
      (λ _ ↦ Sign.Neg)
      (λ _ ↦ Sign.Zero)
    )

@[simp]
noncomputable instance : Mul DedekindReal where
  mul := λ α β ↦ dite (α < Zero.zero)
    (λ αneg ↦ dite (β < Zero.zero)
      (λ βneg ↦ multiplication_of_positive_two_real_numbers'
        (-α) (-β) (zero_lt_neg_of_neg αneg) (zero_lt_neg_of_neg βneg)
      )
      (λ _ ↦ dite (Zero.zero < β)
        (λ βpos ↦ - multiplication_of_positive_two_real_numbers'
          (-α) β (zero_lt_neg_of_neg αneg) βpos
        )
        (λ _ ↦ Zero.zero)
      )
    )
    (λ _ ↦ dite (Zero.zero < α)
      (λ αpos ↦ dite (β < Zero.zero)
        (λ βneg ↦ - multiplication_of_positive_two_real_numbers'
          α (-β) αpos (zero_lt_neg_of_neg βneg)
        )
        (λ _ ↦ dite (Zero.zero < β)
          (λ βpos ↦ multiplication_of_positive_two_real_numbers'
            α β αpos βpos
          )
          (λ _ ↦ Zero.zero)
        )
      )
      (λ _ ↦ Zero.zero)
    )

@[simp]
noncomputable instance : HMul DedekindReal DedekindReal DedekindReal where
  hMul := λ α β ↦ Mul.mul α β

instance : One DedekindReal where
  one := ⟨
    {q : ℚ | q < 1},
    ⟨
      ⟨-1, (by norm_num)⟩,
      ⟨ 2, (by norm_num)⟩,
      λ p ph q qltp ↦ (by
        simp at ph ⊢
        linarith
      ),
      λ p ph ↦ (by
        simp only [Set.mem_setOf_eq] at ph ⊢
        use (1 + p) / 2
        constructor
        · linarith
        · linarith
      )
    ⟩
  ⟩

theorem zero_lt_one : (0 : DedekindReal) < (1 : DedekindReal) := by
  change Zero.zero < One.one
  simp only [LT.lt, Zero.zero, One.one]
  refine Set.ssubset_iff_subset_ne.mpr ?_
  constructor
  · intro q qh
    have : q < 1 := Std.lt_of_lt_of_le qh rfl
    exact this
  · set q : ℚ := 1 / 2 with qeq
    have : q ∈ {q : ℚ | q.blt 1 = true} ∧ q ∉ {q : ℚ | q.blt 0 = true} := by
      constructor
      · rw [qeq]
        have : (1 / 2 : ℚ) < (1 : ℚ) := by norm_num
        exact this
      · simp [Rat.blt]
        grind
    grind

theorem one_neq_zero : (1 : DedekindReal) ≠ 0 := by
  exact Ne.symm (Std.ne_of_lt zero_lt_one)

lemma one_mul_pos (α : DedekindReal) (αpos : 0 < α) :
  multiplication_of_positive_two_real_numbers'
    1 α zero_lt_one αpos = α := by
      change multiplication_of_positive_two_real_numbers' One.one α zero_lt_one αpos = α
      have αpos : Zero.zero < α := αpos
      obtain ⟨α, αh⟩ := α
      simp only [multiplication_of_positive_two_real_numbers', One.one, Set.mem_setOf_eq, gt_iff_lt]
      simp only [LT.lt, Zero.zero] at αpos
      apply Subtype.ext
      ext q
      constructor
      · simp only [Set.mem_setOf_eq, forall_exists_index, and_imp]
        intro r rlt1 s sinα rpos spos qle
        have : r * s < s := mul_lt_of_lt_one_left spos rlt1
        have : q < s := lt_of_le_of_lt qle this
        exact αh.downward_closed s sinα q this
      · intro qinα
        obtain ⟨a, ainα, anonneg⟩ := Set.exists_of_ssubset αpos

        -- >_<
        simp only [Rat.blt, Rat.num_neg, Rat.num_ofNat, Std.le_refl, decide_true, Bool.and_true,
          decide_eq_true_eq, Rat.num_eq_zero, lt_self_iff_false, decide_false, Rat.num_pos,
          Rat.den_ofNat, Nat.cast_one, mul_one, zero_mul, Bool.if_false_left, Bool.if_true_left,
          Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
          decide_eq_false_iff_not, not_lt, Set.mem_setOf_eq, not_or, not_and] at anonneg

        have anonneg : 0 ≤ a := by grind
        set q₀ := max q a with q₀df
        have q₀inα : q₀ ∈ α := by
          have : q₀ = q ∨ q₀ = a := Std.MaxEqOr.max_eq_or q a
          rcases this with this | this
          <;> rw [this]
          <;> assumption
        have q₀pos : 0 ≤ q₀ := by
          rw [q₀df]
          by_cases h : q ≤ a
          <;> simp [h]
          <;> grind
        obtain ⟨q', q'inα, q'lt⟩ := αh.no_greatest q₀ q₀inα
        obtain ⟨q'', q''inα, q''lt⟩ := αh.no_greatest q' q'inα
        have q'pos : 0 < q' := by linarith
        have q''pos : 0 < q'' := by linarith
        set r := q' / q'' with rdf
        have rlt1 : r < 1 := (div_lt_one₀ q''pos).mpr q''lt
        have rpos : 0 < r := div_pos q'pos q''pos
        have : q ≤ r * q'' := by
          rw [rdf]
          ring_nf
          rw [mul_assoc]
          rw [Rat.mul_inv_cancel, Rat.mul_one]
          · grind
          · grind
        use r; use rlt1; use q'';

/-
Rudin didn't refer to the Multiplicative Inverse of a real number
in his book.

But it seems not as simple as it can be omitted.
At least, for me.
-/

def multiplicative_inverse_of_positive_real_number' (α : DedekindReal) :
  (Zero.zero < α) -> DedekindReal :=
    λ αpos ↦ ⟨
      {q : ℚ | ∃ r > 0, r ∉ α.val ∧ q < 1 / r},
      (by
        obtain ⟨α, αh⟩ := α
        simp only [LT.lt, Zero.zero, gt_iff_lt, one_div] at αpos ⊢
        exact ⟨
          (by
            have ⟨a, ainα, anonneg⟩ := Set.exists_of_ssubset αpos
            have anonneg : a ≥ 0 := by
              exact Rat.not_lt.mp anonneg
            obtain ⟨r, rninα⟩ := αh.not_univ
            have := αh.lt_of_mem_of_not_mem a ainα r rninα
            have := Std.lt_of_le_of_lt anonneg this
            use (1 : ℚ) / ((2 : ℚ) * r)
            simp only [one_div, mul_inv_rev, Set.mem_setOf_eq]
            use r
            use this
            use rninα
            have : r⁻¹ * (2 : ℚ)⁻¹ < r⁻¹ := by
              have : 0 < r⁻¹ := Rat.inv_pos.mpr this
              linarith
            exact this
          ),
          (by
            simp only [Set.mem_setOf_eq, not_exists, not_and, Bool.not_eq_true]

            -- we shall confine a routhly lower bound of x > 0
            -- which satisty x ∉ α
            --
            -- Obviously, question can be transformed to
            -- "find a positive element in α."
            have ⟨a, ainα, anonneg⟩ := Set.exists_of_ssubset αpos
            simp only [Set.mem_setOf_eq, Bool.not_eq_true] at anonneg
            have anonneg : 0 ≤ a := anonneg

            -- That not what we need,
            -- which attribute to a is **≥** than 0
            -- not **>** than 0.
            --
            -- Just a small step follow on
            -- which using the no_greatest property
            -- of Dedekind Cut.
            obtain ⟨a', a'inα, a'pos⟩ := αh.no_greatest a ainα
            have a'pos : 0 < a' := Std.lt_of_le_of_lt anonneg a'pos

            -- Allright. Now all of the positive x which not in α
            -- have a' < x, which a' is also positive,
            -- hence 1 / x < 1 / a',
            -- Therefore, using 1 / a' as the q we found.
            use a'⁻¹
            intro x xpos xninα
            have xpos : 0 < x := xpos
            have a'ltx := αh.lt_of_mem_of_not_mem a' a'inα x xninα
            have : x⁻¹ < a'⁻¹ := (inv_lt_inv₀ xpos a'pos).mpr a'ltx
            have : x⁻¹ ≤ a'⁻¹ := Rat.le_of_lt this
            exact Bool.eq_true_imp_eq_false.mp fun a ↦ this
          ),
          (by
            intro p p_in_inv q qltp
            obtain ⟨r, rpos, rninα, pltrinv⟩ := p_in_inv
            have rpos : 0 < r := rpos
            have pltrinv : p < r⁻¹ := pltrinv

            -- This can simply get process
            -- just use the r we already have
            -- q < p, p < 1/r => q < 1/r
            use r
            use rpos
            use rninα
            have : q < r⁻¹ := qltp.trans pltrinv
            exact this
          ),
          (by
            intro p pininv

            -- by using the original r
            -- the train of thought we got is
            -- make q become a average between p and 1/r
            -- which must larger than p and smaller than 1/r
            -- which ascribe to that p is smaller than 1/r
            obtain ⟨r, rpos, rninα, pltrinv⟩ := pininv
            have rpos : 0 < r := rpos
            have pltrinv : p < r⁻¹ := pltrinv
            set q := (p + r⁻¹) / 2 with qdf
            use q
            constructor
            · use r
              use rpos
              use rninα
              have : q < r⁻¹ := by
                rw [qdf]
                linarith
              exact this
            · rw [qdf]
              linarith
          )
        ⟩
      )
    ⟩

lemma pos_of_pos_inv (α : DedekindReal) (αpos : 0 < α) :
  0 < multiplicative_inverse_of_positive_real_number' α αpos := by
    change Zero.zero < multiplicative_inverse_of_positive_real_number' α αpos
    have αpos : Zero.zero < α := αpos
    obtain ⟨α, αh⟩ := α
    simp only [LT.lt, Zero.zero, multiplicative_inverse_of_positive_real_number', gt_iff_lt,
      one_div] at αpos ⊢
    refine Set.ssubset_iff_subset_ne.mpr ?_
    constructor
    · intro q qin0
      have qin0 : q < 0 := qin0
      obtain ⟨r₀, r₀inα, r₀nonneg⟩ := Set.exists_of_ssubset αpos
      have r₀nonneg : 0 ≤ r₀ := by
        simp [Rat.blt] at r₀nonneg
        grind
      obtain ⟨r, rninα⟩ := αh.not_univ
      have : r₀ < r := αh.lt_of_mem_of_not_mem r₀ r₀inα r rninα
      have rpos : 0 < r := by linarith
      have : q < r⁻¹ := by
        have : 0 < r⁻¹ := Rat.inv_pos.mpr rpos
        exact qin0.trans this
      use r; use rpos; use rninα; use this;
    · obtain ⟨q, qin, qnin⟩ : ∃ q : ℚ,
        q ∈ {q : ℚ | ∃ r, Rat.blt 0 r = true ∧ r ∉ α ∧ q.blt r⁻¹ = true}
          ∧ q ∉ {q : ℚ | q.blt 0 = true} := by
            simp only [Set.mem_setOf_eq, Bool.not_eq_true]
            obtain ⟨r₀, r₀inα, r₀nonneg⟩ := Set.exists_of_ssubset αpos
            have r₀nonneg : 0 ≤ r₀ := by
              simp [Rat.blt] at r₀nonneg
              grind
            obtain ⟨r, rninα⟩ := αh.not_univ
            have : r₀ < r := αh.lt_of_mem_of_not_mem r₀ r₀inα r rninα
            have rpos : 0 < r := by linarith
            set q := 1 / (2 * r) with qdf
            have qnonneg : 0 ≤ q := by
              rw [qdf]
              ring_nf
              refine Rat.mul_nonneg ?_ ?_
              · refine Rat.inv_nonneg ?_
                linarith
              · norm_num
            have qnblt0 : q.blt 0 = false := by
              simp [Rat.blt]
              grind
            have qltrinv : q < r⁻¹ := by
              rw [qdf]
              ring_nf
              have : 0 < r⁻¹ := Rat.inv_pos.mpr rpos
              linarith
            use q;
            use ⟨r, rpos, rninα, qltrinv⟩
      exact Ne.symm (ne_of_mem_of_not_mem' qin qnin)

lemma one21 : (One.one : DedekindReal) = 1 := by
  change 1 = 1
  rfl

lemma pos_mul_inv_cancel (α : DedekindReal) (αpos : Zero.zero < α) :
  multiplication_of_positive_two_real_numbers'
    α (multiplicative_inverse_of_positive_real_number' α αpos)
    αpos (pos_of_pos_inv α αpos) = One.one := by
      obtain ⟨α, αh⟩ := α

      simp only [LT.lt, Zero.zero, multiplication_of_positive_two_real_numbers',
        multiplicative_inverse_of_positive_real_number', gt_iff_lt, one_div, Set.mem_setOf_eq,
        One.one] at αpos ⊢

      apply Subtype.ext
      ext x
      constructor
      · simp only [Set.mem_setOf_eq, forall_exists_index, and_imp]
        intro a ainα p q qpos qninα p_lt_q_inv apos ppos x_le_a_p
        change 0 < a at apos
        change 0 < p at ppos
        change 0 < q at qpos
        change x < 1
        change p < q⁻¹ at p_lt_q_inv
        have a_lt_q := αh.lt_of_mem_of_not_mem a ainα q qninα
        calc
          x ≤ a * p := x_le_a_p
          _ < q * p := (Rat.mul_lt_mul_right ppos).mpr a_lt_q
          _ < q * q⁻¹ := (Rat.mul_lt_mul_left qpos).mpr p_lt_q_inv
          _ = 1 := by grind
      · intro xlt1
        change x < 1 at xlt1
        change ∃ a ∈ α, ∃ s,
          (∃ r, 0 < r ∧ r ∉ α ∧ s < r⁻¹)
            ∧ 0 < a ∧ 0 < s ∧ x ≤ a * s

        obtain ⟨a₀, a₀inα, a₀nin0⟩ := Set.exists_of_ssubset αpos

        simp only [Rat.blt, Rat.num_neg, Rat.num_ofNat, Std.le_refl, decide_true, Bool.and_true,
          decide_eq_true_eq, Rat.num_eq_zero, lt_self_iff_false, decide_false, Rat.num_pos,
          Rat.den_ofNat, Nat.cast_one, mul_one, zero_mul, Bool.if_false_left, Bool.if_true_left,
          Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
          decide_eq_false_iff_not, not_lt, Set.mem_setOf_eq, not_or, not_and] at a₀nin0

        have a₀nin0 : 0 ≤ a₀ := by grind
        obtain ⟨a', a'inα, a'ge⟩ := αh.no_greatest a₀ a₀inα
        have a'pos : 0 < a' := by linarith

        by_cases xpos : x ≤ 0

        · obtain ⟨r₀, r₀ninα⟩ := αh.not_univ
          set r := max r₀ 1 with rdf
          have r₀lt : r₀ ≤ r := Std.left_le_max
          have rninα : r ∉ α := by
            by_cases h : r = r₀
            · rw [h]
              assumption
            · have : r₀ < r := Rat.lt_of_le_of_ne r₀lt
                λ a ↦ h (id (Eq.symm a))
              exact αh.upward_closed_compl r₀ r₀ninα r this
          have rpos : 0 < r := by grind
          set s := r⁻¹ / 2 with sdf
          have spos : 0 < s := by
            rw [sdf]
            ring_nf
            refine (Rat.mul_pos_iff_of_pos_left ?_).mpr ?_
            · exact Rat.inv_pos.mpr rpos
            · norm_num
          have slt : s < r⁻¹ := by
            linarith
          have : x ≤ a' * s := by
            calc
              x ≤ 0 := xpos
              _ ≤ _ := by
                have : 0 < a' * s
                  := (Rat.mul_pos_iff_of_pos_left a'pos).mpr spos
                linarith
          use a'; use a'inα; use s
          use ⟨r, rpos, rninα, slt⟩

        · push Not at xpos
          have ⟨a, ainα, r, rninα, apos, rlt⟩ := αh.exists_ratio_lt_of_positive_and_eps_gt_one
            ⟨a', a'inα, a'pos⟩ (1 / x) (one_lt_one_div xpos xlt1)
          set s := x / a with sdf
          have xle : x ≤ a * s := by
            have sdf' : a * s = x := by
              rw [sdf]
              ring_nf
              rw [mul_assoc, mul_comm x, ← mul_assoc, Rat.mul_inv_cancel, one_mul]
              exact Ne.symm (Rat.ne_of_lt apos)
            exact Std.le_of_eq (id (Eq.symm sdf'))
          have rpos : 0 < r :=
            calc
              0 < a := apos
              a < r := αh.lt_of_mem_of_not_mem a ainα r rninα
          have slt : s < r⁻¹ := by
            rw [sdf]
            calc
              _ = r / a * x * r⁻¹ := by
                ring_nf
                rw [mul_assoc (x * a⁻¹), Rat.mul_inv_cancel, mul_one]
                exact Ne.symm (Rat.ne_of_lt rpos)
              _ < 1 / x * x * r⁻¹ := by
                rw [mul_assoc, mul_assoc]
                apply Rat.mul_lt_mul_of_pos_right
                · exact rlt
                · have : 0 < r⁻¹ := Rat.inv_pos.mpr rpos
                  exact (Rat.mul_pos_iff_of_pos_left xpos).mpr this
              _ = _ := by
                ring_nf
                rw [Rat.mul_inv_cancel, one_mul]
                exact Ne.symm (Rat.ne_of_lt xpos)

          use a; use ainα; use s;
          exact ⟨⟨r, rpos, rninα, slt⟩, apos, (div_pos xpos apos), xle⟩

noncomputable instance : Inv DedekindReal where
  inv := λ α ↦ dite (α < Zero.zero)
    (λ αneg ↦ - multiplicative_inverse_of_positive_real_number'
      (-α) (zero_lt_neg_of_neg αneg)
    )
    (λ _ ↦ dite (Zero.zero < α)
      (λ αpos ↦ multiplicative_inverse_of_positive_real_number'
        α αpos
      )
      (λ _ ↦ Zero.zero) -- simply define the inverse of 0 is 0.
    )

end

section
variable (α β : DedekindReal)

#check α * β

example : Zero.zero * Zero.zero = (Zero.zero : DedekindReal) := by
  simp [HMul.hMul, Mul.mul]

example : α * Zero.zero = Zero.zero := by
  simp [HMul.hMul, Mul.mul]

example : α * Zero.zero * β = Zero.zero := by
  simp [HMul.hMul, Mul.mul]

end

section -- Signal simplification lemmas
variable {α β : DedekindReal}

@[simp]
theorem mul_def_pos_pos (hα : Zero.zero < α) (hβ : Zero.zero < β) :
    α * β = multiplication_of_positive_two_real_numbers' α β hα hβ := by
  dsimp [HMul.hMul, Mul.mul]
  split_ifs <;>
  try {grind}

@[simp]
theorem mul_def_pos_neg (hα : Zero.zero < α) (hβ : β < Zero.zero) :
    α * β = -multiplication_of_positive_two_real_numbers' α (-β) hα (zero_lt_neg_of_neg hβ) := by
  dsimp [HMul.hMul, Mul.mul]
  split_ifs <;>
  try {grind}

@[simp]
theorem mul_def_neg_pos (hα : α < Zero.zero) (hβ : Zero.zero < β) :
    α * β = -multiplication_of_positive_two_real_numbers' (-α) β (zero_lt_neg_of_neg hα) hβ := by
  dsimp [HMul.hMul, Mul.mul]
  split_ifs <;>
  try {grind}

@[simp]
theorem mul_def_neg_neg (hα : α < Zero.zero) (hβ : β < Zero.zero) :
    α * β = multiplication_of_positive_two_real_numbers' (-α) (-β)
    (zero_lt_neg_of_neg hα) (zero_lt_neg_of_neg hβ) := by
  dsimp [HMul.hMul, Mul.mul]
  split_ifs
  try {grind}

@[simp]
theorem zero_mul (α : DedekindReal) : Zero.zero * α = Zero.zero := by
  dsimp [HMul.hMul, Mul.mul]
  split_ifs <;>
  try {grind}

@[simp]
theorem mul_zero (α : DedekindReal) : α * Zero.zero = Zero.zero := by
  dsimp [HMul.hMul, Mul.mul]
  split_ifs <;>
  try {grind}

@[simp]
theorem not_neg_lt_zero_of_neg {α : DedekindReal} (h : α < 0) : ¬ -α < 0 :=
  not_lt_of_gt (zero_lt_neg_of_neg h)

@[simp]
theorem neg_lt_zero_iff_pos {α : DedekindReal} : -α < 0 ↔ 0 < α
  := ⟨
    λ h ↦ dedekindreal_neg_neg α ▸ zero_lt_neg_of_neg h,
    λ h ↦ neg_lt_zero_of_pos h
  ⟩

@[simp]
theorem neg_lt_zero_eq_false_of_neg {α : DedekindReal} (h : α < 0) : (-α < 0) = False :=
  eq_false (not_neg_lt_zero_of_neg h)

@[simp]
theorem not_lt_of_gt {α β : DedekindReal} (h : α < β) : ¬ β < α := by
  intro h'
  have := h.trans h'
  grind

@[simp]
theorem neg_mul (α β : DedekindReal) : (-α) * β = -(α * β) := by
  have c1 := lt_trichotomy α Zero.zero
  have c2 := lt_trichotomy β Zero.zero
  rcases c1 with c1 | c1 | c1
  <;> rcases c2 with c2 | c2 | c2
  <;> simp [zero20] at c1 c2

  <;> simp [
    HMul.hMul,
    Mul.mul,
    c1, c2,
    zero_lt_neg_of_neg,
    dedekindreal_neg_neg,
  ]

@[simp]
theorem mul_neg (α β : DedekindReal) : α * (-β) = -(α * β) := by
  have c1 := lt_trichotomy α Zero.zero
  have c2 := lt_trichotomy β Zero.zero
  rcases c1 with c1 | c1 | c1
  <;> rcases c2 with c2 | c2 | c2
  <;> simp [zero20] at c1 c2

  <;> simp [
    HMul.hMul,
    Mul.mul,
    c1, c2,
    zero_lt_neg_of_neg,
    dedekindreal_neg_neg,
  ]

/-
Some tools preparing for proof
  of filed multiplication axioms
    which provided by CAIMEOX.
-/
def signMul : Bool -> DedekindReal -> DedekindReal
  := λ s x ↦ if s then -x else x

#check signMul false 0

@[simp]
theorem signMul_mul (s t : Bool) (x y : DedekindReal) :
  signMul s x * signMul t y = signMul (Bool.xor s t) (x * y) := by
    cases s
    <;> cases t
    <;> simp [
      signMul,
      neg_mul,
      mul_neg,
      dedekindreal_neg_neg
    ]

theorem exists_sign_pos (x : DedekindReal) (hx : x ≠ 0) :
  ∃ s : Bool, ∃ a : DedekindReal, 0 < a ∧ x = signMul s a := by
  by_cases h : x < 0
  · refine ⟨true, -x, zero_lt_neg_of_neg h, ?_⟩
    change x = -(-x)
    rw [dedekindreal_neg_neg]
  · have hxpos : 0 < x := by
      rcases lt_trichotomy x Zero.zero with hlt | rfl | hgt
      · exact False.elim (h hlt)
      · exact False.elim (hx rfl)
      · exact hgt
    refine ⟨false, x, hxpos, ?_⟩
    simp [signMul]

theorem mul_assoc_of_pos {α β γ : DedekindReal} :
  0 < α -> 0 < β -> 0 < γ -> α * (β * γ) = α * β * γ := by
    intro αpos βpos γpos
    have pos_of_β_γ : 0 < multiplication_of_positive_two_real_numbers' β γ βpos γpos := by
      exact pos_of_pos_mul_pos βpos γpos
    have pos_of_α_β : 0 < multiplication_of_positive_two_real_numbers' α β αpos βpos := by
      exact pos_of_pos_mul_pos αpos βpos
    simp only [HMul.hMul, Mul.mul, zero20, αpos, not_lt_of_gt, ↓reduceDIte, βpos, γpos, pos_of_β_γ,
      pos_of_α_β]
    rw [multiplication_of_positive_three_real_numbers_is_associative' αpos βpos γpos]

end

theorem mul_comm {α β : DedekindReal} :
  α * β = β * α := by
    have c1 := lt_trichotomy α Zero.zero
    have c2 := lt_trichotomy β Zero.zero
    rcases c1 with c1 | c1 | c1 <;>
    rcases c2 with c2 | c2 | c2 <;>
    simp [zero20] at c1 c2 <;>
    simp [
      HMul.hMul,
      Mul.mul,
      c1,
      c2,
      multiplication_of_positive_two_real_numbers_is_communicative',
    ]

theorem mul_assoc {α β γ : DedekindReal} :
  α * β * γ = α * (β * γ) := by
    by_cases hα : α = 0
    · subst hα
      calc
        0 * β * γ = 0 * γ := by
          exact congrArg (fun t => t * γ) (zero_mul β)
        _ = 0 := by
          simpa [zero20] using (zero_mul γ)
        _ = 0 * (β * γ) := by
          simpa [zero20] using (zero_mul (β * γ)).symm
    by_cases hβ : β = 0
    · subst hβ
      calc
        α * 0 * γ = 0 * γ := by
          exact congrArg (fun t => t * γ) (mul_zero α)
        _ = 0 := by
          simpa [zero20] using (zero_mul γ)
        _ = α * (0 * γ) := by
          have hz : 0 * γ = 0 := by
            simpa [zero20] using (zero_mul γ)
          rw [hz]
          simpa [zero20] using (mul_zero α).symm
    by_cases hγ : γ = 0
    · subst hγ
      calc
        α * β * 0 = 0 := by
          simpa [zero20] using (mul_zero (α * β))
        _ = α * (β * 0) := by
          have hz : β * 0 = 0 := by
            simpa [zero20] using (mul_zero β)
          rw [hz]
          simpa [zero20] using (mul_zero α).symm
    obtain ⟨sα, a, ha, rfl⟩ := exists_sign_pos α hα
    obtain ⟨sβ, b, hb, rfl⟩ := exists_sign_pos β hβ
    obtain ⟨sγ, c, hc, rfl⟩ := exists_sign_pos γ hγ
    simp only [signMul_mul, Bool.bne_assoc]
    rw [mul_assoc_of_pos]
    · simp [ha]
    · exact hb
    exact hc

theorem one_mul {α : DedekindReal} :
  1 * α = α := by
    have c := lt_trichotomy α 0
    rcases c with c | c | c
    <;> simp [
      HMul.hMul,
      Mul.mul,
      c,
      zero_lt_one,
      one_mul_pos,
      dedekindreal_neg_neg,
    ]

theorem mul_inv_cancel {α : DedekindReal} :
  α ≠ 0 -> α * α⁻¹ = 1 := by
    intro hyp
    change α * α⁻¹ = One.one
    have c := lt_trichotomy α 0
    rcases c with c | c | c
    <;> simp [
      HMul.hMul,
      Mul.mul,
      Inv.inv,
      c,
      pos_of_pos_inv,
      dedekindreal_neg_neg,
      pos_mul_inv_cancel
    ]
    grind

section
open Fields LinearOrder

/-
We finally can define the Field of our Real Number
-/
noncomputable instance : FieldAxioms DedekindReal where
  A1 := λ α β ↦ ⟨α + β, rfl⟩

  -- ∀ (x y : DedekindReal), x + y = y + x
  A2 := dedekindreal_add_comm

  -- ∀ (x y z : DedekindReal), x + y + z = x + (y + z)
  A3 := dedekindreal_add_assoc

  -- ∀ (x : DedekindReal), 0 + x = x
  A4 := dedekindreal_zero_add

  -- ∀ (x : DedekindReal), x + -x = 0
  A5 := dedekindreal_add_neg_cancel

  M1 := λ α β ↦ ⟨α * β, rfl⟩

  -- ∀ (x y : DedekindReal), x * y = y * x
  M2 := by
    intro α β
    rw [mul_comm]

  -- M3 : ∀ (x y z : DedekindReal), x * y * z = x * (y * z)
  M3 := by
    intro α β γ
    rw [mul_assoc]

  -- 1 ≠ 0 ∧ ∀ (x : DedekindReal), 1 * x = x
  M4 := by
    constructor
    · exact one_neq_zero
    · intro α
      rw [one_mul]

  -- ∀ (x : DedekindReal), x ≠ 0 → x * x⁻¹ = 1
  M5 := by
    intro α hyp
    rw [mul_inv_cancel hyp]

  -- ∀ (x y z : DedekindReal), x * (y + z) = x * y + x * z
  D  := sorry

end

end TheRealField
