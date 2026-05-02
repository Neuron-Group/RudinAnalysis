import RudinAnalysis.NumericalSequencesAndSeries.Import
import RudinAnalysis.NumericalSequencesAndSeries.Subsequences
import RudinAnalysis.NumericalSequencesAndSeries.ConvergentSequences
import Mathlib.Data.EReal.Basic
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Instances.EReal.Lemmas
import Mathlib.Topology.Bases

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace UpperAndLowerLimits
open Subsequences ConvergentSequences MetricSpaces

theorem convergesTo_iff_tendsto_atTop {X : Type*} [MetricSpace X] (u : ℕ → X) (p : X) :
  convergesTo X u p ↔ Filter.Tendsto u Filter.atTop (nhds p) := by
  simpa [convergesTo] using (Metric.tendsto_atTop :
    Filter.Tendsto u Filter.atTop (nhds p) ↔ ∀ ε > 0, ∃ N, ∀ n ≥ N, dist (u n) p < ε)
    |>.symm

section -- 3.15 --

/-- A sequence of real numbers tends to +∞ (Definition 3.15). -/
def tendsToPosInf (sₙ : ℕ → ℝ) : Prop :=
  ∀ M : ℝ, ∃ N : ℕ, ∀ n ≥ N, sₙ n ≥ M

/-- A sequence of real numbers tends to -∞ (Definition 3.15). -/
def tendsToNegInf (sₙ : ℕ → ℝ) : Prop :=
  ∀ M : ℝ, ∃ N : ℕ, ∀ n ≥ N, sₙ n ≤ M

end

section -- 3.16 --

/-- The set of extended subsequential limits of a real sequence (Definition 3.16).
    This includes all real subsequential limits as well as ±∞ when appropriate. -/
noncomputable def extendedSubsequentialLimits (sₙ : ℕ → ℝ) : Set EReal := by
  classical
    let E : Set ℝ := subsequentialLimits sₙ
    exact {x : EReal | ∃ (r : ℝ), r ∈ E ∧ x = (r : EReal)}
      ∪ (if ∃ (pnₖ : SubSeq sₙ), tendsToPosInf (SubSeq.val sₙ pnₖ) then {⊤} else ∅)
      ∪ (if ∃ (pnₖ : SubSeq sₙ), tendsToNegInf (SubSeq.val sₙ pnₖ) then {⊥} else ∅)

/-- The upper limit (limsup) of a real sequence (Definition 3.16). -/
noncomputable def upperLimit (sₙ : ℕ → ℝ) : EReal :=
  ⨆ x ∈ extendedSubsequentialLimits sₙ, x

/-- The lower limit (liminf) of a real sequence (Definition 3.16). -/
noncomputable def lowerLimit (sₙ : ℕ → ℝ) : EReal :=
  ⨅ x ∈ extendedSubsequentialLimits sₙ, x

end

section -- 3.17 --

