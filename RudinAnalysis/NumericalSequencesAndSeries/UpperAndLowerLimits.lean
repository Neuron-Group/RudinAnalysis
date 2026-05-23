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
open Subsequences ConvergentSequences MetricSpaces Function Set

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

theorem le_upperLimit_of_mem_extendedSubsequentialLimits (sₙ : ℕ → ℝ) {s : EReal}
    (hs : s ∈ extendedSubsequentialLimits sₙ) :
    s ≤ upperLimit sₙ := by
  unfold upperLimit
  have h₁ : s ≤ ⨆ _ : s ∈ extendedSubsequentialLimits sₙ, s := by
    exact le_iSup_of_le hs le_rfl
  exact le_trans h₁ (le_iSup (fun y ↦ ⨆ _ : y ∈ extendedSubsequentialLimits sₙ, y) s)

theorem mem_extendedSubsequentialLimits_of_subseq (sₙ : ℕ → ℝ) (pnₖ : SubSeq sₙ) {s : EReal}
    (hs : s ∈ extendedSubsequentialLimits (SubSeq.val sₙ pnₖ)) :
    s ∈ extendedSubsequentialLimits sₙ := by
  apply (mem_extendedSubsequentialLimits_iff_mapClusterPt sₙ s).2
  have hs' : MapClusterPt s Filter.atTop (((fun n ↦ (sₙ n : EReal)) ∘ pnₖ.idx)) := by
    simpa [SubSeq.val] using
      (mem_extendedSubsequentialLimits_iff_mapClusterPt (SubSeq.val sₙ pnₖ) s).1 hs
  exact hs'.of_comp pnₖ.strictMono_idx.tendsto_atTop

theorem le_of_forall_le_of_mem_extendedSubsequentialLimits (u : ℕ → ℝ) {x : ℝ} {s : EReal}
    (hu : ∀ n : ℕ, x ≤ u n) (hs : s ∈ extendedSubsequentialLimits u) :
    (x : EReal) ≤ s := by
  let S : Set EReal := Set.Ici (x : EReal)
  have hclosed : IsClosed S := isClosed_Ici
  have hcluster : MapClusterPt s Filter.atTop (fun n ↦ (u n : EReal)) := by
    exact (mem_extendedSubsequentialLimits_iff_mapClusterPt u s).1 hs
  have hmem : ∀ᶠ n in Filter.atTop, (fun n ↦ (u n : EReal)) n ∈ S := by
    exact Filter.Eventually.of_forall <| fun n ↦ by
      change (x : EReal) ≤ (u n : EReal)
      exact_mod_cast hu n
  simpa [S] using hclosed.mem_of_mapClusterPt hcluster hmem

/-- Theorem 3.17(b): If x > s*, then eventually sₙ < x. -/
theorem upperLimit_eventually_lt (sₙ : ℕ → ℝ) {x : ℝ} (hx : (x : EReal) > upperLimit sₙ) :
  ∃ N : ℕ, ∀ n ≥ N, sₙ n < x := by
  unfold upperLimit at hx
  have hx : ∀ s ∈ extendedSubsequentialLimits sₙ, s < x
    := by
      intro s hs
      exact lt_of_le_of_lt
        (le_upperLimit_of_mem_extendedSubsequentialLimits sₙ hs)
        hx
  by_contra hyp; push Not at hyp
  contrapose! hx
  choose f₀ hf₀ using hyp
  set f : ℕ -> ℕ
    := Nat.rec (f₀ 0) (λ _ last ↦ last.succ |> f₀)
  have : StrictMono f := by
    refine strictMono_nat_of_lt_succ ?_
    intro n
    have hf : f n + 1 ≤ f₀ (f n + 1) := (hf₀ (f n + 1)).1
    simpa [f] using hf
  set primitive_sseq : SubSeq sₙ := SubSeq.mk f this
  have primitive_sseq_ge_x :
    ∀ n : ℕ, x ≤ SubSeq.val sₙ primitive_sseq n := by
      intro n
      induction n with
      | zero =>
          exact (hf₀ 0).2
      | succ n hn =>
          exact by
            have hx' : x ≤ sₙ (f₀ (f n + 1)) := (hf₀ (f n + 1)).2
            simpa [SubSeq.val, primitive_sseq, f] using hx'
  have : extendedSubsequentialLimits (SubSeq.val sₙ primitive_sseq)
    |>.Nonempty := by
      exact ⟨upperLimit (SubSeq.val sₙ primitive_sseq),
        upperLimit_mem_extendedSubsequentialLimits (SubSeq.val sₙ primitive_sseq)⟩
  rcases this with ⟨s, hs₀⟩
  have : s ∈ extendedSubsequentialLimits sₙ := by
    exact mem_extendedSubsequentialLimits_of_subseq sₙ primitive_sseq hs₀
  use s; use this;
  exact le_of_forall_le_of_mem_extendedSubsequentialLimits
    (SubSeq.val sₙ primitive_sseq) primitive_sseq_ge_x hs₀

