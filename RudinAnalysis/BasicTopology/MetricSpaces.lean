import RudinAnalysis.BasicTopology.Import

set_option linter.style.lambdaSyntax false

namespace MetricSpaces
universe u v w

open Finset

def closedBall {X : Type*} [MetricSpace X] (p : X) (ε : ℝ) : Set X :=
  {s : X | dist s p ≤ ε}

def openBall {X : Type*} [MetricSpace X] (p : X) (ε : ℝ) : Set X :=
  {s : X | dist s p < ε}

def deletedBall {X : Type*} [MetricSpace X] (p : X) (ε : ℝ) : Set X :=
  openBall p ε \ {p}

@[simp] theorem mem_openBall {X : Type*} [MetricSpace X] {p x : X} {ε : ℝ} :
  x ∈ openBall p ε ↔ dist x p < ε := Iff.rfl

@[simp] theorem mem_deletedBall {X : Type*} [MetricSpace X] {p x : X} {ε : ℝ} :
  x ∈ deletedBall p ε ↔ dist x p < ε ∧ x ≠ p := Iff.rfl

def IsBounded {X : Type*} [MetricSpace X] (s : Set X) : Prop :=
  ∃ c : X, ∃ R > 0, ∀ x ∈ s, dist x c < R

def limitPoint {X : Type*} [MetricSpace X] (p : X) (S : Set X) : Prop :=
  ∀ ε > 0, (deletedBall p ε ∩ S).Nonempty

def sequenceBounded {X : Type*} [MetricSpace X] (u : ℕ -> X) : Prop :=
  IsBounded (Set.range u)

/-
  We simplly use the definition of Compact Sets and Compact Space in mathlib,
    which may facilitate proving by using the lemmas which are already
      inside the mathlib.
-/
#check CompactSpace
#check IsOpen
#check IsClosed
#check IsCompact

section
variable {X : Type w} [MetricSpace X]

/-
  This exactly a definition (not a theorem) in Rudin's book,
    but now we need this to uniform the notion of compact property
      between book and mathlib.
  Skip it.
-/

theorem isOpen_iff_ball_subset {A : Set X} :
  IsOpen A <-> ∀ a ∈ A, ∃ ε > 0, openBall a ε ⊆ A := by
    constructor
    · intro hA a ha
      rcases Metric.isOpen_iff.mp hA a ha with ⟨ε, εpos, hε⟩
      refine ⟨ε, εpos, ?_⟩
      simpa [openBall] using hε
    · intro hA
      refine Metric.isOpen_iff.mpr ?_
      intro a ha
      rcases hA a ha with ⟨ε, εpos, hε⟩
      exact ⟨ε, εpos, by simpa [openBall] using hε⟩

