import RudinAnalysis.TheRealAndComplexNumberSystems.Import
set_option linter.style.emptyLine false

open scoped BigOperators
open Rat Set Function

namespace Introduction

theorem Rat.mem_intCast_iff (r : ℚ) : r ∈ range Int.cast ↔ (⌊r⌋ : ℚ) = r := by
  constructor
  · intro ⟨_, hk⟩; rw [← hk, Int.floor_intCast]
  · intro hr; rw [← hr]; use ⌊r⌋

theorem Rat.not_mem_intCast_iff (r : ℚ) : r ∉ range Int.cast ↔ (⌊r⌋ : ℚ) ≠ r := by
  rw [mem_intCast_iff]

-- The proof of 1/3 is not a Interger (which obvious by human)
example : (3⁻¹ : ℚ) ∉ range Int.cast := by
  rw [Rat.not_mem_intCast_iff]
  decide +kernel

theorem Rat.exists_coprime_pow_eq_mul_of_pos {x : ℚ} {n r : ℕ} :
  x > 0 -> x ^ r = ↑n -> ∃ p q : ℕ, p.Coprime q ∧ p ^ r = q ^ r * n := by
    intro xpos h
    rw [← num_div_den x] at h
    rw [div_pow] at h
    field_simp at h

    have h_z_eq : (x.num : ℤ) ^ r = (x.den : ℤ) ^ r * ↑n := by
      apply Int.cast_injective (α := ℚ)
      push_cast
      exact h

    have cpr := x.isCoprime_num_den

    set p := x.num.natAbs with pdf
    set q := x.den with qdf

    have num_pos : ↑p = x.num := by
      refine Int.natAbs_of_nonneg ?_
      refine num_nonneg.mpr ?_
      exact Rat.le_of_lt xpos

    have p_q_cpr : p.Coprime q := by
      exact x.reduced

    use p; use q;use p_q_cpr;

    rw [← num_pos] at h_z_eq

    exact Eq.symm ((fun {m n} ↦ Int.ofNat_inj.mp) (id (Eq.symm h_z_eq)))

theorem Rat.exists_coprime_pow_eq_mul {x : ℚ} {n r : ℕ} :
  x ^ r = ↑n -> ∃ p q : ℤ, IsCoprime p q ∧ p ^ r = q ^ r * n := by
    intro h
    rw [← num_div_den x] at h
    rw [div_pow] at h
    field_simp at h

    have h_z_eq : (x.num : ℤ) ^ r = (x.den : ℤ) ^ r * ↑n := by
      apply Int.cast_injective (α := ℚ)
      push_cast
      exact h

    have cpr := x.isCoprime_num_den

    set p := x.num with pdf
    set q := (x.den : ℤ) with qdf

    use p; use q;

section

#check Rat
#check Nat.Prime.dvd_of_dvd_pow

lemma two_dvd_of_two_dvd_sq {k : ℕ} (hk : 2 ∣ k ^ 2) :
  2 ∣ k := by
    apply Nat.Prime.dvd_of_dvd_pow
    · exact Nat.prime_two
    exact hk

lemma div_2 {m n : ℕ} (hnm : 2 * m = 2 * n) : (m = n) := by
  have : 0 < 2 := by norm_num
  apply Nat.eq_of_mul_eq_mul_left this hnm

lemma division_lemma_m {m n : ℕ}
  (hmn : 2 * m ^ 2 = n ^ 2)
    : 2 ∣ m := by
      have : 2 ∣ n ^ 2 := by
        apply dvd_def.mpr
        use m ^ 2
        exact hmn.symm
      have two_dvd_n : 2 ∣ n := two_dvd_of_two_dvd_sq this
      rw [dvd_def] at two_dvd_n
      rcases two_dvd_n with ⟨c, ceq⟩
      rw [ceq] at hmn
      rw [mul_pow] at hmn
      nth_rw 2 [pow_two] at hmn
      rw [mul_assoc] at hmn
      have := div_2 hmn
      --
      apply two_dvd_of_two_dvd_sq
      rw [dvd_def]
      use c ^ 2

#check Nat.not_coprime_of_dvd_of_dvd
theorem sqrt2_irrational' :
  ¬∃ (m n : ℕ),
    2 * m ^ 2 = n ^ 2  ∧
    m.Coprime n := by
      rintro ⟨m, ⟨n, ⟨eq, cpr⟩⟩⟩
      have two_dvd_n : 2 ∣ n := by
        apply two_dvd_of_two_dvd_sq
        rw [dvd_def]
        use m ^ 2
        exact eq |> symm
      have two_dvd_m := by
        exact division_lemma_m eq
      have := Nat.not_coprime_of_dvd_of_dvd (by norm_num) two_dvd_m two_dvd_n
      contradiction