/-- Theorem 3.17, uniqueness part: s* is the only number with properties (a) and (b). -/
theorem upperLimit_unique (sₙ : ℕ → ℝ) (y : EReal)
  (h_mem : y ∈ extendedSubsequentialLimits sₙ)
  (h_eventually : ∀ {x : ℝ}, (x : EReal) > y → ∃ N : ℕ, ∀ n ≥ N, sₙ n < x) :
    y = upperLimit sₙ := by
  apply le_antisymm
  · exact le_upperLimit_of_mem_extendedSubsequentialLimits sₙ h_mem
  · by_contra h
    have hyu : y < upperLimit sₙ := lt_of_not_ge h
    have hu_mem : upperLimit sₙ ∈ extendedSubsequentialLimits sₙ :=
      upperLimit_mem_extendedSubsequentialLimits sₙ
    have hu_cluster : MapClusterPt (upperLimit sₙ) Filter.atTop (fun n ↦ (sₙ n : EReal)) :=
      (mem_extendedSubsequentialLimits_iff_mapClusterPt sₙ (upperLimit sₙ)).1 hu_mem
    rcases EReal.exists_between_coe_real hyu with ⟨x, hxy, hxu⟩
    rcases h_eventually hxy with ⟨N, hN⟩
    have hmem : ∀ᶠ n in Filter.atTop, (fun n ↦ (sₙ n : EReal)) n ∈ Set.Iic (x : EReal) := by
      exact Filter.mem_atTop_sets.2 ⟨N, fun n hn ↦ by
        change (sₙ n : EReal) ≤ (x : EReal)
        exact le_of_lt (by exact_mod_cast hN n hn)⟩
    have hu_le_x : upperLimit sₙ ≤ (x : EReal) := by
      simpa using IsClosed.mem_of_mapClusterPt isClosed_Iic hu_cluster hmem
    exact (not_le_of_gt hxu) hu_le_x

/-- Analogous result for the lower limit: lower limit is in the extended subsequential limits. -/
theorem lowerLimit_mem_extendedSubsequentialLimits (sₙ : ℕ → ℝ) :
    lowerLimit sₙ ∈ extendedSubsequentialLimits sₙ := by
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
  have hlow : lowerLimit sₙ = sInf S := by
    unfold lowerLimit
    simpa [S] using (sInf_image (s := extendedSubsequentialLimits sₙ) (f := id)).symm
  have hs : sInf S ∈ S := hclosed.sInf_mem hnonempty
  rw [hlow]
  exact hs

/-- Analogous result for the lower limit: if x < s_*, then eventually sₙ > x. -/
theorem lowerLimit_eventually_gt (sₙ : ℕ → ℝ) {x : ℝ} (hx : (x : EReal) < lowerLimit sₙ) :
  ∃ N : ℕ, ∀ n ≥ N, sₙ n > x := by
  unfold lowerLimit at hx
  have hx : ∀ s ∈ extendedSubsequentialLimits sₙ, (x : EReal) < s := by
    intro s hs
    exact lt_of_lt_of_le hx (iInf_le_of_le s (iInf_le_of_le hs le_rfl))
  by_contra hyp
  push Not at hyp
  choose f₀ hf₀ using hyp
  set f : ℕ → ℕ := Nat.rec (f₀ 0) (λ _ last ↦ last.succ |> f₀)
  have hf_strict : StrictMono f := by
    refine strictMono_nat_of_lt_succ ?_
    intro n
    have hf : f n + 1 ≤ f₀ (f n + 1) := (hf₀ (f n + 1)).1
    simpa [f] using hf
  set primitive_sseq : SubSeq sₙ := SubSeq.mk f hf_strict
  have primitive_sseq_le_x : ∀ n : ℕ, SubSeq.val sₙ primitive_sseq n ≤ x := by
    intro n
    induction n with
    | zero =>
        exact (hf₀ 0).2
    | succ n hn =>
        exact by
          have hx' : sₙ (f₀ (f n + 1)) ≤ x := (hf₀ (f n + 1)).2
          simpa [SubSeq.val, primitive_sseq, f] using hx'
  have : extendedSubsequentialLimits (SubSeq.val sₙ primitive_sseq) |>.Nonempty := by
    exact ⟨lowerLimit (SubSeq.val sₙ primitive_sseq),
      lowerLimit_mem_extendedSubsequentialLimits (SubSeq.val sₙ primitive_sseq)⟩
  rcases this with ⟨s, hs₀⟩
  have hs : s ∈ extendedSubsequentialLimits sₙ :=
    mem_extendedSubsequentialLimits_of_subseq sₙ primitive_sseq hs₀
  have hs_le : s ≤ (x : EReal) := by
    let S : Set EReal := Set.Iic (x : EReal)
    have hclosed : IsClosed S := isClosed_Iic
    have hcluster :
      MapClusterPt s Filter.atTop (λ n ↦ (((SubSeq.val sₙ primitive_sseq) n : ℝ) : EReal)) := by
        exact mem_extendedSubsequentialLimits_iff_mapClusterPt
          (SubSeq.val sₙ primitive_sseq) s |>.1 hs₀
    have hmem : ∀ᶠ n in Filter.atTop,
      (λ n ↦ (((SubSeq.val sₙ primitive_sseq) n : ℝ) : EReal)) n ∈ S := by
      exact Filter.Eventually.of_forall <| fun n ↦ by
        change ((((SubSeq.val sₙ primitive_sseq) n : ℝ) : EReal)) ≤ (x : EReal)
        exact_mod_cast primitive_sseq_le_x n
    simpa [S] using hclosed.mem_of_mapClusterPt hcluster hmem
  exact (not_lt_of_ge hs_le) (hx s hs)