theorem mem_extendedSubsequentialLimits_iff_mapClusterPt (sₙ : ℕ → ℝ) (x : EReal) :
  x ∈ extendedSubsequentialLimits sₙ ↔ MapClusterPt x Filter.atTop (fun n ↦ (sₙ n : EReal)) := by
  classical
  constructor
  · intro hx
    rcases hx with hx | hx
    · rcases hx with hx | hx
      · rcases hx with ⟨r, ⟨pnₖ, hconv⟩, rfl⟩
        rw [convergesTo_iff_tendsto_atTop] at hconv
        have hcoe : Filter.Tendsto ((fun n ↦ (sₙ n : EReal)) ∘ pnₖ.idx) Filter.atTop (nhds (r : EReal)) := by
          simpa [SubSeq.val] using (EReal.tendsto_coe).2 hconv
        exact (Filter.Tendsto.mapClusterPt hcoe).of_comp pnₖ.strictMono_idx.tendsto_atTop
      · by_cases hpos : ∃ (pnₖ : SubSeq sₙ), tendsToPosInf (SubSeq.val sₙ pnₖ)
        · simp [extendedSubsequentialLimits, hpos] at hx
          subst hx
          rcases hpos with ⟨pnₖ, hpnₖ⟩
          have ht : Filter.Tendsto ((fun n ↦ (sₙ n : EReal)) ∘ pnₖ.idx) Filter.atTop (nhds (⊤ : EReal)) := by
            rw [EReal.tendsto_nhds_top_iff_real]
            intro y
            rw [tendsToPosInf] at hpnₖ
            rcases hpnₖ (y + 1) with ⟨N, hN⟩
            exact Filter.mem_atTop_sets.2 ⟨N, fun n hn ↦ by
              show (y : EReal) < ((fun n ↦ (sₙ n : EReal)) ∘ pnₖ.idx) n
              have hy : y < sₙ (pnₖ.idx n) := by
                exact lt_of_lt_of_le (by linarith : y < y + 1) (hN n hn)
              simpa [SubSeq.val] using hy⟩
          exact (Filter.Tendsto.mapClusterPt ht).of_comp pnₖ.strictMono_idx.tendsto_atTop
        · simp [extendedSubsequentialLimits, hpos] at hx
    · by_cases hneg : ∃ (pnₖ : SubSeq sₙ), tendsToNegInf (SubSeq.val sₙ pnₖ)
      · simp [extendedSubsequentialLimits, hneg] at hx
        subst hx
        rcases hneg with ⟨pnₖ, hpnₖ⟩
        have ht : Filter.Tendsto ((fun n ↦ (sₙ n : EReal)) ∘ pnₖ.idx) Filter.atTop (nhds (⊥ : EReal)) := by
          rw [EReal.tendsto_nhds_bot_iff_real]
          intro y
          rw [tendsToNegInf] at hpnₖ
          rcases hpnₖ (y - 1) with ⟨N, hN⟩
          exact Filter.mem_atTop_sets.2 ⟨N, fun n hn ↦ by
            show ((fun n ↦ (sₙ n : EReal)) ∘ pnₖ.idx) n < (y : EReal)
            have hy : sₙ (pnₖ.idx n) < y := by
              exact lt_of_le_of_lt (hN n hn) (by linarith : y - 1 < y)
            simpa [SubSeq.val] using hy⟩
        exact (Filter.Tendsto.mapClusterPt ht).of_comp pnₖ.strictMono_idx.tendsto_atTop
      · simp [extendedSubsequentialLimits, hneg] at hx
  · intro hx
    have hne : (nhds x ⊓ Filter.map (fun n ↦ (sₙ n : EReal)) Filter.atTop).NeBot := hx
    obtain ⟨φ, hφmono, hφtendsto⟩ := Filter.subseq_tendsto_of_neBot hne
    by_cases htop : x = ⊤
    · apply Or.inl
      apply Or.inr
      have : ∃ (pnₖ : SubSeq sₙ), tendsToPosInf (SubSeq.val sₙ pnₖ) := by
        let pnₖ : SubSeq sₙ := ⟨φ, hφmono⟩
        refine ⟨pnₖ, ?_⟩
        rw [tendsToPosInf]
        intro M
        have ht : Filter.Tendsto ((fun n ↦ (sₙ n : EReal)) ∘ φ) Filter.atTop (nhds (⊤ : EReal)) := by
          simpa [htop] using hφtendsto
        rw [EReal.tendsto_nhds_top_iff_real] at ht
        rcases Filter.mem_atTop_sets.1 (ht M) with ⟨N, hN⟩
        exact ⟨N, fun n hn ↦ by
          have hlt : (M : EReal) < ((fun n ↦ (sₙ n : EReal)) ∘ φ) n := hN n hn
          simpa [SubSeq.val] using le_of_lt hlt⟩
      simpa [extendedSubsequentialLimits, this, htop]
    · by_cases hbot : x = ⊥
      · apply Or.inr
        have : ∃ (pnₖ : SubSeq sₙ), tendsToNegInf (SubSeq.val sₙ pnₖ) := by
          let pnₖ : SubSeq sₙ := ⟨φ, hφmono⟩
          refine ⟨pnₖ, ?_⟩
          rw [tendsToNegInf]
          intro M
          have ht : Filter.Tendsto ((fun n ↦ (sₙ n : EReal)) ∘ φ) Filter.atTop (nhds (⊥ : EReal)) := by
            simpa [hbot] using hφtendsto
          rw [EReal.tendsto_nhds_bot_iff_real] at ht
          rcases Filter.mem_atTop_sets.1 (ht M) with ⟨N, hN⟩
          exact ⟨N, fun n hn ↦ by
            have hlt : ((fun n ↦ (sₙ n : EReal)) ∘ φ) n < (M : EReal) := hN n hn
            simpa [SubSeq.val] using le_of_lt hlt⟩
        simpa [extendedSubsequentialLimits, this, hbot]
      · apply Or.inl
        apply Or.inl
        let r : ℝ := x.toReal
        have hxcoe : x = (r : EReal) := by
          rw [show r = x.toReal by rfl]
          exact (EReal.coe_toReal htop hbot).symm
        let pnₖ : SubSeq sₙ := ⟨φ, hφmono⟩
        have hconv : convergesTo ℝ pnₖ r := by
          rw [convergesTo_iff_tendsto_atTop]
          rw [← EReal.tendsto_coe]
          simpa [hxcoe, SubSeq.val] using hφtendsto
        exact ⟨r, ⟨pnₖ, hconv⟩, hxcoe⟩