#check pow_pos
lemma ge_zero_sq_ge_zero {n : ℕ} (hne : 0 < n)
  : (0 < n ^ 2) := by
    exact pow_pos hne 2

#check Nat.mul_left_inj
lemma cancellation_lemma {k m n : ℕ}
  (hk_pos : 0 < k ^ 2)
  (hmn : 2 * (m * k) ^ 2 = (n * k) ^ 2)
    : 2 * m ^ 2 = n ^ 2 := by
      repeat rw [mul_pow] at hmn
      rw [← mul_assoc] at hmn
      have hk_neq_0 : k ^ 2 ≠ 0 := by
        exact Nat.ne_zero_of_lt hk_pos
      rw [Nat.mul_left_inj hk_neq_0] at hmn
      assumption

#check Nat.gcd_pos_of_pos_left
#check Nat.gcd_pos_of_pos_right
#check Nat.exists_coprime
#check Nat.pos_of_ne_zero

theorem wlog_coprime :
  (∃ (m n : ℕ), 2 * m ^ 2 = n ^ 2 ∧ m ≠ 0)
  → (∃ (m' n' : ℕ), 2 * m' ^ 2 = n' ^ 2 ∧ m'.Coprime n') := by
  intro hypotheses
  obtain ⟨m, n, ⟨eq, mneq0⟩⟩ := hypotheses
  have := Nat.exists_coprime m n
  rcases this with ⟨m', n', hl, h, hr⟩
  use m'
  use n'
  constructor
  · rw [h] at eq
    nth_rw 2 [hr] at eq
    repeat rw [mul_pow] at eq
    rw [← mul_assoc] at eq
    have : m.gcd n ≠ 0 := by
      exact Nat.gcd_ne_zero_left mneq0
    have : m.gcd n ^ 2 ≠ 0 := by
      exact pow_ne_zero 2 this
    rw [Nat.mul_left_inj this] at eq
    exact eq
  · exact hl

theorem sqrt2_irrational'' :
  ¬∃ (m n : ℕ),
    2 * m ^ 2 = n ^ 2 ∧ m ≠ 0 := by
    by_contra
    have h1 := wlog_coprime this
    have h2 := sqrt2_irrational'
    contradiction

#check num_div_den
#check Rat

#check cast_injective
#check Injective
#check cast
#check Injective Rat.cast
theorem no_rational_sqrt_two : ¬∃ p : ℚ, p ^ 2 = 2 := by
  rintro ⟨p, hp⟩

  -- rewrite p as a fraction
  rw [← num_div_den p] at hp

  -- handle with squre and denominator
  rw [div_pow] at hp
  field_simp at hp

  -- obtain the interger equation (follow the inj map on ℚ)
  have h_int_eq : (p.num : ℤ) ^ 2 = 2 * (p.den : ℤ) ^ 2 := by
    apply Int.cast_injective (α := ℚ)
    push_cast
    rw [mul_comm]
    exact hp

  -- transform to real number
  let m : ℕ := p.den
  let n : ℕ := p.num.natAbs
  have h_nat_eq : 2 * m ^ 2 = n ^ 2 := by
    rw [← Int.natAbs_sq] at h_int_eq          -- h_int_eq : (n : ℤ)^2 = 2 * (m : ℤ)^2
    exact_mod_cast h_int_eq.symm

  -- denominator is not zero
  have h_m_ne_zero : m ≠ 0 := p.den_nz

  -- contradict with sqrt2_irrational''
  exact sqrt2_irrational'' ⟨m, n, h_nat_eq, h_m_ne_zero⟩

end

section --1.1

def A : Set ℚ := {p : ℚ | 0 < p ∧ p ^ 2 < 2}
def B : Set ℚ := {p : ℚ | 0 < p ∧ p ^ 2 > 2}