/-- Analogous result for the lower limit: uniqueness. -/
theorem lowerLimit_unique (sₙ : ℕ → ℝ) (y : EReal)
    (h_mem : y ∈ extendedSubsequentialLimits sₙ)
    (h_eventually : ∀ {x : ℝ}, (x : EReal) < y → ∃ N : ℕ, ∀ n ≥ N, sₙ n > x) :
    y = lowerLimit sₙ := by
  apply le_antisymm
  · by_contra h
    have hyl : lowerLimit sₙ < y := lt_of_not_ge h
    have hl_mem : lowerLimit sₙ ∈ extendedSubsequentialLimits sₙ :=
      lowerLimit_mem_extendedSubsequentialLimits sₙ
    have hl_cluster : MapClusterPt (lowerLimit sₙ) Filter.atTop (fun n ↦ (sₙ n : EReal)) :=
      (mem_extendedSubsequentialLimits_iff_mapClusterPt sₙ (lowerLimit sₙ)).1 hl_mem
    rcases EReal.exists_between_coe_real hyl with ⟨x, hlx, hxy⟩
    rcases h_eventually hxy with ⟨N, hN⟩
    have hmem : ∀ᶠ n in Filter.atTop, (λ n ↦ (sₙ n : EReal)) n ∈ Set.Ici (x : EReal) := by
      exact Filter.mem_atTop_sets.2 ⟨N, λ n hn ↦ by
        change (x : EReal) ≤ (sₙ n : EReal)
        exact le_of_lt (by exact_mod_cast hN n hn)⟩
    have hx_le_l : (x : EReal) ≤ lowerLimit sₙ := by
      simpa using IsClosed.mem_of_mapClusterPt isClosed_Ici hl_cluster hmem
    exact (not_le_of_gt hlx) hx_le_l
  · unfold lowerLimit
    exact iInf_le_of_le y (iInf_le_of_le h_mem le_rfl)

end

section -- 3.18 --

/-- Theorem 3.18(c): A real-valued sequence converges to s
    iff limsup = liminf = s. -/
