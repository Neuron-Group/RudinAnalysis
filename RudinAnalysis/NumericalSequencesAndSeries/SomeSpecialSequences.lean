import RudinAnalysis.NumericalSequencesAndSeries.Import
import RudinAnalysis.NumericalSequencesAndSeries.ConvergentSequences

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace SomeSpecialSequences
open ConvergentSequences MetricSpaces

section -- 3.20 --

section
universe u
variable {X : Type u}

#check ℕ

def P : ℕ -> Type u := λ n ↦
  match n with
  | Nat.zero => Set X
  | Nat.succ n => Set (P n)

def func : Π (n : ℕ), @P X n := λ n ↦
  match n with
  | Nat.zero => (∅ : Set X)
  | Nat.succ n => sorry


end

theorem tendsto_zero_one_div_pow {p : ℝ} (hp : 0 < p) :
    convergesTo ℝ (fun n ↦ 1 / ((n + 1 : ℕ) : ℝ) ^ p) 0 := by
  rw [convergesTo]
  have ht : Filter.Tendsto (fun n : ℕ ↦ (((n + 1 : ℕ) : ℝ)) ^ (-p)) Filter.atTop (nhds 0) := by
    exact (tendsto_rpow_neg_atTop hp).comp
      (tendsto_natCast_atTop_atTop.comp (Filter.tendsto_add_atTop_nat 1))
  intro ε εpos
  rcases Metric.tendsto_atTop.1 ht ε εpos with ⟨N, hN⟩
  refine ⟨N, ?_⟩
  intro n hn
  change |1 / (((n + 1 : ℕ) : ℝ) ^ p) - 0| < ε
  have hnn := hN n hn
  have hs : ((((n + 1 : ℕ) : ℝ)) ^ (-p)) = 1 / ((((n + 1 : ℕ) : ℝ)) ^ p) := by
    rw [Real.rpow_neg (by positivity : 0 ≤ (((n + 1 : ℕ) : ℝ))) p, one_div]
  rw [hs] at hnn
  simpa [Real.dist_eq] using hnn

theorem tendsto_nthRoot_const {p : ℝ} (hp : 0 < p) :
    convergesTo ℝ (λ n ↦ p ^ (1 / ((n + 1 : ℕ) : ℝ))) 1 := by
  set xₙ := λ n ↦ p ^ (1 / ((n + 1 : ℕ) : ℝ)) - 1
  suffices convergesTo ℝ xₙ 0 by
    rw [convergesTo] at this ⊢
    intro ε εpos
    rcases this ε εpos with ⟨N, hN⟩
    refine ⟨N, ?_⟩
    intro n hn
    simpa [xₙ, Real.dist_eq] using hN n hn
  have hbase : Filter.Tendsto (fun n : ℕ ↦ (1 : ℝ) / ((n + 1 : ℕ) : ℝ)) Filter.atTop (nhds 0) := by
    have h := tendsto_zero_one_div_pow (p := 1) zero_lt_one
    rw [convergesTo] at h
    simpa [one_div] using (Metric.tendsto_atTop.mpr h)
  have hpow : Filter.Tendsto (fun n : ℕ ↦ p ^ ((1 : ℝ) / ((n + 1 : ℕ) : ℝ)))
      Filter.atTop (nhds (p ^ (0 : ℝ))) := by
    exact (Real.continuousAt_const_rpow (show p ≠ 0 by linarith)).tendsto.comp hbase
  have hx : Filter.Tendsto xₙ Filter.atTop (nhds (p ^ (0 : ℝ) - 1)) := by
    simpa [xₙ] using hpow.sub (tendsto_const_nhds : Filter.Tendsto (fun _ : ℕ ↦ (1 : ℝ)) Filter.atTop (nhds 1))
  rw [convergesTo]
  simpa using (Metric.tendsto_atTop.mp hx)

theorem tendsto_nthRoot_nat :
  convergesTo ℝ (fun n ↦ ((n + 1 : ℕ) : ℝ) ^ (1 / ((n + 1 : ℕ) : ℝ))) 1 := by
  sorry

theorem tendsto_pow_div_geom {p : ℝ} (hp : 0 < p) {α : ℝ} :
  convergesTo ℝ (fun n ↦ ((n + 1 : ℕ) : ℝ) ^ α / (1 + p) ^ (n + 1 : ℕ)) 0 := by
  sorry

theorem tendsto_pow_of_abs_lt_one {x : ℝ} (hx : |x| < 1) :
  convergesTo ℝ (fun n ↦ x ^ n) 0 := by
  sorry

end

end SomeSpecialSequences
