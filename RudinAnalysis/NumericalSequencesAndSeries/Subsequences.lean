import RudinAnalysis.NumericalSequencesAndSeries.Import
import RudinAnalysis.NumericalSequencesAndSeries.ConvergentSequences

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace Subsequences
open ConvergentSequences

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
theorem pigeonhole_principle_infinite_seq {X : Type*} [Finite X]
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

variable {X : Type*} [MetricSpace X]

open Classical in
example [CompactSpace X] (pₙ : ℕ -> X) :
  ∃ pnₖ : SubSeq pₙ, converge' X pnₖ := by
    by_cases hyp : Finite X
    · obtain ⟨p, hp⟩ := pigeonhole_principle_infinite_seq pₙ
      choose hₖ hhₖ using hp
      set nₖ : ℕ -> ℕ
        := λ k => Nat.rec (hₖ 0) (λ _ prev => hₖ prev) k
          with nₖdf
      have hnₖ : StrictMono nₖ := by
        apply StrictMono.strictmono_nat_iff_forall_succ_lt.mpr
        intro n
        exact (hhₖ
          (Nat.rec (hₖ 0) (fun x prev ↦ hₖ prev) n)).left
      set nₖ' : StrictMonoSeq := ⟨nₖ, hnₖ⟩ with nₖ'df
      set pnₖ : SubSeq pₙ := {nₖ := nₖ'} with pnₖdf
      use pnₖ; use p;
      intro _ εpos; use 0; intro n nnonneg
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
      exact RCLike.ofReal_pos.mp εpos
    · sorry

end

end Subsequences