theorem convergent_iff_upperLimit_eq_lowerLimit (sₙ : ℕ → ℝ) (s : ℝ) :
  convergesTo ℝ sₙ s
    <->
      upperLimit sₙ = (s : EReal) ∧ lowerLimit sₙ = (s : EReal) := by
  constructor
  · intro sₙcvg
    let p_id : SubSeq sₙ := ⟨fun n ↦ n, fun _ _ h ↦ h⟩
    have hp_id : convergesTo ℝ p_id s :=
      (subseq_converge_iff_converge sₙ s).1 sₙcvg p_id
    have hs_mem : (s : EReal) ∈ extendedSubsequentialLimits sₙ := by
      left
      left
      exact ⟨s, ⟨p_id, hp_id⟩, rfl⟩
    constructor
    · exact (upperLimit_unique sₙ (s : EReal) hs_mem (by
        intro x hx
        have hsx : s < x := by exact_mod_cast hx
        have hε : 0 < x - s := sub_pos.mpr hsx
        rcases sₙcvg (x - s) hε with ⟨N, hN⟩
        refine ⟨N, fun n hn ↦ ?_⟩
        have hdist := hN n hn
        have habs : |sₙ n - s| < x - s := by simpa [dist] using hdist
        linarith [abs_lt.mp habs |>.2, hsx])).symm
    · exact (lowerLimit_unique sₙ (s : EReal) hs_mem (by
        intro x hx
        have hxs : x < s := by exact_mod_cast hx
        have hε : 0 < s - x := sub_pos.mpr hxs
        rcases sₙcvg (s - x) hε with ⟨N, hN⟩
        refine ⟨N, fun n hn ↦ ?_⟩
        have hdist := hN n hn
        have habs : |sₙ n - s| < s - x := by simpa [dist] using hdist
        linarith [abs_lt.mp habs |>.1, hxs])).symm
  · rintro ⟨ulim, llim⟩
    intro ε εpos
    have h₁ : ∃ N : ℕ, ∀ n ≥ N, sₙ n < s + ε := by
      have hx : ((s + ε : ℝ) : EReal) > upperLimit sₙ := by
        rw [ulim]
        exact_mod_cast (show s < s + ε by linarith)
      exact upperLimit_eventually_lt sₙ hx
    have h₂ : ∃ N : ℕ, ∀ n ≥ N, sₙ n > s - ε := by
      have hx : ((s - ε : ℝ) : EReal) < lowerLimit sₙ := by
        rw [llim]
        exact_mod_cast sub_lt_self s εpos
      exact lowerLimit_eventually_gt sₙ hx
    rcases h₁ with ⟨N₁, hN₁⟩
    rcases h₂ with ⟨N₂, hN₂⟩
    refine ⟨max N₁ N₂, fun n hn ↦ ?_⟩
    have hlt : sₙ n < s + ε := hN₁ n (le_of_max_le_left hn)
    have hgt : s - ε < sₙ n := hN₂ n (le_of_max_le_right hn)
    have habs : |sₙ n - s| < ε := by
      rw [abs_lt]
      constructor <;> linarith
    simpa [dist] using habs

/-- Example 3.18(a): For a sequence whose range contains all rationals,
    limsup = +∞ and liminf = -∞. (Skeleton) -/
