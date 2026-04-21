import RudinAnalysis.NumericalSequencesAndSeries.Import

set_option linter.style.lambdaSyntax false

namespace ConvergentSequences

section -- 3.1 --
variable (X : Type*) [MetricSpace X]

section
variable (x y : X)

#check (dist x y : ℝ)

end

def converge_to (pₙ : ℕ -> X) (p : X) : Prop :=
  ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, dist (pₙ n) p < ε

def Converge (pₙ : ℕ -> X) : Prop :=
  ∃ p : X, converge_to X pₙ p

def converge (pₙ : ℕ -> X) : Type _ :=
  Σ' p : X, converge_to X pₙ p

#check converge

def lim {X : Type*} [MetricSpace X] : (pₙ : ℕ -> X) -> (h : converge X pₙ) -> X
  := λ _ h ↦ h.1

end

instance : MetricSpace {x : ℝ // 0 < x} where
  eq_of_dist_eq_zero := by
    rintro ⟨x, xpos⟩ ⟨y, ypos⟩ h
    apply Subtype.ext
    simp only [dist_eq_zero, Subtype.mk.injEq] at h ⊢
    exact h

example (x : ℝ) : x - 1 < Nat.floor x := by
  exact Nat.sub_one_lt_floor x

example : ¬ Nonempty (converge {x : ℝ // 0 < x}
    (λ n ↦ ⟨1 / ↑(n + 1),
      Nat.one_div_cast_pos (Ne.symm (Nat.zero_ne_add_one n))⟩)) := by
  intro h
  rcases h with ⟨p, hp⟩
  have ppos : 0 < (p : ℝ) := p.2
  have hε : 0 < (p : ℝ) / 2 := half_pos ppos
  rcases hp ((p : ℝ) / 2) hε with ⟨N0, hN0⟩
  rcases exists_nat_gt (2 / (p : ℝ)) with ⟨M, hM⟩
  let N : ℕ := max N0 M
  have hNdist : ∀ n ≥ N,
      dist
        ⟨1 / ↑(n + 1), Nat.one_div_cast_pos (Ne.symm (Nat.zero_ne_add_one n))⟩
        p < (p : ℝ) / 2 := by
    intro n hn
    exact hN0 n (Nat.le_trans (Nat.le_max_left _ _) hn)
  have hNgt : ((N : ℝ) : ℝ) > 2 / (p : ℝ) := by
    have : (M : ℝ) ≤ (N : ℝ) := by
      exact Nat.cast_le.mpr (Nat.le_max_right _ _)
    exact lt_of_lt_of_le hM this
  have hNgt' : 2 / (p : ℝ) < ((N : ℝ) + 1) := by
    linarith [hNgt]
  have hsmall : 1 / ((N : ℝ) + 1) < (p : ℝ) / 2 := by
    have hpos : 0 < ((N : ℝ) + 1) := by
      exact add_pos_of_nonneg_of_pos (Nat.cast_nonneg _) zero_lt_one
    have hpos' : 0 < 2 / (p : ℝ) := by
      exact div_pos zero_lt_two ppos
    have h' : ((N : ℝ) + 1)⁻¹ < (2 / (p : ℝ))⁻¹ :=
      (inv_lt_inv₀ hpos hpos').2 hNgt'
    have : 1 / (2 / (p : ℝ)) = (p : ℝ) / 2 := by
      field_simp [ppos]
    simpa [this] using h'
  have hdist : dist
      ⟨1 / ↑(N + 1), Nat.one_div_cast_pos (Ne.symm (Nat.zero_ne_add_one N))⟩
      p < (p : ℝ) / 2 := hNdist N (Nat.le_refl _)
  have hneg : 1 / ((N : ℝ) + 1) - (p : ℝ) < 0 := by
    nlinarith [hsmall]
  have hgt : (p : ℝ) / 2 < (p : ℝ) - 1 / ((N : ℝ) + 1) := by
    nlinarith [hsmall]
  have hlt : (p : ℝ) - 1 / ((N : ℝ) + 1) < (p : ℝ) / 2 := by
    have hdist' : |1 / ((N : ℝ) + 1) - (p : ℝ)| < (p : ℝ) / 2 := by
      simpa [dist] using hdist
    have hnonpos : 1 / ((N : ℝ) + 1) - (p : ℝ) ≤ 0 := le_of_lt hneg
    have hlt' : -(1 / ((N : ℝ) + 1) - (p : ℝ)) < (p : ℝ) / 2 := by
      rwa [abs_of_nonpos hnonpos] at hdist'
    nlinarith
  linarith

def Ball {X : Type*} [MetricSpace X] : X -> {ε : ℝ // 0 < ε} -> Set X
  := λ p ε ↦ {s : X | dist s p < ε}

def Balls.{u} {X : Type u} [MetricSpace X] : X -> Type u
  := λ p ↦ {S : Set X // ∃ ε, S = Ball p ε}

def Ball0 {X : Type*} [MetricSpace X] : X -> {ε : ℝ // 0 < ε} -> Set X
  := λ p ε ↦ (Ball p ε)\{p}

def Ball0s.{u} {X : Type u} [MetricSpace X] : X -> Type u
  := λ p ↦ {S : Set X // ∃ ε, S = Ball0 p ε}

def Bounded {X : Type*} [MetricSpace X] (s : Set X) : Prop :=
  ∃ c : X, ∃ R > 0, ∀ x ∈ s, dist x c < R

def limit_point {X : Type*} [MetricSpace X] (p : X) (S : Set X) : Prop :=
  ∀ b : Balls p, (b.val ∩ S).Nonempty

section -- 3.2 --
variable {X : Type*} [MetricSpace X]

def is_bounded (pₙ : ℕ -> X) : Prop
  := Bounded (Set.range pₙ)

-- (a) --
theorem converge_to_iff_ball_finite_except (pₙ : ℕ -> X) (p : X) : converge_to X pₙ p
  <-> ∀ U : Balls p, ∃ ex_idx : Finset ℕ,
    ∀ n ∉ ex_idx, pₙ n ∈ U.val := by
      constructor
      · intro hcv ⟨U, ⟨⟨ε, εpos⟩, Udf⟩⟩
        simp only [Ball] at Udf ⊢
        specialize hcv ε εpos
        obtain ⟨N, Nh⟩ := hcv
        set ex_idx := Finset.range N with exdf
        use ex_idx
        intro n nh
        simp only [exdf, Finset.mem_range, not_lt] at nh
        specialize Nh n nh
        rw [Udf]
        simp only [Set.mem_setOf_eq]
        exact Nh
      · intro h ε εpos
        set ε' := (⟨ε, εpos⟩ : {ε : ℝ // 0 < ε}) with εdf
        set b : Balls p := ⟨Ball p ε', (by
          use ε'
        )⟩ with bdf
        specialize h b
        obtain ⟨ex_set, exh⟩ := h
        obtain ⟨N, Nh⟩ := Finset.exists_nat_subset_range ex_set
        have : ∀ n ≥ N, n ∉ ex_set := by
          intro n nge
          have : n ∉ Finset.range N := by
            simp only [Finset.mem_range, not_lt]; exact nge
          exact Finset.notMem_mono Nh this
        use N; intro n nge;
        specialize exh n (this _ nge)
        simp only [Ball, bdf, εdf, Set.mem_setOf_eq] at exh
        exact exh

-- (b) --
theorem converge_to_unique (pₙ : ℕ -> X) :
  ∀ p p' : X, converge_to X pₙ p ∧ converge_to X pₙ p' -> p = p' := by
    intro p p' ⟨hl, hr⟩
    have : ∀ ε > 0, dist p p' < ε := by
      intro ε εpos
      specialize hl (ε / 2) (by nlinarith)
      specialize hr (ε / 2) (by nlinarith)
      obtain ⟨N₁, h₁⟩ := hl
      obtain ⟨N₂, h₂⟩ := hr
      set n := max N₁ N₂ with Ndf
      specialize h₁ n (by grind)
      specialize h₂ n (by grind)
      calc
        dist p p' ≤ dist (pₙ n) p + dist (pₙ n) p' := by
          exact dist_triangle_left p p' (pₙ n)
        _ < _ := by
          linarith
    have : dist p p' = 0 := by
      by_contra h
      push Not at h
      have nneg : 0 ≤ dist p p' := dist_nonneg
      have pos : 0 < dist p p' := by grind
      specialize this ((dist p p') / 2) (by nlinarith)
      grind
    exact dist_eq_zero.mp this

-- (c) --
theorem convergent_implies_bounded (pₙ : ℕ -> X) : converge X pₙ -> is_bounded pₙ := by
  intro hconv
  rcases hconv with ⟨p, hp⟩
  specialize hp 1 zero_lt_one
  rcases hp with ⟨N, hN⟩
  let R0 : ℝ := (Finset.range (N + 1)).sup'
    Finset.nonempty_range_add_one
    (λ n ↦ dist (pₙ n) p)
  use p
  use max R0 1 + 1
  constructor
  · nlinarith [le_max_right R0 1]
  · intro x hx
    rcases hx with ⟨n, rfl⟩
    by_cases hn : n < N + 1
    · have hR0 : dist (pₙ n) p ≤ R0 := by
        have hmem : n ∈ Finset.range (N + 1) := by
          simpa using hn
        simpa [R0] using
          (Finset.le_sup' (s := Finset.range (N + 1))
            (f := λ n ↦ dist (pₙ n) p) hmem)
      nlinarith [hR0, le_max_left R0 1]
    · have hNle : N ≤ n := by
        exact Nat.le_trans (Nat.le_succ N) (Nat.le_of_not_gt hn)
      have htail : dist (pₙ n) p < 1 := hN n hNle
      nlinarith [htail, le_max_right R0 1]

-- (d) --
open Classical in
theorem exists_seq_of_limit_point : ∀ E : Set X, ∀ p : X, limit_point p E
  -> ∃ pₙ : ℕ -> X, (∀ n, pₙ n ∈ E) ∧ converge_to X pₙ p := by
    intro E p ph
    have : ∀ n : ℕ, ∃ p₀ ∈ E, dist p₀ p < 1 / (↑n + 1) := by
      intro n
      set ball := Ball p ⟨1 / (↑n + 1), Nat.one_div_pos_of_nat⟩
        with ball_df
      specialize ph ⟨ball,⟨
        ⟨1 / (↑n + 1), Nat.one_div_pos_of_nat⟩,
        ball_df
      ⟩⟩
      simp only [Set.Nonempty, Set.mem_inter_iff] at ph
      rcases ph with ⟨p₀, p₀inBall, p₀inE⟩
      use p₀
      constructor
      · exact p₀inE
      · ring_nf
        rw [ball_df] at p₀inBall
        simp only [Ball, one_div, Set.mem_setOf_eq] at p₀inBall
        rw [add_comm]
        exact p₀inBall
    choose pₙ hpₙ using this
    use pₙ
    constructor
    · intro n
      specialize hpₙ n
      exact hpₙ.left
    · intro ε εpos
      obtain ⟨N, Nh⟩ : ∃ N : ℕ, 1 / ε - 1 < ↑N
        := exists_nat_gt (1 / ε - 1)
      use N
      intro n nh
      specialize hpₙ n
      rcases hpₙ with ⟨_, hpₙ⟩
      calc
        _ < 1 / (↑n + 1) := hpₙ
        _ < ε := by
          have : 1 / ε - 1 < ↑n := by
            have : (n : ℝ) ≥ ↑N := Nat.cast_le.mpr nh
            linarith
          field_simp at this ⊢
          linarith

end

section -- 3.3 --
variable (sₙ tₙ : ℕ -> ℂ) (s t : ℂ)
  (cvs : converge_to ℂ sₙ s) (cvt : converge_to ℂ tₙ t)

-- (a) --
theorem cnv_add' (sₙ tₙ : ℕ -> ℂ) (s t : ℂ)
  (cvs : converge_to ℂ sₙ s) (cvt : converge_to ℂ tₙ t) :
  converge_to ℂ (sₙ + tₙ) (s + t) := by
    intro ε εpos
    set ε' := ε / 2 with ε'df
    have ε'pos : 0 < ε' := by linarith
    specialize cvs ε' ε'pos
    specialize cvt ε' ε'pos
    rcases cvs with ⟨Ns, hNs⟩
    rcases cvt with ⟨Nt, hNt⟩
    set N := max Ns Nt with Ndf
    use N
    intro n ngeN
    rw [Ndf] at ngeN
    specialize hNs n ((Nat.le_max_left Ns Nt).trans ngeN)
    specialize hNt n ((Nat.le_max_right Ns Nt).trans ngeN)
    -- simp only [aₙ]
    have : dist ((sₙ + tₙ) n) (s + t) ≤ dist (sₙ n) s + dist (tₙ n) t := by
      exact dist_add_add_le (sₙ n) (tₙ n) s t
    calc
      _ < ε' + ε' := by linarith
      _ = _ := by
        rw [ε'df]
        linarith

theorem cnv_add {sₙ tₙ : ℕ -> ℂ}
  (cvs : converge ℂ sₙ) (cvt : converge ℂ tₙ) :
  lim (sₙ + tₙ) ⟨
    cvs.1 + cvt.1,
    cnv_add' sₙ tₙ cvs.1 cvt.1 cvs.2 cvt.2
  ⟩ = lim sₙ cvs + lim tₙ cvt
  := by simp only [lim]

-- (b) --
theorem cnv_const_mul' (sₙ : ℕ -> ℂ) (s : ℂ) (cvs : converge_to ℂ sₙ s)
  (c : ℂ) : converge_to ℂ (c • sₙ) (c * s) := by
    intro ε εpos
    by_cases c0 : c = 0
    · simp only [ge_iff_le, c0, Pi.smul_apply, smul_eq_mul, zero_mul, dist_self]
      use 0
      simp only [zero_le, forall_const]
      exact εpos
    · push Not at c0
      set ε' := ε / ‖c‖ with ε'df
      have ε'pos : 0 < ε' := by
        rw [ε'df]
        field_simp
        simp only [zero_mul]
        exact εpos
      specialize cvs ε' ε'pos
      rcases cvs with ⟨N, Nh⟩
      use N; intro n nh
      specialize Nh n nh
      calc
        _ = ‖c‖ * dist (sₙ n) s := by
          have d1 := Complex.dist_eq (sₙ n) s
          have d2 := Complex.dist_eq (c * sₙ n) (c * s)
          simp only [Pi.smul_apply, smul_eq_mul, d2, d1]
          calc
            _ = ‖c * (sₙ n - s)‖ := by
              ring_nf
            _ = _ := Complex.norm_mul c (sₙ n - s)
        _ < _ := by
          rw [ε'df] at Nh
          field_simp at Nh
          linarith

theorem cnv_const_mul {sₙ : ℕ -> ℂ} (cvs : converge ℂ sₙ) {c : ℂ} :
  lim (c • sₙ) ⟨c * cvs.1, cnv_const_mul' sₙ cvs.1 cvs.2 c⟩ = c * lim sₙ cvs
    := by simp only [lim]

instance : HAdd ℂ (ℕ → ℂ) (ℕ → ℂ) where
  hAdd := λ c sₙ ↦ λ n ↦ c + sₙ n

theorem cnv_const_add' (sₙ : ℕ -> ℂ) (s : ℂ) (cvs : converge_to ℂ sₙ s)
  (c : ℂ) : converge_to ℂ (c + sₙ) (c + s) := by
    intro ε εpos
    rcases cvs ε εpos with ⟨N, Nh⟩
    use N; intro n nh
    specialize Nh n nh
    have : (c + sₙ) n = c + sₙ n := by
      unfold HAdd.hAdd
      unfold instHAddComplexForallNat_rudinAnalysis
      simp
      rfl
    simp only [this, dist_add_left, gt_iff_lt]
    exact Nh

theorem cnv_const_add {sₙ : ℕ -> ℂ} (cvs : converge ℂ sₙ) {c : ℂ} :
  lim (c + sₙ) ⟨c + cvs.1, cnv_const_add' sₙ cvs.1 cvs.2 c⟩ = c + lim sₙ cvs
    := by simp only [lim]

-- (c) --
example :
  converge_to ℂ (sₙ * tₙ) (s * t) := by
    have := cnv_const_add' (-(s * t) + sₙ * tₙ) 0

    intro ε εpos
    set ε' := √ε with ε'df
    have ε'pos : 0 < ε' := Real.sqrt_pos_of_pos εpos
    specialize cvs ε' ε'pos
    specialize cvt ε' ε'pos
    rcases cvs with ⟨Ns, hNs⟩
    rcases cvt with ⟨Nt, hNt⟩
    set N := max Ns Nt with Ndf
    use N; intro n hn
    specialize hNs n ((Nat.le_max_left Ns Nt).trans hn)
    specialize hNt n ((Nat.le_max_right Ns Nt).trans hn)


    sorry

end

end ConvergentSequences