example : ∀ p ∈ A, ∃ q ∈ A, p < q := by
  intro p pinA
  set q := (2 * p + 2)/(p + 2) with qeq
  use q
  unfold A at pinA ⊢
  simp only [mem_setOf_eq] at pinA ⊢
  constructor
  · constructor
    · rw [qeq]
      apply div_pos
      repeat linarith
    · rw [qeq]
      apply lt_of_sub_neg

      have this₁ : (p + 2) ^ 2 ≠ 0 := by
        rw [ne_comm]
        apply ne_of_lt
        apply pow_pos
        linarith

      have this₂ : 0 < (p + 2) ^ 2 := by
        positivity

      calc
        _ = ((2 * p + 2) ^ 2 / (p + 2) ^ 2) - 2 := by
          rw [div_pow]
        _ = ((2 * p + 2) ^ 2 - 2 * (p + 2) ^ 2) / (p + 2) ^ 2 := by
          rw [sub_div _ _ ((p + 2) ^ 2)]
          simp only [sub_right_inj]
          apply eq_div_of_mul_eq
          · exact this₁
          rfl
        _ = 2 * (p ^ 2 - 2) / (p + 2) ^ 2 := by
          apply (div_left_inj' this₁).mpr
          simp [pow_two]
          ring
        _ < _ := by
          have h₁ : p ^ 2 - 2 < 0 := by
            linarith
          rw [div_eq_inv_mul]
          apply mul_neg_of_pos_of_neg
          · apply inv_pos_of_pos
            exact this₂
          linarith
  rw [qeq]
  refine (Rat.lt_div_iff ?_).mpr ?_
  · linarith
  · rw [mul_add]
    linarith

example : ∀ p ∈ B, ∃ q ∈ B, q < p := by
  unfold B; simp only [gt_iff_lt, mem_setOf_eq, and_imp];
  intro p ppos two_lt_p_sq
  set q := (2 * p + 2) / (p + 2) with qdf
  have qpos : 0 < q := by
    rw [qdf]
    refine (Rat.lt_div_iff ?_).mpr ?_
    · exact Right.add_pos_of_pos_of_nonneg ppos rfl
    · simp
      linarith
  have two_lt_q_sq : 2 < q ^ 2 := by
    rw [qdf]
    rw [div_pow]
    refine (Rat.lt_div_iff ?_).mpr ?_
    · linarith
    · ring_nf
      linarith
  use q;
  use ⟨qpos, two_lt_q_sq⟩;
  refine (Rat.div_lt_iff' ?_).mpr ?_
  · exact Right.add_pos_of_pos_of_nonneg ppos rfl
  · ring_nf
    linarith

end

section

private def positiveColorWeight (n : ℕ) : ℕ :=
  n.factorization 2 + 3 * n.factorization 3 + 4 * n.factorization 5

private def positiveColor (n : ℕ) : Fin 5 :=
  ⟨positiveColorWeight n % 5, Nat.mod_lt _ (by decide)⟩

private def positivePart (i : Fin 5) : Set ℕ := {n : ℕ | 0 < n ∧ positiveColor n = i}

private def shiftPerm : Equiv.Perm (Fin 5) where
  toFun
    | 0 => 0
    | 1 => 1
    | 2 => 3
    | 3 => 2
    | 4 => 4
  invFun
    | 0 => 0
    | 1 => 1
    | 2 => 3
    | 3 => 2
    | 4 => 4
  left_inv := by
    intro i
    fin_cases i <;> rfl
  right_inv := by
    intro i
    fin_cases i <;> rfl

private lemma positiveColorWeight_mul {a n : ℕ} (ha : a ≠ 0) (hn : n ≠ 0) :
    positiveColorWeight (a * n) = positiveColorWeight a + positiveColorWeight n := by
  have hmul := Nat.factorization_mul ha hn
  have h2 : (a * n).factorization 2 = a.factorization 2 + n.factorization 2 := by
    exact congrArg (fun f => f 2) hmul
  have h3 : (a * n).factorization 3 = a.factorization 3 + n.factorization 3 := by
    exact congrArg (fun f => f 3) hmul
  have h5 : (a * n).factorization 5 = a.factorization 5 + n.factorization 5 := by
    exact congrArg (fun f => f 5) hmul
  dsimp [positiveColorWeight]
  rw [h2, h3, h5]
  omega

private lemma positiveColor_mul_eq_add {a n : ℕ} (ha : a ≠ 0) (hn : n ≠ 0) :
    positiveColor (a * n) = positiveColor n + positiveColor a := by
  apply Fin.ext
  simp [positiveColor, positiveColorWeight_mul, ha, hn, Fin.add_def, Nat.add_mod, add_comm]

private lemma positiveColorWeight_one : positiveColorWeight 1 = 0 := by
  simp [positiveColorWeight]

private lemma positiveColorWeight_two : positiveColorWeight 2 = 1 := by
  simp [positiveColorWeight, Nat.prime_two.factorization_self,
    Nat.factorization_eq_zero_of_not_dvd (by norm_num : ¬ 3 ∣ 2),
    Nat.factorization_eq_zero_of_not_dvd (by norm_num : ¬ 5 ∣ 2)]

private lemma positiveColorWeight_three : positiveColorWeight 3 = 3 := by
  simp [positiveColorWeight, Nat.prime_three.factorization_self,
    Nat.factorization_eq_zero_of_not_dvd (by norm_num : ¬ 2 ∣ 3),
    Nat.factorization_eq_zero_of_not_dvd (by norm_num : ¬ 5 ∣ 3)]

private lemma positiveColorWeight_four : positiveColorWeight 4 = 2 := by
  simpa [positiveColorWeight_two] using
    positiveColorWeight_mul (a := 2) (n := 2) (by norm_num : 2 ≠ 0) (by norm_num : 2 ≠ 0)

private lemma positiveColorWeight_five : positiveColorWeight 5 = 4 := by
  simp [positiveColorWeight, Nat.prime_five.factorization_self,
    Nat.factorization_eq_zero_of_not_dvd (by norm_num : ¬ 2 ∣ 5),
    Nat.factorization_eq_zero_of_not_dvd (by norm_num : ¬ 3 ∣ 5)]

private lemma positiveColor_one : positiveColor 1 = 0 := by
  apply Fin.ext
  simp [positiveColor, positiveColorWeight_one]

private lemma positiveColor_two : positiveColor 2 = 1 := by
  apply Fin.ext
  simp [positiveColor, positiveColorWeight_two]

private lemma positiveColor_three : positiveColor 3 = 3 := by
  apply Fin.ext
  simp [positiveColor, positiveColorWeight_three]

private lemma positiveColor_four : positiveColor 4 = 2 := by
  apply Fin.ext
  simp [positiveColor, positiveColorWeight_four]

private lemma positiveColor_five : positiveColor 5 = 4 := by
  apply Fin.ext
  simp [positiveColor, positiveColorWeight_five]

private lemma positiveColor_mul_index (n : ℕ) (hn : 0 < n) (k : Fin 5) :
    positiveColor ((k.val + 1) * n) = positiveColor n + shiftPerm k := by
  have hn0 : n ≠ 0 := Nat.ne_zero_of_lt hn
  fin_cases k
  · simp [shiftPerm]
  · simpa [shiftPerm, positiveColor_two] using positiveColor_mul_eq_add (by norm_num : 2 ≠ 0) hn0
  · simpa [shiftPerm, positiveColor_three] using
      positiveColor_mul_eq_add (by norm_num : 3 ≠ 0) hn0
  · simpa [shiftPerm, positiveColor_four] using positiveColor_mul_eq_add (by norm_num : 4 ≠ 0) hn0
  · simpa [shiftPerm, positiveColor_five] using positiveColor_mul_eq_add (by norm_num : 5 ≠ 0) hn0

/--
The positive integers can be partitioned into five pairwise disjoint sets so that,
for every positive integer `n`, one of `n, 2n, 3n, 4n, 5n` lies in each set.
-/
theorem exists_five_disjoint_sets_for_one_to_five_multiples :
    ∃ C : Fin 5 → Set ℕ,
      (∀ m : ℕ, 0 < m ↔ ∃ i, m ∈ C i) ∧
      Set.PairwiseDisjoint (Set.univ : Set (Fin 5)) C ∧
      ∀ n : ℕ, 0 < n → ∀ i : Fin 5, ∃ k : Fin 5, (k.val + 1) * n ∈ C i := by
  refine ⟨positivePart, ?_, ?_, ?_⟩
  · intro m
    constructor
    · intro hm
      exact ⟨positiveColor m, hm, rfl⟩
    · rintro ⟨i, hm, _⟩
      exact hm
  · intro i _ j _ hij
    change Disjoint (positivePart i) (positivePart j)
    rw [Set.disjoint_left]
    intro m hmi hmj
    simp only [positivePart, Set.mem_setOf_eq] at hmi hmj
    exact hij (hmi.2.symm.trans hmj.2)
  · intro n hn i
    refine ⟨shiftPerm.symm (i - positiveColor n), ?_⟩
    constructor
    · exact Nat.mul_pos (Nat.succ_pos _) hn
    · have hcolor := positiveColor_mul_index n hn (shiftPerm.symm (i - positiveColor n))
      have hcolor' :
          positiveColor (((shiftPerm.symm (i - positiveColor n)).val + 1) * n) =
            positiveColor n + (i - positiveColor n) := by
        simpa using hcolor
      simpa [positivePart, add_sub_cancel] using hcolor'

end

end Introduction