/-- Theorem 3.17(a): The upper limit belongs to the set of extended subsequential limits. -/
theorem upperLimit_mem_extendedSubsequentialLimits (sₙ : ℕ → ℝ) :
  upperLimit sₙ ∈ extendedSubsequentialLimits sₙ := by
  let S : Set EReal := extendedSubsequentialLimits sₙ
  have hEqSet : S = {x : EReal | MapClusterPt x Filter.atTop (fun n ↦ (sₙ n : EReal))} := by
    ext x
    simp [S, mem_extendedSubsequentialLimits_iff_mapClusterPt]
  have hclosed : IsClosed S := by
    have hclosed' : IsClosed {x : EReal | MapClusterPt x Filter.atTop (λ n ↦ (sₙ n : EReal))} := by
      simpa [mapClusterPt_def] using
        (isClosed_setOf_clusterPt :
          IsClosed {x : EReal | ClusterPt x (Filter.map (fun n ↦ (sₙ n : EReal)) Filter.atTop)})
    simpa [hEqSet] using hclosed'
  have hnonempty : S.Nonempty := by
    rcases (isCompact_univ : IsCompact (Set.univ : Set EReal)).exists_mapClusterPt
      (f := Filter.atTop) (u := fun n ↦ (sₙ n : EReal)) (by simp) with ⟨x, -, hx⟩
    exact ⟨x, (mem_extendedSubsequentialLimits_iff_mapClusterPt sₙ x).2 hx⟩
  have hup : upperLimit sₙ = sSup S := by
    unfold upperLimit
    simpa [S] using (sSup_image (s := extendedSubsequentialLimits sₙ) (f := id)).symm
  have hs : sSup S ∈ S := hclosed.sSup_mem hnonempty
  rw [hup]
  exact hs

/-- Theorem 3.17(b): If x > s*, then eventually sₙ < x. -/
theorem upperLimit_eventually_lt (sₙ : ℕ → ℝ) {x : ℝ} (hx : (x : EReal) > upperLimit sₙ) :
  ∃ N : ℕ, ∀ n ≥ N, sₙ n < x := by
  unfold upperLimit at hx
  sorry

/-- Theorem 3.17, uniqueness part: s* is the only number with properties (a) and (b). -/
theorem upperLimit_unique (sₙ : ℕ → ℝ) (y : EReal)
    (h_mem : y ∈ extendedSubsequentialLimits sₙ)
    (h_eventually : ∀ {x : ℝ}, (x : EReal) > y → ∃ N : ℕ, ∀ n ≥ N, sₙ n < x) :
    y = upperLimit sₙ := by
  sorry

/-- Analogous result for the lower limit: lower limit is in the extended subsequential limits. -/
theorem lowerLimit_mem_extendedSubsequentialLimits (sₙ : ℕ → ℝ) :
  lowerLimit sₙ ∈ extendedSubsequentialLimits sₙ := by
  sorry

/-- Analogous result for the lower limit: if x < s_*, then eventually sₙ > x. -/
theorem lowerLimit_eventually_gt (sₙ : ℕ → ℝ) {x : ℝ} (hx : (x : EReal) < lowerLimit sₙ) :
  ∃ N : ℕ, ∀ n ≥ N, sₙ n > x := by
  sorry

/-- Analogous result for the lower limit: uniqueness. -/
theorem lowerLimit_unique (sₙ : ℕ → ℝ) (y : EReal)
    (h_mem : y ∈ extendedSubsequentialLimits sₙ)
    (h_eventually : ∀ {x : ℝ}, (x : EReal) < y → ∃ N : ℕ, ∀ n ≥ N, sₙ n > x) :
    y = lowerLimit sₙ := by
  sorry

end

section -- 3.18 --

/-- Theorem 3.18(c): A real-valued sequence converges to s
    iff limsup = liminf = s. -/
theorem convergent_iff_upperLimit_eq_lowerLimit (sₙ : ℕ → ℝ) (s : ℝ) :
  convergesTo ℝ sₙ s ↔ upperLimit sₙ = (s : EReal) ∧ lowerLimit sₙ = (s : EReal) := by
  sorry

/-- Example 3.18(a): For a sequence whose range contains all rationals,
    limsup = +∞ and liminf = -∞. (Skeleton) -/
theorem example_rational_sequence_limsup_liminf (sₙ : ℕ → ℝ)
    (h_range : ∀ q : ℚ, (q : ℝ) ∈ Set.range sₙ) :
    upperLimit sₙ = ⊤ ∧ lowerLimit sₙ = ⊥ := by
  sorry

/-- Example 3.18(b): For sₙ = (-1)^n / (1 + 1/n), limsup = 1, liminf = -1. (Skeleton) -/
theorem example_alternating_limsup_liminf :
    let sₙ : ℕ → ℝ := λ n ↦ ((-1 : ℝ) ^ n) / (1 + 1 / (↑n + 1))
    upperLimit sₙ = (1 : EReal) ∧ lowerLimit sₙ = (-1 : EReal) := by
  intro sₙ
  sorry

end

section -- 3.19 --

/-- Theorem 3.19: If sₙ ≤ tₙ eventually, then liminf sₙ ≤ liminf tₙ
    and limsup sₙ ≤ limsup tₙ. -/
theorem limsup_le_limsup_of_eventually_le (sₙ tₙ : ℕ → ℝ) (h : ∃ N : ℕ, ∀ n ≥ N, sₙ n ≤ tₙ n) :
  upperLimit sₙ ≤ upperLimit tₙ := by
  sorry

/-- Theorem 3.19: liminf part. -/
theorem liminf_le_liminf_of_eventually_le (sₙ tₙ : ℕ → ℝ) (h : ∃ N : ℕ, ∀ n ≥ N, sₙ n ≤ tₙ n) :
  lowerLimit sₙ ≤ lowerLimit tₙ := by
  sorry

end

end UpperAndLowerLimits