theorem isOpen_openBall {p : X} {ε : ℝ} : IsOpen (openBall p ε) := by
  apply isOpen_iff_ball_subset.mpr
  intro b binB
  simp only [openBall, Set.mem_setOf_eq] at binB ⊢
  set ε' := (ε - dist b p) / 2 with ε'df
  have ε'pos : 0 < ε' := by linarith
  use ε', ε'pos
  intro b' b'inball'
  simp [ε'df] at b'inball'
  field_simp at b'inball'
  have c1 : dist b' p ≤ dist b' b + dist b p := dist_triangle b' b p
  have c2 : dist b' b + dist b p < ε := by linarith
  exact Std.lt_of_le_of_lt c1 c2

theorem isOpen_deletedBall {p : X} {ε : ℝ} : IsOpen (deletedBall p ε) := by
  apply isOpen_iff_ball_subset.mpr
  intro b binB
  simp only [deletedBall, openBall, Set.mem_diff, Set.mem_setOf_eq,
    Set.mem_singleton_iff] at binB ⊢
  have dbp_pos : 0 < dist b p := by
    exact dist_pos.mpr binB.2
  set ε' := min ((ε - dist b p) / 2) (dist b p / 2) with ε'df
  have ε'pos : 0 < ε' := by
    rw [ε'df]
    apply lt_min <;> linarith
  use ε', ε'pos
  intro b' hb'
  simp only [ε'df, lt_inf_iff, Set.mem_setOf_eq] at hb'
  have c1 : dist b' p ≤ dist b' b + dist b p := dist_triangle b' b p
  have c2 : dist b' b + dist b p < ε := by
    have : dist b' b < (ε - dist b p) / 2 := hb'.1
    linarith
  constructor
  · exact Std.lt_of_le_of_lt c1 c2
  · intro h
    have : dist b p < dist b p / 2 := by
      have : dist b' b < dist b p / 2 := by
        exact hb'.2
      rw [h] at this
      simpa [dist_comm] using this
    linarith

-- 2.20 --
open Classical in
theorem limitPoint_ball_infinite (E : Set X) (p : X) (hp : limitPoint p E) :
  ∀ ε > 0, (openBall p ε ∩ E).Infinite := by
    intro ε εpos hyp
    rcases Set.Finite.exists_finset_coe hyp with ⟨S, hS⟩
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
        have hxnbhE : x ∈ openBall p ε ∩ E := by
          have : x ∈ (S : Set X) := by simpa using hxS
          rw [hS] at this
          exact this
        exact lt_of_le_of_lt
          (Finset.inf'_le (s := T) (f := fun y ↦ dist y p) hxT)
          hxnbhE.1
      set δ : ℝ := min ε (r / 2) with δdf
      have hδpos : 0 < δ := by
        rw [δdf]
        apply lt_min
        · exact εpos
        · linarith
      have hδ : (deletedBall p δ ∩ E).Nonempty := hp δ hδpos
      rcases hδ with ⟨x, hxδ, hxE⟩
      have hxdist : dist x p < δ := by
        simpa [deletedBall, openBall] using hxδ.1
      have hxne : x ≠ p := by
        simpa [deletedBall] using hxδ.2
      have hxnbh : x ∈ openBall p ε := by
        have : dist x p < ε := lt_of_lt_of_le hxdist (by rw [δdf]; exact min_le_left _ _)
        simpa [openBall] using this
      have hxS : x ∈ S := by
        have : x ∈ (S : Set X) := by
          rw [hS]
          exact ⟨hxnbh, hxE⟩
        simpa using this
      have hxT : x ∈ T := by
        exact Finset.mem_erase.mpr ⟨hxne, hxS⟩
      have hr_le : r ≤ dist x p := by
        exact Finset.inf'_le (s := T) (f := fun y ↦ dist y p) hxT
      have hlt_half : dist x p < r / 2 := by
        rw [δdf] at hxdist
        exact lt_of_lt_of_le hxdist (min_le_right _ _)
      linarith
    · have hδ : (deletedBall p ε ∩ E).Nonempty := hp ε εpos
      rcases hδ with ⟨x, hxδ, hxE⟩
      have hxnbh : x ∈ openBall p ε := by
        simpa [deletedBall, openBall] using hxδ.1
      have hxS : x ∈ S := by
        have : x ∈ (S : Set X) := by
          rw [hS]
          exact ⟨hxnbh, hxE⟩
        simpa using this
      have hxT : x ∈ T := by
        have hxne : x ≠ p := by
          simpa [deletedBall] using hxδ.2
        exact Finset.mem_erase.mpr ⟨hxne, hxS⟩
      exact hT ⟨x, hxT⟩

-- 2.30 --
open Classical in
theorem open_induced_iff_exists_open_inter {E Y : Set X} (EsubY : E ⊆ Y) :
  IsOpen (Subtype.val ⁻¹' E : Set Y) <-> ∃ G, IsOpen G ∧ E = Y ∩ G := by
    constructor
    · intro hE
      rcases isOpen_induced_iff.mp hE with ⟨G, hG, hEq⟩
      refine ⟨G, hG, ?_⟩
      ext x
      constructor
      · intro hx
        constructor
        · exact EsubY hx
        · have hx' : (⟨x, EsubY hx⟩ : Y) ∈ Subtype.val ⁻¹' G := by
            rwa [hEq]
          exact hx'
      · intro hx
        have hx' : (⟨x, hx.1⟩ : Y) ∈ Subtype.val ⁻¹' E := by
          rw [← hEq]
          exact hx.2
        exact hx'
    · rintro ⟨G, hG, rfl⟩
      exact isOpen_induced_iff.mpr ⟨G, hG, by ext y; simp⟩

end

section -- 2.31 2.32 --
variable {X : Type w} [MetricSpace X]

structure OpenCover (E : Set X) (ι : Type v) where
  U       : ι -> Set X
  isOpen  : ∀ i, IsOpen (U i)
  covers  : E ⊆ ⋃ i, U i

structure SubCover {E : Set X} {ι : Type v} (G : OpenCover E ι) where
  idxs    : Set ι
  covers  : E ⊆ ⋃ a : idxs, G.U a.1

def OpenCover.IsFinite {E : Set X} {ι : Type v} (_G : OpenCover E ι) : Prop :=
  Finite ι

def SubCover.IsFinite {E : Set X} {ι : Type v} {G : OpenCover E ι} (S : SubCover G) : Prop :=
  Set.Finite S.idxs

def SubCover.toOpenCover {E : Set X} {ι : Type v} {G : OpenCover E ι}
    (S : SubCover G) : OpenCover E S.idxs where
  U       := λ a ↦ G.U a.1
  isOpen  := λ a ↦ G.isOpen a.1
  covers  := S.covers

/-
  This exactly a definition (not a theorem) in Rudin's book,
    but now we need this to uniform the notion of compact property
      between book and mathlib.
  Skip it.
-/
open Classical in
theorem compact_iff_finite_subcover {E : Set X} : IsCompact E
  <-> ∀ (ι : Type w) (G : OpenCover E ι), ∃ G' : SubCover G, G'.IsFinite := by
    constructor
    · intro hG ι G
      classical
      obtain ⟨t, ht⟩ := hG.elim_finite_subcover (fun i : ι ↦ G.U i) G.isOpen G.covers
      refine ⟨{ idxs := t, covers := ?_ }, ?_⟩
      · simpa [Set.iUnion_subtype] using ht
      · exact Finset.finite_toSet t
    · intro hG
      classical
      refine (isCompact_iff_finite_subcover.2 ?_)
      intro ι U hUo hsU
      let G : OpenCover E ι := {
        U := U
        isOpen := hUo
        covers := hsU
      }
      rcases hG ι G with ⟨G', hfinite⟩
      letI : Finite G'.idxs := hfinite.to_subtype
      letI : Fintype G'.idxs := Fintype.ofFinite G'.idxs
      refine ⟨Finset.univ.image (fun a : G'.idxs ↦ a.1), ?_⟩
      intro y hy
      rcases Set.mem_iUnion.mp (G'.covers hy) with ⟨α, hα⟩
      exact Set.mem_biUnion
        (s := ((Finset.univ.image (fun a : G'.idxs ↦ a.1) : Finset ι) : Set ι))
        (t := U) (x := α.1)
        (Finset.mem_image.mpr ⟨α, Finset.mem_univ _, rfl⟩) hα

open Classical in
theorem finite_subcover_of_compact {E : Set X} (hE : IsCompact E) :
  ∀ (ι : Type w) (G : OpenCover E ι), ∃ G' : SubCover G, G'.IsFinite := by
    intro ι G
    obtain ⟨t, ht⟩ := hE.elim_finite_subcover (fun i : ι ↦ G.U i) G.isOpen G.covers
    refine ⟨{ idxs := t, covers := ?_ }, ?_⟩
    · simpa [Set.iUnion_subtype] using ht
    · exact Finset.finite_toSet t

open Classical in
example (E : Set X) (finE : E.Finite)
  : ∀ (ι : Type w) (G : OpenCover E ι), ∃ G' : SubCover G, G'.IsFinite := by
    intro ι G
    have hcov : ∀ e ∈ E, ∃ i : ι, e ∈ G.U i := by
      intro e einE
      simpa [Set.mem_iUnion] using G.covers einE
    choose idx hidx using hcov
    letI : Finite E.Elem := finE.to_subtype
    refine ⟨{
      idxs := Set.range (fun e : E.Elem ↦ idx e.1 e.2)
      covers := by
        intro e einE
        refine Set.mem_iUnion.mpr ?_
        exact ⟨⟨idx e einE, ⟨⟨e, einE⟩, rfl⟩⟩, hidx e einE⟩
    }, by
      simpa using Set.finite_range (fun e : E.Elem ↦ idx e.1 e.2)⟩

end

section -- 2.33 2.34 --
variable {X : Type w} [MetricSpace X]

theorem isCompact_induced_iff (K Y : Set X) (KsubY : K ⊆ Y) :
  IsCompact K <-> IsCompact (Subtype.val ⁻¹' K : Set Y) := by
    rw [Subtype.isCompact_iff]
    have himage : (Subtype.val '' (Subtype.val ⁻¹' K : Set Y) : Set X) = K := by
      ext x
      constructor
      · rintro ⟨y, hy, rfl⟩
        exact hy
      · intro hx
        exact ⟨⟨x, KsubY hx⟩, hx, rfl⟩
    simp [himage]

theorem isClosed_of_isCompact {K : Set X} (hK : IsCompact K) : IsClosed K :=
  hK.isClosed
end

section -- 2.36 --
variable {X : Type w} [MetricSpace X]

/-
  Rudin 2.36:
  A family of compact sets with the finite intersection property
  has nonempty total intersection.
-/
theorem nonempty_iInter_of_finite_intersections
  {ι : Type w} (K : ι → Set X)
  (hKcmp : ∀ i : ι, IsCompact (K i))
  (hfinite : ∀ s : Finset ι, (⋂ i ∈ s, K i).Nonempty) :
  (⋂ i : ι, K i).Nonempty := by
    classical
    by_contra hyp
    · push Not at hyp
      have ι_nonempty : Nonempty ι := by
        by_contra ι_empt
        push Not at ι_empt
        have : ⋂ i, K i = (Set.univ : Set X) := by
          exact Set.iInter_of_empty K
        rw [hyp] at this
        have hnonempty : (⋂ i, K i).Nonempty := by
          simpa [this] using hfinite (∅ : Finset ι)
        rw [hyp] at hnonempty
        exact Set.not_nonempty_empty hnonempty
      have ι_set_nonempty : (Set.univ : Set ι).Nonempty := by
        exact Set.nonempty_iff_univ_nonempty.mp ι_nonempty
      rcases ι_set_nonempty with ⟨one, hone⟩
      set K_one := K one with K_one_df
      have K_one_compact : IsCompact K_one := hKcmp one
      set Gα : OpenCover K_one ι := {
        U       := λ i ↦ (K i)ᶜ
        isOpen  := λ i ↦ by
          have := isClosed_of_isCompact (hKcmp i)
          exact IsClosed.isOpen_compl
        covers  := by
          intro k hk
          have k_not_in_inter : k ∉ ⋂ i, K i
            := of_eq_false (congrFun hyp k)
          have := Set.iInter_eq_compl_iUnion_compl K
          rw [this] at k_not_in_inter
          exact Set.not_notMem.mp k_not_in_inter
      }
      rcases (compact_iff_finite_subcover.mp
        K_one_compact ι Gα) with ⟨⟨ι', hι'⟩, hG'⟩
      simp [SubCover.IsFinite] at hG'
      let s : Finset ι := hG'.toFinset ∪ {one}
      have hs_empty : (⋂ i ∈ s, K i) = (∅ : Set X) := by
        ext x
        constructor
        · intro hx
          have hxKone : x ∈ K one := by
            have : x ∈ ⋂ i ∈ s, K i := hx
            simp only [union_singleton, mem_insert, Set.Finite.mem_toFinset,
              Set.iInter_iInter_eq_or_left, Set.mem_inter_iff, Set.mem_iInter, s] at this
            exact this.1
          have hxcover : x ∈ ⋃ a : ι', (K a.1)ᶜ := hι' hxKone
          rcases Set.mem_iUnion.mp hxcover with ⟨a, hxa⟩
          have hxKa : x ∈ K a.1 := by
            have : x ∈ ⋂ i ∈ s, K i := hx
            simp only [union_singleton, mem_insert, Set.Finite.mem_toFinset,
              Set.iInter_iInter_eq_or_left, Set.mem_inter_iff, Set.mem_iInter, s] at this
            exact this.2 a.1 a.property
          exact False.elim (hxa hxKa)
        · intro hx
          simp at hx
      have hs_nonempty : ((⋂ i ∈ s, K i) : Set X).Nonempty := hfinite s
      rw [hs_empty] at hs_nonempty
      exact Set.not_nonempty_empty hs_nonempty
end

section -- 2.37 --
variable {X : Type w} [MetricSpace X]

open Classical in
theorem bolzano_weierstrass (E K : Set X) (infE : E.Infinite) (cmpK : IsCompact K) (EsubK : E ⊆ K) :
  ∃ p ∈ K, limitPoint p E := by
    have cmpK := compact_iff_finite_subcover.mp cmpK
    by_contra hyp
    push Not at hyp
    have hK : ∀ p ∈ K, ∃ ε > 0, ¬ (deletedBall p ε ∩ E).Nonempty := by
      intro p hp
      simpa [limitPoint] using hyp p hp
    choose k hk using hK
    set ε : K.Elem → ℝ := λ i ↦ k i.val i.property with εdf
    have hε : ∀ i : K.Elem, 0 < ε i := by
      intro i
      exact (hk i.val i.property).left
    set U : K.Elem -> Set X := λ i ↦ openBall i.val (ε i)
      with Udf
    set G : OpenCover K K.Elem := {
      U,
      isOpen := by
        intro i
        rw [Udf]
        exact isOpen_openBall
      covers := by
        intro k' k'inK
        refine Set.mem_iUnion.mpr ⟨⟨k', k'inK⟩, ?_⟩
        rw [Udf]
        simp only [openBall, Set.mem_setOf_eq, dist_self]
        exact hε ⟨k', k'inK⟩
    }
    specialize cmpK K.Elem G
    rcases cmpK with ⟨G', hG'⟩
    letI : Finite G'.idxs := hG'.to_subtype
    have hsubset : E ⊆ Set.range (fun a : G'.idxs => a.1.val) := by
      intro x hxE
      rcases Set.mem_iUnion.mp (G'.covers (EsubK hxE)) with ⟨a, ha⟩
      change x ∈ U a.1 at ha
      rw [Udf] at ha
      change x ∈ openBall a.1.val (ε a.1) at ha
      by_cases hxeq : x = a.1.val
      · exact ⟨a, hxeq.symm⟩
      · have hxBall0 : x ∈ deletedBall a.1.val (ε a.1) := by
          exact ⟨ha, by simpa using hxeq⟩
        have hxNE : (deletedBall a.1.val (ε a.1) ∩ E).Nonempty := ⟨x, hxBall0, hxE⟩
        exact False.elim ((hk a.1.val a.1.property).right hxNE)
    have hfin : (Set.range fun a : G'.idxs => a.1.val).Finite := Set.finite_range _
    exact infE.not_finite (hfin.subset hsubset)

end

end MetricSpaces
