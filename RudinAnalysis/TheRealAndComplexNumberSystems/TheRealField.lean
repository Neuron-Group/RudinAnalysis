import RudinAnalysis.TheRealAndComplexNumberSystems.Import
import RudinAnalysis.TheRealAndComplexNumberSystems.OrderedSets
import RudinAnalysis.TheRealAndComplexNumberSystems.Fields

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
  push Not at h  -- 现在 h : ∀ p ∈ α, p + r ∈ α

  obtain ⟨p₀, hp₀⟩ := rα.nonempty
  obtain ⟨q, hq⟩ := rα.is_bounded_above  -- hq : ∀ x ∈ α, x ≤ q

  have h_all : ∀ n : ℕ, p₀ + (n : ℚ) * r ∈ α := by
    intro n
    induction n with
    | zero => simpa using hp₀
    | succ n ih =>
        -- 把 succ 写成 n+1，利用归纳假设和 h
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

section
variable (α : DedekindReal)

#check -α

end

--  α : Set ℚ
-- -α : Set ℚ := {q : ℚ | ∃ r > 0, -q - r ∉ α }
--  0 : Set ℚ := {q : ℚ | q < 0               }
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

theorem pos_of_neg_neg {α : DedekindReal} :
  (α < Zero.zero) -> (Zero.zero < -α) := by
    obtain ⟨α, αh⟩ := α
    intro αneg
    simp only [LT.lt, Zero.zero, Neg.neg, gt_iff_lt] at αneg ⊢
    refine Set.ssubset_iff_subset_ne.mpr ?_
    constructor
    · intro q qin0
      simp only [Rat.blt, Rat.num_neg, Rat.num_ofNat, Std.le_refl, decide_true, Bool.and_true,
        decide_eq_true_eq, Rat.num_eq_zero, lt_self_iff_false, decide_false, Rat.num_pos,
        Rat.den_ofNat, Nat.cast_one, mul_one, zero_mul, Bool.if_false_left, Bool.if_true_left,
        Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
        decide_eq_false_iff_not, not_lt, mem_setOf_eq, Rat.num_nonneg, Bool.false_and,
        Bool.false_eq_true, ↓reduceIte] at qin0 ⊢
      have qin0 : q < 0 := by grind
      use - q / 2
      constructor
      · grind
      · have h1 : q.neg - -q / 2 > 0 := by
          simp only [gt_iff_lt, sub_pos]
          calc
            -q / 2 < -q := by linarith
            _ = _ := Rat.add_left_cancel q rfl
        intro assume
        have := αneg.left assume
        simp only [Rat.blt, Rat.num_neg, Rat.num_ofNat, Std.le_refl, decide_true, Bool.and_true,
          decide_eq_true_eq, Rat.num_eq_zero, lt_self_iff_false, decide_false, Rat.num_pos,
          Rat.den_ofNat, Nat.cast_one, mul_one, zero_mul, Bool.if_false_left, Bool.if_true_left,
          Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
          decide_eq_false_iff_not, not_lt, mem_setOf_eq, sub_neg, tsub_le_iff_right,
          zero_add] at this
        have q_neg_lt_neg_q_div_2 : q.neg < -q / 2 := by grind
        have h2 : q.neg - -q / 2 ≤ 0 := by
          have : q.neg - -q / 2 < 0
            := sub_neg.mpr q_neg_lt_neg_q_div_2
          exact Rat.le_of_lt this
        have h2 : ¬ q.neg - -q / 2 > 0 := by
          exact Rat.not_lt.mpr h2
        contradiction
    intro eq
    have := Set.ext_iff.mp eq
    simp only [mem_setOf_eq] at this

    -- α ⊂ {q | q < 0} => ∃ q < 0, q ∉ α
    -- q < 0 => q / 2 < 0, -q / 2 > 0
    -- use -q / 2 as x and r,
    -- hence -x - r = q ∉ α, and x is positive.
    have ⟨q, qneg, qninα⟩ := exists_of_ssubset αneg
    simp only [Rat.blt, Rat.num_neg, Rat.num_ofNat, Std.le_refl, decide_true, Bool.and_true,
      decide_eq_true_eq, Rat.num_eq_zero, lt_self_iff_false, decide_false, Rat.num_pos,
      Rat.den_ofNat, Nat.cast_one, mul_one, zero_mul, Bool.if_false_left, Bool.if_true_left,
      Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
      decide_eq_false_iff_not, not_lt, mem_setOf_eq] at qneg
    have qneg : q < 0 := by grind
    have := (iff_def.mp (this (-q / 2))).right
    contrapose! this
    constructor
    · use -q / 2
      constructor
      · have : 0 < -q / 2 := by grind
        exact Bool.eq_false_imp_eq_true.mp fun a ↦ this
      · have : (-q / 2).neg - -q / 2 = q := by
          have : (-q / 2).neg = -(-q / 2) := by
            exact Eq.symm (Rat.add_left_cancel q rfl)
          rw [this]
          ring
        rw [this]
        exact qninα
    have : (-q / 2).blt 0 = (-q / 2 < 0) := by
      exact Eq.propIntro (fun a ↦ a) fun a ↦ a
    intro h
    rw [this] at h
    grind


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
        (-α) (-β) (pos_of_neg_neg αneg) (pos_of_neg_neg βneg)
      )
      (λ _ ↦ dite (Zero.zero < β)
        (λ βpos ↦ - multiplication_of_positive_two_real_numbers'
          (-α) β (pos_of_neg_neg αneg) βpos
        )
        (λ _ ↦ Zero.zero)
      )
    )
    (λ _ ↦ dite (Zero.zero < α)
      (λ αpos ↦ dite (β < Zero.zero)
        (λ βneg ↦ - multiplication_of_positive_two_real_numbers'
          α (-β) αpos (pos_of_neg_neg βneg)
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

noncomputable instance : Inv DedekindReal where
  inv := λ α ↦ dite (α < Zero.zero)
    (λ αneg ↦ - multiplicative_inverse_of_positive_real_number'
      (-α) (pos_of_neg_neg αneg)
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

section
open Fields LinearOrder

/-
We finally can define the Field of our Real Number
-/
noncomputable instance : FieldAxioms DedekindReal where
  A1 := λ α β ↦ ⟨α + β, rfl⟩
  A2 := by
    rintro ⟨α, αh⟩ ⟨β, βh⟩
    dsimp [HAdd.hAdd, Add.add]
    apply Subtype.ext
    ext x
    simp only [Set.mem_setOf_eq]
    constructor <;> rintro ⟨a, ha, b, hb, rfl⟩ <;>
      exact ⟨b, hb, a, ha, add_comm a b⟩
  A3 := by
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
  A4 := by
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
  A5 := by
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


  M1 := sorry
  M2 := sorry
  M3 := sorry
  M4 := sorry
  M5 := sorry

  D  := sorry

end

end TheRealField
