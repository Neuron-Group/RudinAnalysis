import RudinAnalysis.NumericalSequencesAndSeries.Import
import RudinAnalysis.NumericalSequencesAndSeries.ConvergentSequences
import Mathlib.Data.ENNReal.Real

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace Subsequences
open ConvergentSequences MetricSpaces

section -- 3.5 --
variable {X : Type*} [MetricSpace X]

theorem eventually_ge_of_strictMono {nₖ : ℕ → ℕ} (hnₖ : StrictMono nₖ) (N : ℕ) :
  ∃ K, ∀ k ≥ K, nₖ k ≥ N := by
    induction N with
    | zero =>
      use 0; intro k _;
      exact Nat.zero_le (nₖ k)
    | succ N h =>
      rcases h with ⟨K, h⟩
      set K' := K + 1 with K'df
      specialize h K (by linarith)
      use K'; intro k hk
      have kltK : k > K := Nat.lt_of_succ_le hk
      have : nₖ k > nₖ K := hnₖ kltK
      have : nₖ k ≥ nₖ K + 1 := Order.add_one_le_iff.mpr this
      linarith only [this, h]

@[ext]
structure SubSeq (pₙ : ℕ -> X) where
  idx : ℕ → ℕ
  strictMono_idx : StrictMono idx

def SubSeq.val (pₙ : ℕ → X) (s : SubSeq pₙ) : ℕ → X :=
  pₙ ∘ s.idx

instance (pₙ : ℕ → X) : CoeFun (SubSeq pₙ) (fun _ => ℕ → X) where
  coe s := SubSeq.val pₙ s

theorem subseq_converge_iff_converge (pₙ : ℕ -> X) (p : X) :
  convergesTo X pₙ p <-> ∀ pnₖ : SubSeq pₙ, convergesTo X pnₖ p := by
    constructor

    · intro cvp pnₖ ε εpos
      specialize cvp ε εpos
      rcases cvp with ⟨N, cvp⟩
      rcases eventually_ge_of_strictMono pnₖ.strictMono_idx N with ⟨K, Kh⟩
      use K; intro k kgeK;
      specialize Kh k kgeK
      specialize cvp (pnₖ.idx k) Kh
      simpa [SubSeq.val, CoeFun.coe] using cvp

    · intro hyp
      set p_id : SubSeq pₙ := ⟨
        λ n ↦ n,
        by
          intro _ _ h
          exact h
      ⟩ with p_id_df
      specialize hyp p_id
      have : SubSeq.val pₙ p_id = pₙ := by
        dsimp only [SubSeq.val]
        ext n
        simp only [p_id_df, Function.comp_apply]
      rw [this] at hyp
      exact hyp

end

section -- 3.6 --
theorem pigeonhole_principle_infinite_seq {X : Type u} [Finite X]
  (pₙ : ℕ → X) : ∃ p : X, ∀ N : ℕ, ∃ n > N, pₙ n = p := by
    by_contra hyp
    push Not at hyp
    let S (p : X) : Set ℕ := {n | pₙ n = p}
    have fin_S (p : X) : Set.Finite (S p) := by
      rcases hyp p with ⟨N, hN⟩
      have subset : S p ⊆ {n | n ≤ N} := by
        intro n hn
        simp only [S, Set.mem_setOf_eq] at hn
        by_contra h
        simp only [Set.mem_setOf_eq, not_le] at h
        specialize hN n h
        contradiction
      exact Set.Finite.subset (Set.finite_le_nat N) subset
    have finite_union : Set.Finite (⋃ p : X, S p) := by
      haveI := Fintype.ofFinite X
      exact Set.finite_iUnion fin_S
    have union_eq_univ : (⋃ p : X, S p) = Set.univ := by
      ext n
      simp only [Set.mem_iUnion, S, Set.mem_setOf_eq]
      constructor
      · simp
      · intro nh
        use pₙ n
    rw [union_eq_univ] at finite_union
    have := @Set.infinite_univ ℕ _
    exact Ne.elim (fun a ↦ this finite_union) union_eq_univ

