import RudinAnalysis.TheRealAndComplexNumberSystems.Import

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
  --
  -- rewrite p as a fraction
  rw [← num_div_den p] at hp
  --
  -- handle with squre and denominator
  rw [div_pow] at hp
  field_simp at hp
  --
  -- obtain the interger equation (follow the inj map on ℚ)
  have h_int_eq : (p.num : ℤ) ^ 2 = 2 * (p.den : ℤ) ^ 2 := by
    apply Int.cast_injective (α := ℚ)
    -- simp only [Int.cast_pow, Int.cast_mul, Int.cast_ofNat, Int.cast_natCast] at hp ⊢
    push_cast
    rw [mul_comm]
    exact hp
  --
  -- transform to real number
  let m : ℕ := p.den
  let n : ℕ := p.num.natAbs
  have h_nat_eq : 2 * m ^ 2 = n ^ 2 := by
    rw [← Int.natAbs_sq] at h_int_eq          -- h_int_eq : (n : ℤ)^2 = 2 * (m : ℤ)^2
    exact_mod_cast h_int_eq.symm
  --
  -- denominator is not zero
  have h_m_ne_zero : m ≠ 0 := p.den_nz
  --
  -- contradict with sqrt2_irrational''
  exact sqrt2_irrational'' ⟨m, n, h_nat_eq, h_m_ne_zero⟩

end

end Introduction
