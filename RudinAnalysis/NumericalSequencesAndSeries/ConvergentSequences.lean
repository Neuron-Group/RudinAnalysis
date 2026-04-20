import RudinAnalysis.NumericalSequencesAndSeries.Import
set_option linter.style.lambdaSyntax false

section -- 3.1 --
variable (X : Type*) [MetricSpace X]

section
variable (x y : X)

#check (dist x y : ℝ)

end

def converge (pₙ : ℕ -> X) : Prop :=
  ∃ p : X, ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, dist (pₙ n) p < ε

def converge_to (pₙ : ℕ -> X) (p : X) : Prop :=
  ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, dist (pₙ n) p < ε

end

instance : MetricSpace {x : ℝ // 0 < x} where
  eq_of_dist_eq_zero := by
    rintro ⟨x, xpos⟩ ⟨y, ypos⟩ h
    apply Subtype.ext
    simp only [dist_eq_zero, Subtype.mk.injEq] at h ⊢
    exact h

example (x : ℝ) : x - 1 < Nat.floor x := by
  exact Nat.sub_one_lt_floor x

example : ¬ converge {x : ℝ // 0 < x} (λ n ↦ ⟨1 / ↑(n + 1),
      Nat.one_div_cast_pos (Ne.symm (Nat.zero_ne_add_one n))
    ⟩) := by
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

def Ball.{u} {X : Type u} [MetricSpace X] : X -> {ε : ℝ // 0 < ε} -> Set X
  := λ p ε ↦ {s : X | dist s p < ε}

def Balls.{u} {X : Type u} [MetricSpace X] : X -> Type u
  := λ p ↦ {S : Set X // ∃ ε, S = Ball p ε}

def Ball0.{u} {X : Type u} [MetricSpace X] : X -> {ε : ℝ // 0 < ε} -> Set X
  := λ p ε ↦ (Ball p ε)\{p}

def Ball0s.{u} {X : Type u} [MetricSpace X] : X -> Type u
  := λ p ↦ {S : Set X // ∃ ε, S = Ball0 p ε}

section -- 3.2 --
variable {X : Type*} [MetricSpace X] (pₙ : ℕ -> X)

theorem converge_to_iff_ball_finite_except (p : X) : converge_to X pₙ p
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

example : ∀ p p' : X, converge_to X pₙ p ∧ converge_to X pₙ p' -> p = p' := by
  intro p p' ⟨hl, hr⟩
  sorry

end
