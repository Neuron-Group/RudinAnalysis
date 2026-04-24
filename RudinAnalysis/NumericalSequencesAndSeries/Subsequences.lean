import RudinAnalysis.NumericalSequencesAndSeries.Import
import RudinAnalysis.NumericalSequencesAndSeries.ConvergentSequences

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace Subsequences
open ConvergentSequences MetricSpaces

section -- 3.5 --
variable {X : Type*} [MetricSpace X]

def StrictMono (f : ℕ → ℕ) : Prop :=
  ∀ k₁ k₂, k₁ < k₂ → f k₁ < f k₂

def StrictMonoSeq : Type := { f : ℕ → ℕ // StrictMono f }

theorem StrictMono.strictmono_nat_iff_forall_succ_lt {f : ℕ -> ℕ} :
  StrictMono f <-> ∀ n, f n < f (Nat.succ n)
  := by
    constructor
    · intro hyp n
      have : n < Nat.succ n := Nat.lt_add_one n
      exact hyp n (Nat.succ n) this
    · intro hyp k₁ k₂ lt
      induction k₂ with
      | zero =>
        exfalso
        have : ¬ k₁ < 0 := Nat.not_lt_zero k₁
        exact Nat.not_succ_le_zero k₁ lt
      | succ k₂ h =>
        by_cases lt' : k₁ < k₂ + 1
        · have c1 : f k₁ ≤ f k₂ := by
            by_cases c : k₁ = k₂
            · rw [c]
            · have : k₁ < k₂ := by
                refine Nat.lt_of_le_of_ne ?_ c
                · exact Nat.le_of_lt_succ lt
              specialize h this
              exact Nat.le_of_succ_le h
          have c2 : f k₂ < f (k₂ + 1) := by
            exact hyp k₂
          exact Nat.lt_of_le_of_lt c1 (hyp k₂)
        · contradiction

theorem eventually_ge_of_strictMono (nₖ : StrictMonoSeq) (N : ℕ) :
  ∃ K, ∀ k ≥ K, nₖ.val k ≥ N := by
    induction N with
    | zero =>
      use 0; intro k _;
      exact Nat.zero_le (nₖ.val k)
    | succ N h =>
      rcases h with ⟨K, h⟩
      set K' := K + 1 with K'df
      specialize h K (by linarith)
      use K'; intro k hk
      have kltK : k > K := Nat.lt_of_succ_le hk
      have : nₖ.val k > nₖ.val K := nₖ.prop K k kltK
      have : nₖ.val k ≥ nₖ.val K + 1 := Order.add_one_le_iff.mpr this
      linarith only [this, h]

@[ext]
structure SubSeq (pₙ : ℕ -> X) where
  nₖ  : StrictMonoSeq

def SubSeq.val (pₙ : ℕ → X) (s : SubSeq pₙ) : ℕ → X :=
  pₙ ∘ s.nₖ.val

instance (pₙ : ℕ → X) : CoeFun (SubSeq pₙ) (fun _ => ℕ → X) where
  coe s := SubSeq.val pₙ s

theorem subseq_converge_iff_converge (pₙ : ℕ -> X) (p : X) :
  converge_to X pₙ p <-> ∀ pnₖ : SubSeq pₙ, converge_to X pnₖ p := by
    constructor

    · intro cvp pnₖ ε εpos
      specialize cvp ε εpos
      rcases cvp with ⟨N, cvp⟩
      rcases eventually_ge_of_strictMono pnₖ.nₖ N with ⟨K, Kh⟩
      use K; intro k kgeK;
      specialize Kh k kgeK
      specialize cvp (pnₖ.nₖ.val k) Kh
      simpa [SubSeq.val, CoeFun.coe] using cvp

    · intro hyp
      set p_id : SubSeq pₙ := ⟨
        λ n ↦ n,
        (by
          intro _ _ h
          exact h
        )
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
example [CompactSpace X] (pₙ : ℕ -> X) :
  ∃ pnₖ : SubSeq pₙ, converge' X pnₖ := by
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
        apply StrictMono.strictmono_nat_iff_forall_succ_lt.mpr
        intro n
        exact (hhₖ
          (Nat.rec (hₖ 0) (fun x prev ↦ hₖ prev) n)).left
      set nₖ' : StrictMonoSeq := ⟨nₖ, hnₖ⟩ with nₖ'df
      set pnₖ : SubSeq pₙ := {nₖ := nₖ'} with pnₖdf
      use pnₖ; use p; intro ε εpos
      use 0; intro n nnonneg;
      have : SubSeq.val pₙ pnₖ n = p := by
        simp only [SubSeq.val, Function.comp_apply]
        rw [pnₖdf, nₖ'df]
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
      have hInfBall : ∀ b : Ball0s p, (b.val ∩ E).Infinite := by
        intro b hfin
        rcases Set.Finite.exists_finset_coe hfin with ⟨S, hS⟩
        let T : Finset X := S.erase p
        by_cases hT : T.Nonempty
        · let r : ℝ := T.inf' hT (fun x ↦ dist x p)
          have hr_pos : 0 < r := by
            rw [show r = T.inf' hT (fun x ↦ dist x p) by rfl]
            exact (Finset.lt_inf'_iff (H := hT)).2 fun x hx ↦ by
              have hxp : x ≠ p := (Finset.mem_erase.mp (by simpa [T] using hx)).1
              exact dist_pos.mpr hxp
          have hr_nbh : r < b.ε := by
            let x := hT.choose
            have hxT : x ∈ T := hT.choose_spec
            have hxS : x ∈ S := (Finset.mem_erase.mp hxT).2
            have hxbE : x ∈ b.val ∩ E := by
              have : x ∈ (S : Set X) := by simpa using hxS
              rw [hS] at this
              exact this
            exact lt_of_le_of_lt
              (Finset.inf'_le (s := T) (f := fun y ↦ dist y p) hxT)
              hxbE.1.1
          let δ : {t : ℝ // 0 < t} := ⟨min b.ε (r / 2), by
            apply lt_min
            · exact b.ε.property
            · linarith
          ⟩
          have hδ : ((Ball0s.mk δ : Ball0s p).val ∩ E).Nonempty := limp (Ball0s.mk δ)
          rcases hδ with ⟨x, hxδ, hxE⟩
          have hxb : x ∈ b.val := by
            have : dist x p < b.ε := lt_of_lt_of_le hxδ.1 (min_le_left _ _)
            simpa [Ball0s.val, Ball0, Ball] using ⟨this, hxδ.2⟩
          have hxS : x ∈ S := by
            have : x ∈ (S : Set X) := by
              rw [hS]
              exact ⟨hxb, hxE⟩
            simpa using this
          have hxT : x ∈ T := by
            exact Finset.mem_erase.mpr ⟨by simpa [Ball0s.val, Ball0] using hxδ.2, hxS⟩
          have hr_le : r ≤ dist x p := by
            exact Finset.inf'_le (s := T) (f := fun y ↦ dist y p) hxT
          have hlt_half : dist x p < r / 2 := by
            exact lt_of_lt_of_le hxδ.1 (min_le_right _ _)
          linarith
        · have hδ : ((Ball0s.mk b.ε : Ball0s p).val ∩ E).Nonempty := limp (Ball0s.mk b.ε)
          rcases hδ with ⟨x, hxδ, hxE⟩
          have hxb : x ∈ b.val := by
            simpa [Ball0s.val, Ball0] using hxδ
          have hxS : x ∈ S := by
            have : x ∈ (S : Set X) := by
              rw [hS]
              exact ⟨hxb, hxE⟩
            simpa using this
          have hxT : x ∈ T := by
            exact Finset.mem_erase.mpr ⟨by simpa [Ball0s.val, Ball0] using hxδ.2, hxS⟩
          exact hT ⟨x, hxT⟩
      have hp' : ∀ k N : ℕ, ∃ n > N, dist (pₙ n) p < 1 / (↑k + 1) := by
        intro k N
        let b : Ball0s p := ⟨⟨1 / (↑k + 1), Nat.one_div_pos_of_nat⟩⟩
        have hbInf : (b.val ∩ E).Infinite := hInfBall b
        let F : Set X := pₙ '' {n : ℕ | n ≤ N}
        have hFfin : F.Finite := by
          exact Set.Finite.image pₙ (Set.finite_le_nat N)
        have hxexists : ∃ x, x ∈ b.val ∩ E ∧ x ∉ F := by
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
        simpa [b, Ball0s.val, Ball0, Ball] using hxBE.1.1
      choose hₖ hhₖ using hp'
      set nₖ : ℕ → ℕ := λ k ↦ Nat.rec (hₖ 0 0) (λ i prev ↦ hₖ (i + 1) prev) k with nₖdf
      have hnₖ : StrictMono nₖ := by
        apply StrictMono.strictmono_nat_iff_forall_succ_lt.mpr
        intro n
        rw [nₖdf]
        exact (hhₖ (n + 1) _).left
      set nₖ' : StrictMonoSeq := ⟨nₖ, hnₖ⟩ with nₖ'df
      set pnₖ : SubSeq pₙ := {nₖ := nₖ'} with pnₖdf
      use pnₖ
      use p
      intro ε εpos
      obtain ⟨N, hN⟩ : ∃ N : ℕ, 1 / ε - 1 < ↑N := exists_nat_gt (1 / ε - 1)
      use N
      intro n hn
      have hdist : dist (pnₖ n) p < 1 / (↑n + 1) := by
        simp only [SubSeq.val, Function.comp_apply]
        rw [pnₖdf, nₖ'df]
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

end Subsequences