theorem pigeonhole_principle_infinite_seq_on_set {X : Type u}
  (pₙ : ℕ → X) : (pₙ '' Set.univ).Finite -> ∃ p : X, ∀ N : ℕ, ∃ n > N, pₙ n = p := by
    intro hfin
    let Y : Set X := pₙ '' Set.univ
    letI : Fintype Y := Set.Finite.fintype hfin
    let q : ℕ → Y := fun n ↦ ⟨pₙ n, by
      refine ⟨n, ?_, rfl⟩
      simp
    ⟩
    obtain ⟨p, hp⟩ := pigeonhole_principle_infinite_seq q
    refine ⟨p, ?_⟩
    intro N
    obtain ⟨n, hn, hq⟩ := hp N
    refine ⟨n, hn, ?_⟩
    exact congrArg Subtype.val hq

variable {X : Type*} [MetricSpace X]

open Classical in
theorem compactSpace_has_convergent_subsequence [CompactSpace X] (pₙ : ℕ -> X) :
  ∃ pnₖ : SubSeq pₙ, convergent X pnₖ := by
    set X' : Set X := Set.univ with X'df
    have X'cmp : IsCompact X' := CompactSpace.isCompact_univ
    set E : Set X := pₙ '' Set.univ with Edf
    have EsubX : E ⊆ X' := Set.image_subset_iff.mpr fun ⦃a⦄ a_1 ↦ a_1
    by_cases hyp : E.Finite
    · obtain ⟨p, hp⟩ := pigeonhole_principle_infinite_seq_on_set pₙ hyp
      choose hₖ hhₖ using hp
      set nₖ : ℕ -> ℕ
        := λ k ↦ Nat.rec (hₖ 0) (λ _ prev ↦ hₖ prev) k
          with nₖdf
      have hnₖ : StrictMono nₖ := by
        refine strictMono_nat_of_lt_succ ?_
        intro n
        exact (hhₖ
          (Nat.rec (hₖ 0) (fun x prev ↦ hₖ prev) n)).left
      set pnₖ : SubSeq pₙ := {idx := nₖ, strictMono_idx := hnₖ} with pnₖdf
      use pnₖ; use p; intro ε εpos
      use 0; intro n nnonneg;
      have : SubSeq.val pₙ pnₖ n = p := by
        simp only [SubSeq.val, Function.comp_apply]
        rw [pnₖdf]
        simp only
        rw [nₖdf]
        induction n with
        | zero =>
          exact (hhₖ 0).right
        | succ n =>
          exact (hhₖ _).right
      rw [this]
      simp only [dist_self, gt_iff_lt]
      assumption
    · push Not at hyp
      obtain ⟨p, pinX', limp⟩ := bolzano_weierstrass E X' hyp X'cmp EsubX
      have hInfBall : ∀ ε > 0, (deletedBall p ε ∩ E).Infinite := by
        intro ε εpos hfin
        rcases Set.Finite.exists_finset_coe hfin with ⟨S, hS⟩
        let T : Finset X := S.erase p
        by_cases hT : T.Nonempty
        · let r : ℝ := T.inf' hT (fun x ↦ dist x p)
          have hr_pos : 0 < r := by
            rw [show r = T.inf' hT (fun x ↦ dist x p) by rfl]
            exact (Finset.lt_inf'_iff (H := hT)).2 fun x hx ↦ by
              have hxp : x ≠ p := (Finset.mem_erase.mp (by simpa [T] using hx)).1
              exact dist_pos.mpr hxp
          have hr_nbh : r < ε := by
            let x := hT.choose
            have hxT : x ∈ T := hT.choose_spec
            have hxS : x ∈ S := (Finset.mem_erase.mp hxT).2
            have hxbE : x ∈ deletedBall p ε ∩ E := by
              have : x ∈ (S : Set X) := by simpa using hxS
              rw [hS] at this
              exact this
            exact lt_of_le_of_lt
              (Finset.inf'_le (s := T) (f := fun y ↦ dist y p) hxT)
              hxbE.1.1
          let δ : ℝ := min ε (r / 2)
          have hδpos : 0 < δ := by
            apply lt_min
            · exact εpos
            · linarith
          have hδ : (deletedBall p δ ∩ E).Nonempty := limp δ hδpos
          rcases hδ with ⟨x, hxδ, hxE⟩
          have hxb : x ∈ openBall p ε := by
            have : dist x p < ε := lt_of_lt_of_le hxδ.1 (by
              change δ ≤ ε
              simp [δ]
            )
            simpa [openBall] using this
          have hxS : x ∈ S := by
            have : x ∈ (S : Set X) := by
              rw [hS]
              exact ⟨⟨hxb, hxδ.2⟩, hxE⟩
            simpa using this
          have hxT : x ∈ T := by
            exact Finset.mem_erase.mpr ⟨hxδ.2, hxS⟩
          have hr_le : r ≤ dist x p := by
            exact Finset.inf'_le (s := T) (f := fun y ↦ dist y p) hxT
          have hlt_half : dist x p < r / 2 := by
            exact lt_of_lt_of_le hxδ.1 (by
              change δ ≤ r / 2
              simp [δ]
            )
          linarith
        · have hδ : (deletedBall p ε ∩ E).Nonempty := limp ε εpos
          rcases hδ with ⟨x, hxδ, hxE⟩
          have hxb : x ∈ openBall p ε := by
            simpa [openBall] using hxδ.1
          have hxS : x ∈ S := by
            have : x ∈ (S : Set X) := by
              rw [hS]
              exact ⟨⟨hxb, hxδ.2⟩, hxE⟩
            simpa using this
          have hxT : x ∈ T := by
            exact Finset.mem_erase.mpr ⟨hxδ.2, hxS⟩
          exact hT ⟨x, hxT⟩
      have hp' : ∀ k N : ℕ, ∃ n > N, dist (pₙ n) p < 1 / (↑k + 1) := by
        intro k N
        have hbInf : (deletedBall p (1 / (↑k + 1)) ∩ E).Infinite := by
          exact hInfBall (1 / (↑k + 1)) Nat.one_div_pos_of_nat
        let F : Set X := pₙ '' {n : ℕ | n ≤ N}
        have hFfin : F.Finite := by
          exact Set.Finite.image pₙ (Set.finite_le_nat N)
        have hxexists : ∃ x, x ∈ deletedBall p (1 / (↑k + 1)) ∩ E ∧ x ∉ F := by
          by_contra h
          apply hbInf.not_finite
          apply hFfin.subset
          intro x hx
          by_contra hxF
          exact h ⟨x, hx, hxF⟩
        rcases hxexists with ⟨x, hxBE, hxnotF⟩
        rcases hxBE.2 with ⟨n, -, rfl⟩
        have hnle : ¬ n ≤ N := by
          intro hnle
          apply hxnotF
          exact ⟨n, hnle, rfl⟩
        refine ⟨n, Nat.lt_of_not_ge hnle, ?_⟩
        simpa [deletedBall, openBall] using hxBE.1.1
      choose hₖ hhₖ using hp'
      set nₖ : ℕ → ℕ := λ k ↦ Nat.rec (hₖ 0 0) (λ i prev ↦ hₖ (i + 1) prev) k with nₖdf
      have hnₖ : StrictMono nₖ := by
        refine strictMono_nat_of_lt_succ ?_
        intro n
        rw [nₖdf]
        exact (hhₖ (n + 1) _).left
      set pnₖ : SubSeq pₙ := {idx := nₖ, strictMono_idx := hnₖ} with pnₖdf
      use pnₖ
      use p
      intro ε εpos
      obtain ⟨N, hN⟩ : ∃ N : ℕ, 1 / ε - 1 < ↑N := exists_nat_gt (1 / ε - 1)
      use N
      intro n hn
      have hdist : dist (pnₖ n) p < 1 / (↑n + 1) := by
        simp only [SubSeq.val, Function.comp_apply]
        rw [pnₖdf]
        simp only
        rw [nₖdf]
        induction n with
        | zero =>
          exact (hhₖ 0 0).right
        | succ n ih =>
          exact (hhₖ (n + 1) _).right
      calc
        _ < 1 / (↑n + 1) := hdist
        _ < ε := by
          have : 1 / ε - 1 < ↑n := by
            have : (n : ℝ) ≥ ↑N := Nat.cast_le.mpr hn
            linarith
          field_simp at this ⊢
          linarith

end

section -- 3.6(b) --
theorem bounded_sequence_in_euclidean_has_convergent_subsequence
  {n : ℕ} (pₙ : ℕ → Fin n → ℝ) (hpₙ : sequenceBounded pₙ) :
  ∃ pnₖ : SubSeq pₙ, convergent (Fin n → ℝ) pnₖ := by
    unfold sequenceBounded IsBounded at hpₙ
    set E := Set.range pₙ with Edf
    rcases hpₙ with ⟨c, R, hRpos, hbound⟩
    set K : Set (Fin n -> ℝ) := closedBall c R
      with Kdf
    have hEK : E ⊆ K := by
      intro x hx
      rw [Kdf]
      simp [closedBall]
      specialize hbound x hx
      linarith
    have hKcompact : IsCompact K := by
      rw [Kdf]
      apply isCompact_closedBall c R
    set q : ℕ -> K
      := λ m ↦ ⟨pₙ m, hEK ⟨m, rfl⟩⟩
        with qdf
    have CmpLift : CompactSpace K := isCompact_iff_compactSpace.mp hKcompact
    have ⟨qnₖ, cv⟩ := compactSpace_has_convergent_subsequence q
    let pnₖ : SubSeq pₙ := ⟨
      qnₖ.idx,
      qnₖ.strictMono_idx,
    ⟩
    have inter_match : ∀ k, ((qnₖ k : K) : Fin n -> ℝ) = pnₖ k := by
      intro k
      simp [SubSeq.val, qdf]
      congr
    use pnₖ
    rcases cv with ⟨⟨p, pinK⟩, hp⟩
    use p
    intro ε εpos
    specialize hp ε εpos
    rcases hp with ⟨N, hngeN⟩
    use N; intro n ngeN
    specialize hngeN n ngeN
    rw [← inter_match n]
    exact hngeN

end

section -- 3.7 --
variable {X : Type u} [MetricSpace X]

def subsequentialLimits (pₙ : ℕ → X) : Set X :=
  {p : X | ∃ pnₖ : SubSeq pₙ, convergesTo X pnₖ p}

theorem subsequentialLimits_isClosed (pₙ : ℕ → X) :
  IsClosed (subsequentialLimits pₙ) := by
    /-
      If the set of all sublimit points is infinit,
        it is already closed.
    -/
    by_cases inf_slmts : (subsequentialLimits pₙ).Finite
    · exact Set.Finite.isClosed inf_slmts
    /-
      Or, the proof shall show that every limit point
        of the set is inside the set itself.
    -/
    · push Not at inf_slmts
      /-
        A problem is, we cannot show a limitpoint instantly,
          since the set may be discrete.
        But we can assume the compl set is closed,
          which means there must be some point in compl set
            with any neighborhood inter the original set
              not empty.
      -/
      set S : Set X := (subsequentialLimits pₙ)ᶜ with Sdf
      have Sdf_ct : Sᶜ = subsequentialLimits pₙ := by
        rw [Sdf]
        simp
      rw [← Sdf_ct]
      apply isClosed_compl_iff.mpr
      apply MetricSpaces.isOpen_iff_ball_subset.mpr
      by_contra ct
      push Not at ct
      rcases ct with ⟨p, pinS, hp⟩
      /-
        And then, it will be show that p is a limit point
          of original set.
      -/
      have p_is_lim : MetricSpaces.limitPoint p Sᶜ := by
        unfold limitPoint
        intro ε εpos
        specialize hp ε εpos
        have : (openBall p ε ∩ Sᶜ).Nonempty := by
          exact Set.inter_compl_nonempty_iff.mpr hp
        rcases this with ⟨p₀, hp₀⟩
        use p₀
        constructor
        · constructor
          · exact hp₀.left
          · have c1 : p₀ ∈ Sᶜ := hp₀.right
            have c2 := pinS
            have c3 : p ∉ Sᶜ := Set.notMem_compl_iff.mpr pinS
            exact Membership.mem.ne_of_notMem c1 c3
        · exact hp₀.right

      rw [Sdf_ct] at p_is_lim

      /-
        Fine. We now get a limit point.
        Then, intend to construct a subsequence converges to p,
          which contradict against p ∉ subsequentialLimits pₙ,
            which rudin's book was doing.
      -/

      /-
        Choose a sequence in set tends to the limit point p,
          since each point in sequence is a sub limit of pₙ,
            that for each point, it can also choose a point in pₙ
              which sufficiently close to such point.
        The only thing may be difficult to construct is assuring
          the index of that point which was chosen is gradually lifting.
      -/
      have := ConvergentSequences.sequence_of_limitPoint
        (subsequentialLimits pₙ) p p_is_lim
      rcases this with ⟨lim_pointsₙ, lim_points_in, cnt_lim_points⟩
      unfold convergesTo at cnt_lim_points
      have : ∀ ε > 0, ∀ N ≥ 0, ∃ n > N, dist (pₙ n) p < ε := by
        intro ε εpos N Nnonneg
        specialize cnt_lim_points (ε / 2) (by linarith)
        rcases cnt_lim_points with ⟨N₀, hN₀⟩
        specialize hN₀ N₀ (by linarith)
        set p' := lim_pointsₙ N₀ with p'df
        specialize lim_points_in N₀
        rw [← p'df] at lim_points_in
        rcases lim_points_in with ⟨pnₖ, hpnₖ⟩
        rcases pnₖ with ⟨idx_seq, str_mono_idx⟩
        simp only [SubSeq.val] at hpnₖ
        specialize hpnₖ (ε / 2) (by linarith)
        rcases hpnₖ with ⟨N₁', hN₁'⟩
        have : ∀ N' : ℕ, ∃ N : ℕ, ∀ n ≥ N, idx_seq n ≥ N' := by
          intro N'
          exact eventually_ge_of_strictMono str_mono_idx N'
        specialize this (N + 1)
        rcases this with ⟨N₁, hN₁⟩
        set n := max N₁ N₁' with ndf
        specialize hN₁ n (by
          rw [ndf]
          simp
        )
        specialize hN₁' n (by
          rw [ndf]
          simp
        )
        simp at hN₁'
        use idx_seq n; use (Nat.lt_of_succ_le hN₁)
        have c1 : dist (pₙ (idx_seq n)) p ≤ dist (pₙ (idx_seq n)) p' + dist p' p
          := by exact dist_triangle (pₙ (idx_seq n)) p' p
        have c2 : dist (pₙ (idx_seq n)) p' + dist p' p < ε :=
          calc
            _ < ε / 2 + ε / 2 := by
              grind => linarith
            _ = ε := by exact add_halves ε
        exact Std.lt_of_le_of_lt c1 c2
      /-
        Now, we should construct the subsequence finally
      -/
      have hp' : ∀ k N : ℕ, ∃ n > N, dist (pₙ n) p < 1 / (↑k + 1) := by
        intro k N
        exact this (1 / (↑k + 1)) Nat.one_div_pos_of_nat N (by simp)
      choose hₖ hhₖ using hp'
      set nₖ : ℕ → ℕ := λ k ↦ Nat.rec (hₖ 0 0) (λ i prev ↦ hₖ (i + 1) prev) k with nₖdf
      have hnₖ : StrictMono nₖ := by
        refine strictMono_nat_of_lt_succ ?_
        intro n
        rw [nₖdf]
        exact (hhₖ (n + 1) _).left
      set pnₖ : SubSeq pₙ := {idx := nₖ, strictMono_idx := hnₖ} with pnₖdf
      have hdist : ∀ n : ℕ, dist (pnₖ n) p < 1 / (↑n + 1) := by
        intro n
        simp only [SubSeq.val, Function.comp_apply]
        rw [pnₖdf]
        simp only
        rw [nₖdf]
        induction n with
        | zero =>
          exact (hhₖ 0 0).right
        | succ n ih =>
          exact (hhₖ (n + 1) _).right
      exfalso
      apply pinS
      rw [subsequentialLimits]
      refine ⟨pnₖ, ?_⟩
      unfold convergesTo
      intro ε εpos
      obtain ⟨N, hN⟩ : ∃ N : ℕ, 1 / ε - 1 < ↑N := exists_nat_gt (1 / ε - 1)
      use N
      intro n hn
      calc
        dist (pnₖ n) p < 1 / (↑n + 1) := hdist n
        _ < ε := by
          have : 1 / ε - 1 < ↑n := by
            have : (n : ℝ) ≥ ↑N := Nat.cast_le.mpr hn
            linarith
          field_simp at this ⊢
          linarith

end

section -- 3.8 3.9 --
variable {X : Type u} [MetricSpace X]

def cauchySequence (pₙ : ℕ → X) : Prop :=
  ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, ∀ m ≥ N, dist (pₙ n) (pₙ m) < ε

noncomputable def diameter (E : Set X) : ENNReal :=
  ⨆ p : E, ⨆ q : E, ENNReal.ofReal (dist p.1 q.1)

def tailSet (pₙ : ℕ → X) (N : ℕ) : Set X :=
  {p : X | ∃ n ≥ N, pₙ n = p}

theorem cauchySequence_iff_diameter_tails_vanish (pₙ : ℕ → X) :
  cauchySequence pₙ <->
    ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, diameter (tailSet pₙ n) < ENNReal.ofReal ε := by
    constructor
    · intro hyp ε εpos
      specialize hyp (ε / 2) (by linarith)
      rcases hyp with ⟨N, hN⟩
      use N
      intro n hn
      have hεhalf : ENNReal.ofReal (ε / 2) < ENNReal.ofReal ε := by
        rw [ENNReal.ofReal_lt_ofReal_iff εpos]
        linarith
      unfold diameter
      refine lt_of_le_of_lt ?_ hεhalf
      · refine iSup_le ?_
        intro p
        refine iSup_le ?_
        intro q
        rcases p.2 with ⟨k, hk, hp⟩
        rcases q.2 with ⟨m, hm, hq⟩
        simpa [← hp, ← hq] using
          ENNReal.ofReal_le_ofReal (le_of_lt (hN k (le_trans hn hk) m (le_trans hn hm)))
    · intro h ε εpos
      rcases h ε εpos with ⟨N, hN⟩
      refine ⟨N, ?_⟩
      intro n hn m hm
      have hdiam : diameter (tailSet pₙ N) < ENNReal.ofReal ε := hN N (le_rfl)
      have hdist : ENNReal.ofReal (dist (pₙ n) (pₙ m)) ≤ diameter (tailSet pₙ N) := by
        unfold diameter
        refine le_iSup_of_le ⟨pₙ n, ⟨n, hn, rfl⟩⟩ ?_
        refine le_iSup_of_le ⟨pₙ m, ⟨m, hm, rfl⟩⟩ ?_
        exact le_rfl
      have hlt : ENNReal.ofReal (dist (pₙ n) (pₙ m)) < ENNReal.ofReal ε :=
        lt_of_le_of_lt hdist hdiam
      rw [ENNReal.ofReal_lt_ofReal_iff εpos] at hlt
      exact hlt

end

section -- 3.10 --
variable {X : Type u} [MetricSpace X]

theorem diameter_closure_eq (E : Set X) :
  diameter (closure E) = diameter E := by
    /-
      Since the property of closure,
        each openball of every points in closure,
          the inter of the openball and the original set not emmpty.
      So for each points pair in closure
        for each ε / 2 > 0 as the radius of openball,
          there is another pair in original set,
            which have the distance with the original points pair
              smaller then ε / 2.
      Thus we got diameter of points in closure is larger
        than diameter of points in original set with a ε,
          since the arbitrary of ε, two diameter just equa.
    -/
    apply le_antisymm
    · by_cases htop : diameter E = ⊤
      · rw [htop]
        exact le_top
      · have hEtop : diameter E < ⊤ := lt_of_le_of_ne le_top htop
        refine ENNReal.le_of_forall_pos_le_add ?_
        intro ε εpos _
        unfold diameter
        refine iSup_le ?_
        intro p
        refine iSup_le ?_
        intro q
        have hεreal : 0 < ((ε : ℝ) / 2) := by
          positivity
        rcases Metric.mem_closure_iff.mp p.2 ((ε : ℝ) / 2) hεreal with ⟨x, hxE, hpx⟩
        rcases Metric.mem_closure_iff.mp q.2 ((ε : ℝ) / 2) hεreal with ⟨y, hyE, hqy⟩
        have hxy : ENNReal.ofReal (dist x y) ≤ diameter E := by
          unfold diameter
          refine le_iSup_of_le ⟨x, hxE⟩ ?_
          refine le_iSup_of_le ⟨y, hyE⟩ ?_
          simp
        have hdist : dist p.1 q.1 ≤ dist x y + ε := by
          have hyq : dist y q.1 < (ε : ℝ) / 2 := by
            simpa [dist_comm] using hqy
          have hdist' : dist p.1 q.1 < dist x y + ε := by
            have htri : dist p.1 q.1 ≤ dist p.1 x + dist x y + dist y q.1 :=
              dist_triangle4 p.1 x y q.1
            nlinarith
          exact le_of_lt hdist'
        have hdist' : ENNReal.ofReal (dist p.1 q.1) ≤ diameter E + ε := by
          calc
            ENNReal.ofReal (dist p.1 q.1) ≤ ENNReal.ofReal (dist x y + ε) :=
              ENNReal.ofReal_le_ofReal hdist
            _ = ENNReal.ofReal (dist x y) + ε := by
              simpa using
                ENNReal.ofReal_add dist_nonneg
                  (show 0 ≤ (ε : ℝ) by exact_mod_cast (le_of_lt εpos))
            _ ≤ diameter E + ε := by
              simpa [add_comm, add_left_comm, add_assoc] using add_le_add_right hxy ε
        exact hdist'
    · unfold diameter
      refine iSup_le ?_
      intro p
      refine iSup_le ?_
      intro q
      refine le_iSup_of_le ⟨p.1, subset_closure p.2⟩ ?_
      refine le_iSup_of_le ⟨q.1, subset_closure q.2⟩ ?_
      simp

theorem singleton_intersection_of_nested_compact
  (K : ℕ → Set X)
  (hKcmp : ∀ n : ℕ, IsCompact (K n))
  (hKnest : ∀ n : ℕ, K n ⊇ K (n + 1))
  (hKdiam : ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, diameter (K n) < ENNReal.ofReal ε) :
  ∃! p : X, ∀ n : ℕ, p ∈ K n := by
    sorry

end

section -- 3.11 3.12 --
variable {X : Type u} [MetricSpace X]

theorem convergent_implies_cauchy (pₙ : ℕ → X) :
  convergent X pₙ → cauchySequence pₙ := by
    sorry

theorem cauchySequence_converges_in_compactSpace [CompactSpace X] (pₙ : ℕ → X) :
  cauchySequence pₙ → convergent X pₙ := by
    sorry

theorem cauchySequence_converges_in_euclidean
  {n : ℕ} (pₙ : ℕ → Fin n → ℝ) :
  cauchySequence pₙ → convergent (Fin n → ℝ) pₙ := by
    sorry

def completeMetricSpace (X : Type*) [MetricSpace X] : Prop :=
  ∀ pₙ : ℕ → X, cauchySequence pₙ → convergent X pₙ

theorem compactSpace_complete [CompactSpace X] :
  completeMetricSpace X := by
    sorry

theorem euclideanSpace_complete (n : ℕ) :
  completeMetricSpace (Fin n → ℝ) := by
    sorry

theorem closed_subset_of_complete_is_complete
  (Y : Set X) (hYclosed : IsClosed Y) (hXcomplete : completeMetricSpace X) :
  completeMetricSpace Y := by
    sorry

end

section -- 3.13 3.14 --
def monotoneIncreasing (sₙ : ℕ → ℝ) : Prop :=
  ∀ n : ℕ, sₙ n ≤ sₙ (n + 1)

def monotoneDecreasing (sₙ : ℕ → ℝ) : Prop :=
  ∀ n : ℕ, sₙ (n + 1) ≤ sₙ n

def monotoneSequence (sₙ : ℕ → ℝ) : Prop :=
  monotoneIncreasing sₙ ∨ monotoneDecreasing sₙ

theorem monotoneSequence_convergent_iff_bounded (sₙ : ℕ → ℝ) :
  monotoneSequence sₙ → (convergent ℝ sₙ ↔ sequenceBounded sₙ) := by
    sorry

end

end Subsequences