theorem example_rational_sequence_limsup_liminf (sₙ : ℕ → ℝ)
    (h_range : ∀ q : ℚ, (q : ℝ) ∈ Set.range sₙ) :
    upperLimit sₙ = ⊤ ∧ lowerLimit sₙ = ⊥ := by
  constructor
  · have c₁ : ⊤ ∈ extendedSubsequentialLimits sₙ := by
      have hstep : ∀ prev k : ℕ, ∃ n > prev, (k : ℝ) ≤ sₙ n := by
        intro prev k
        let F : Finset ℝ := (Finset.range (prev + 1)).image sₙ
        have hFne : F.Nonempty := by
          refine ⟨sₙ 0, Finset.mem_image.mpr ?_⟩
          exact ⟨0, by simp, rfl⟩
        let M : ℝ := max (k : ℝ) (F.max' hFne)
        rcases exists_rat_gt M with ⟨q, hq⟩
        rcases h_range q with ⟨n, hnq⟩
        have hqk : (k : ℝ) < (q : ℝ) := lt_of_le_of_lt (le_max_left _ _) hq
        have hn : n > prev := by
          by_contra hle
          have hmem : (q : ℝ) ∈ F := by
            refine Finset.mem_image.mpr ?_
            exact ⟨n, by simp [Finset.mem_range, Nat.lt_succ_iff, le_of_not_gt hle], hnq⟩
          have hqle : (q : ℝ) ≤ F.max' hFne := F.le_max' _ hmem
          exact not_lt_of_ge (le_trans hqle (le_max_right _ _)) hq
        have hkq : (k : ℝ) ≤ sₙ n := by rw [hnq]; exact le_of_lt hqk
        exact ⟨n, hn, hkq⟩
      choose g hg_lt hg_val using hstep
      set f : ℕ → ℕ := Nat.rec (g 0 0) (fun n last ↦ g last (n + 1))
      have hf_strict : StrictMono f := by
        refine strictMono_nat_of_lt_succ ?_
        intro n
        have hlt : f n < g (f n) (n + 1) := hg_lt (f n) (n + 1)
        simpa [f] using hlt
      let pnₖ : SubSeq sₙ := ⟨f, hf_strict⟩
      have hpos : tendsToPosInf (SubSeq.val sₙ pnₖ) := by
        intro M
        rcases exists_nat_gt M with ⟨N, hN⟩
        refine ⟨N, fun n hn ↦ ?_⟩
        have hval : (n : ℝ) ≤ sₙ (f n) := by
          induction n with
          | zero =>
              simpa [f] using hg_val 0 0
          | succ k ih =>
              simpa [f] using hg_val (f k) (k + 1)
        exact le_trans (le_of_lt hN) (le_trans (by exact_mod_cast hn) hval)
      have hsub : ∃ pnₖ : SubSeq sₙ, tendsToPosInf (SubSeq.val sₙ pnₖ) := ⟨pnₖ, hpos⟩
      simp [extendedSubsequentialLimits, hsub]
    have c₂ : ∀ x : EReal, x > ⊤ -> ∃ N : ℕ, ∀ n ≥ N, sₙ n < x := by
      intro x hx
      exfalso
      exact not_lt_of_ge le_top hx
    exact (upperLimit_unique sₙ ⊤ c₁ (by intro x hx; exfalso; exact not_lt_of_ge le_top hx)).symm
  · have c₁ : ⊥ ∈ extendedSubsequentialLimits sₙ := by
      have hstep : ∀ prev k : ℕ, ∃ n > prev, sₙ n ≤ -(k : ℝ) := by
        intro prev k
        let F : Finset ℝ := (Finset.range (prev + 1)).image sₙ
        have hFne : F.Nonempty := by
          refine ⟨sₙ 0, Finset.mem_image.mpr ?_⟩
          exact ⟨0, by simp, rfl⟩
        let m : ℝ := min (-(k : ℝ)) (F.min' hFne)
        rcases exists_rat_btwn (show m - 1 < m by linarith) with ⟨q, hq1, hq2⟩
        rcases h_range q with ⟨n, hnq⟩
        have hqk : (q : ℝ) < -(k : ℝ) := lt_of_lt_of_le hq2 (min_le_left _ _)
        have hn : n > prev := by
          by_contra hle
          have hmem : (q : ℝ) ∈ F := by
            refine Finset.mem_image.mpr ?_
            exact ⟨n, by simpa using le_of_not_gt hle, hnq⟩
          have hminle : F.min' hFne ≤ (q : ℝ) := F.min'_le _ hmem
          exact not_lt_of_ge (le_trans (min_le_right _ _) hminle) hq2
        exact ⟨n, hn, hnq.symm ▸ le_of_lt hqk⟩
      choose g hg_lt hg_val using hstep
      set f : ℕ → ℕ := Nat.rec (g 0 0) (fun n last ↦ g last (n + 1))
      have hf_strict : StrictMono f := by
        refine strictMono_nat_of_lt_succ ?_
        intro n
        have hlt : f n < g (f n) (n + 1) := hg_lt (f n) (n + 1)
        simpa [f] using hlt
      let pnₖ : SubSeq sₙ := ⟨f, hf_strict⟩
      have hneg : tendsToNegInf (SubSeq.val sₙ pnₖ) := by
        intro M
        rcases exists_nat_gt (-M) with ⟨N, hN⟩
        refine ⟨N, fun n hn ↦ ?_⟩
        have hval : sₙ (f n) ≤ -(n : ℝ) := by
          induction n with
          | zero => simpa [f] using hg_val 0 0
          | succ k ih => simpa [f] using hg_val (f k) (k + 1)
        have hNr : (- (n : ℝ)) ≤ M := by
          have : (N : ℝ) ≤ n := by exact_mod_cast hn
          linarith [hN]
        exact le_trans hval hNr
      have hsub : ∃ pnₖ : SubSeq sₙ, tendsToNegInf (SubSeq.val sₙ pnₖ) := ⟨pnₖ, hneg⟩
      simp [extendedSubsequentialLimits, hsub]
    have c₂ : ∀ x : EReal, x < ⊥ -> ∃ N : ℕ, ∀ n ≥ N, sₙ n > x := by
      intro x hx
      exfalso
      exact not_lt_of_ge bot_le hx
    exact (lowerLimit_unique sₙ ⊥ c₁ (by intro x hx; exfalso; exact not_lt_of_ge bot_le hx)).symm

/-- Example 3.18(b): For sₙ = (-1)^n / (1 + 1/n), limsup = 1, liminf = -1. (Skeleton) -/
theorem example_alternating_limsup_liminf :
    let sₙ : ℕ → ℝ := λ n ↦ ((-1 : ℝ) ^ n) / (1 + 1 / (↑n + 1))
    upperLimit sₙ = (1 : EReal) ∧ lowerLimit sₙ = (-1 : EReal) := by
  intro sₙ
  constructor
  · set nₖ : ℕ -> ℕ := λ n ↦ 2 * n
    have nₖ_mono : StrictMono nₖ := by
      intro a b hab
      simp only [Order.lt_two_iff, zero_le, mul_lt_mul_iff_right₀, nₖ]
      assumption
    set sseq : SubSeq sₙ := SubSeq.mk nₖ nₖ_mono
    have hsseq_conv : convergesTo ℝ sseq 1 := by
      intro ε εpos
      rcases exists_nat_gt (1 / ε) with ⟨N, hN⟩
      refine ⟨N, fun n hn ↦ ?_⟩
      have hrepr : sseq n = 1 - 1 / ((2 * n : ℝ) + 2) := by
        have hpow : ((-1 : ℝ) ^ (2 * n)) = 1 := by
          rw [pow_mul]
          norm_num
        calc
          sseq n = ((-1 : ℝ) ^ (2 * n)) / (1 + 1 / ((2 * n : ℝ) + 1)) := by
            simp [sseq, SubSeq.val, nₖ, sₙ, mul_comm]
          _ = 1 / (1 + 1 / ((2 * n : ℝ) + 1)) := by rw [hpow]
          _ = 1 - 1 / ((2 * n : ℝ) + 2) := by
            field_simp
            ring
      have hlt : 1 / ((2 * n : ℝ) + 2) < ε := by
        have hn' : 1 / ε < (n : ℝ) + 1 := by
          have : (N : ℝ) ≤ n := by exact_mod_cast hn
          linarith
        have hpos : 0 < (n : ℝ) + 1 := by positivity
        have hlt' : 1 / ((n : ℝ) + 1) < ε := by
          exact (one_div_lt hpos εpos).2 hn'
        have hle : 1 / ((2 * n : ℝ) + 2) ≤ 1 / ((n : ℝ) + 1) := by
          have h1 : (n : ℝ) + 1 ≤ (2 * n : ℝ) + 2 := by nlinarith
          have hpos1 : 0 < (n : ℝ) + 1 := by positivity
          have hpos2 : 0 < (2 * n : ℝ) + 2 := by positivity
          have : ((2 * n : ℝ) + 2)⁻¹ ≤ ((n : ℝ) + 1)⁻¹ := (inv_le_inv₀ hpos2 hpos1).2 h1
          simpa [one_div] using this
        exact lt_of_le_of_lt hle hlt'
      have habs : |sseq n - 1| < ε := by
        rw [hrepr]
        have : (1 - 1 / ((2 * n : ℝ) + 2)) - 1 = -(1 / ((2 * n : ℝ) + 2)) := by ring
        have hnonneg : 0 ≤ 1 / ((2 * n : ℝ) + 2) := by positivity
        rw [this, abs_of_nonpos (by linarith)]
        simpa using hlt
      simpa [dist] using habs
    have hmem : (1 : EReal) ∈ extendedSubsequentialLimits sₙ := by
      left
      left
      exact ⟨1, ⟨sseq, hsseq_conv⟩, rfl⟩
    exact (upperLimit_unique sₙ (1 : EReal) hmem (by
      intro x hx
      refine ⟨0, fun n _ ↦ ?_⟩
      have hpow : ((-1 : ℝ) ^ n) ≤ 1 := by
        have hEq : ((-1 : ℝ) ^ n) = 1 ∨ ((-1 : ℝ) ^ n) = -1 := neg_one_pow_eq_or ℝ n
        rcases hEq with h | h <;> linarith [h]
      have hden : 0 < 1 + 1 / ((n : ℝ) + 1) := by positivity
      have hle1 : sₙ n ≤ 1 := by
        have hdiv : ((-1 : ℝ) ^ n) / (1 + 1 / ((n : ℝ) + 1)) ≤ 1 / (1 + 1 / ((n : ℝ) + 1)) :=
          div_le_div_of_nonneg_right hpow (le_of_lt hden)
        have hlt' : 1 / (1 + 1 / ((n : ℝ) + 1)) < 1 := by
          have hgt : (1 : ℝ) < 1 + 1 / ((n : ℝ) + 1) := by
            have hpos : 0 < 1 / ((n : ℝ) + 1) := by positivity
            linarith
          have htmp : 1 / (1 + 1 / ((n : ℝ) + 1)) < 1 / (1 : ℝ) :=
            one_div_lt_one_div_of_lt zero_lt_one hgt
          simpa using htmp
        exact le_trans hdiv (le_of_lt hlt')
      have hx' : 1 < x := by exact_mod_cast hx
      linarith)).symm
  · set nₖ : ℕ -> ℕ := λ n ↦ 2 * n + 1
    have nₖ_mono : StrictMono nₖ := by
      intro a b hab
      simpa [nₖ, two_mul] using Nat.add_lt_add_right (Nat.add_lt_add hab hab) 1
    set sseq : SubSeq sₙ := SubSeq.mk nₖ nₖ_mono
    have hsseq_conv : convergesTo ℝ sseq (-1) := by
      intro ε εpos
      rcases exists_nat_gt (1 / ε) with ⟨N, hN⟩
      refine ⟨N, fun n hn ↦ ?_⟩
      have hrepr : sseq n = -1 + 1 / ((2 * n : ℝ) + 3) := by
        have hpow : ((-1 : ℝ) ^ (2 * n + 1)) = -1 := by
          rw [pow_add, pow_mul]
          norm_num
        calc
          sseq n = ((-1 : ℝ) ^ (2 * n + 1)) / (1 + 1 / ((2 * n + 1 : ℝ) + 1)) := by
            simp [sseq, SubSeq.val, nₖ, sₙ, mul_comm, add_comm]
          _ = (-1 : ℝ) / (1 + 1 / ((2 * n + 1 : ℝ) + 1)) := by rw [hpow]
          _ = -1 + 1 / ((2 * n : ℝ) + 3) := by
            field_simp
            ring
      have hlt : 1 / ((2 * n : ℝ) + 3) < ε := by
        have hn' : 1 / ε < (n : ℝ) + 1 := by
          have : (N : ℝ) ≤ n := by exact_mod_cast hn
          linarith
        have hpos : 0 < (n : ℝ) + 1 := by positivity
        have hlt' : 1 / ((n : ℝ) + 1) < ε := by
          exact (one_div_lt hpos εpos).2 hn'
        have hle : 1 / ((2 * n : ℝ) + 3) ≤ 1 / ((n : ℝ) + 1) := by
          have h1 : (n : ℝ) + 1 ≤ (2 * n : ℝ) + 3 := by nlinarith
          have hpos1 : 0 < (n : ℝ) + 1 := by positivity
          have hpos2 : 0 < (2 * n : ℝ) + 3 := by positivity
          have : ((2 * n : ℝ) + 3)⁻¹ ≤ ((n : ℝ) + 1)⁻¹ := (inv_le_inv₀ hpos2 hpos1).2 h1
          simpa [one_div] using this
        exact lt_of_le_of_lt hle hlt'
      have habs : |sseq n - (-1)| < ε := by
        rw [hrepr]
        have : (-1 + 1 / ((2 * n : ℝ) + 3)) - (-1) = 1 / ((2 * n : ℝ) + 3) := by ring
        have hnonneg : 0 ≤ 1 / ((2 * n : ℝ) + 3) := by positivity
        rw [this, abs_of_nonneg hnonneg]
        simpa using hlt
      simpa [dist] using habs
    have hmem : ((-1 : ℝ) : EReal) ∈ extendedSubsequentialLimits sₙ := by
      left
      left
      exact ⟨-1, ⟨sseq, hsseq_conv⟩, rfl⟩
    exact (lowerLimit_unique sₙ ((-1 : ℝ) : EReal) hmem (by
      intro x hx
      refine ⟨0, fun n _ ↦ ?_⟩
      have hpow : (-1 : ℝ) ≤ ((-1 : ℝ) ^ n) := by
        have hEq : ((-1 : ℝ) ^ n) = 1 ∨ ((-1 : ℝ) ^ n) = -1 := neg_one_pow_eq_or ℝ n
        rcases hEq with h | h <;> linarith [h]
      have hden : 0 < 1 + 1 / ((n : ℝ) + 1) := by positivity
      have hgtm1 : -1 < sₙ n := by
        rcases neg_one_pow_eq_or ℝ n with hp | hp
        · have hs : 0 < sₙ n := by
            simp [sₙ, hp]
            positivity
          linarith
        · simp [sₙ, hp]
          have hpos : 0 < 1 / ((n : ℝ) + 1) := by positivity
          have hgt : (1 : ℝ) < 1 + 1 / ((n : ℝ) + 1) := by linarith
          have hlt' : 1 / (1 + 1 / ((n : ℝ) + 1)) < 1 := by
            have htmp : 1 / (1 + 1 / ((n : ℝ) + 1)) < 1 / (1 : ℝ) :=
              one_div_lt_one_div_of_lt zero_lt_one hgt
            simpa using htmp
          have hgtm1 : -1 < -1 / (1 + 1 / ((n : ℝ) + 1)) := by
            simpa [neg_div] using (neg_lt_neg hlt')
          simpa [sₙ, hp] using hgtm1
      have hx' : x < -1 := by exact_mod_cast hx
      exact lt_trans hx' hgtm1
      )).symm

end

section -- 3.19 --

/-- Theorem 3.19: If sₙ ≤ tₙ eventually, then liminf sₙ ≤ liminf tₙ
    and limsup sₙ ≤ limsup tₙ. -/
theorem limsup_le_limsup_of_eventually_le (sₙ tₙ : ℕ → ℝ) (h : ∃ N : ℕ, ∀ n ≥ N, sₙ n ≤ tₙ n) :
  upperLimit sₙ ≤ upperLimit tₙ := by
  by_contra hst
  have hlt : upperLimit tₙ < upperLimit sₙ := lt_of_not_ge hst
  rcases EReal.exists_between_coe_real hlt with ⟨x, htx, hxs⟩
  rcases upperLimit_eventually_lt tₙ htx with ⟨N₁, hN₁⟩
  rcases h with ⟨N₂, hN₂⟩
  have hmem : ∀ᶠ n in Filter.atTop, (fun n ↦ (sₙ n : EReal)) n ∈ Set.Iic (x : EReal) := by
    refine Filter.mem_atTop_sets.2 ⟨max N₁ N₂, fun n hn ↦ ?_⟩
    change (sₙ n : EReal) ≤ (x : EReal)
    have hsle : sₙ n ≤ tₙ n := hN₂ n (le_of_max_le_right hn)
    have htlt : tₙ n < x := hN₁ n (le_of_max_le_left hn)
    exact le_of_lt (by exact_mod_cast lt_of_le_of_lt hsle htlt)
  have hu_mem : upperLimit sₙ ∈ extendedSubsequentialLimits sₙ :=
    upperLimit_mem_extendedSubsequentialLimits sₙ
  have hu_cluster : MapClusterPt (upperLimit sₙ) Filter.atTop (fun n ↦ (sₙ n : EReal)) :=
    (mem_extendedSubsequentialLimits_iff_mapClusterPt sₙ (upperLimit sₙ)).1 hu_mem
  have hu_le_x : upperLimit sₙ ≤ (x : EReal) := by
    simpa using IsClosed.mem_of_mapClusterPt isClosed_Iic hu_cluster hmem
  exact (not_le_of_gt hxs) hu_le_x

/-- Theorem 3.19: liminf part. -/
theorem liminf_le_liminf_of_eventually_le (sₙ tₙ : ℕ → ℝ) (h : ∃ N : ℕ, ∀ n ≥ N, sₙ n ≤ tₙ n) :
  lowerLimit sₙ ≤ lowerLimit tₙ := by
  by_contra hst
  have hlt : lowerLimit tₙ < lowerLimit sₙ := lt_of_not_ge hst
  rcases EReal.exists_between_coe_real hlt with ⟨x, htx, hxs⟩
  rcases lowerLimit_eventually_gt sₙ hxs with ⟨N₁, hN₁⟩
  rcases h with ⟨N₂, hN₂⟩
  have hmem : ∀ᶠ n in Filter.atTop, (fun n ↦ (tₙ n : EReal)) n ∈ Set.Ici (x : EReal) := by
    refine Filter.mem_atTop_sets.2 ⟨max N₁ N₂, fun n hn ↦ ?_⟩
    change (x : EReal) ≤ (tₙ n : EReal)
    have hxlt : x < sₙ n := hN₁ n (le_of_max_le_left hn)
    have hsle : sₙ n ≤ tₙ n := hN₂ n (le_of_max_le_right hn)
    exact le_of_lt (by exact_mod_cast lt_of_lt_of_le hxlt hsle)
  have hl_mem : lowerLimit tₙ ∈ extendedSubsequentialLimits tₙ :=
    lowerLimit_mem_extendedSubsequentialLimits tₙ
  have hl_cluster : MapClusterPt (lowerLimit tₙ) Filter.atTop (fun n ↦ (tₙ n : EReal)) :=
    (mem_extendedSubsequentialLimits_iff_mapClusterPt tₙ (lowerLimit tₙ)).1 hl_mem
  have hx_le : (x : EReal) ≤ lowerLimit tₙ := by
    simpa using IsClosed.mem_of_mapClusterPt isClosed_Ici hl_cluster hmem
  exact (not_le_of_gt htx) hx_le

end

end UpperAndLowerLimits
