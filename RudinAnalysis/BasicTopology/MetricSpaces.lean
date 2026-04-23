import RudinAnalysis.BasicTopology.Import

set_option linter.style.lambdaSyntax false

namespace MetricSpaces

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
  ∀ b : Ball0s p, (b.val ∩ S).Nonempty

def is_bounded {X : Type*} [MetricSpace X] (pₙ : ℕ -> X) : Prop
  := Bounded (Set.range pₙ)

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

theorem open_iff_exists_ball_subset {A : Set X} :
  IsOpen A <-> ∀ a ∈ A, ∃ b : Balls a, b.val ⊆ A := by
    constructor
    · intro hA a ha
      rcases Metric.isOpen_iff.mp hA a ha with ⟨ε, εpos, hε⟩
      refine ⟨⟨Ball a ⟨ε, εpos⟩, ⟨⟨ε, εpos⟩, rfl⟩⟩, ?_⟩
      simpa [Ball] using hε
    · intro hA
      refine Metric.isOpen_iff.mpr ?_
      intro a ha
      rcases hA a ha with ⟨b, hb⟩
      rcases b with ⟨s, hs⟩
      rcases hs with ⟨ε, rfl⟩
      exact ⟨ε, ε.property, by simpa [Ball] using hb⟩

theorem Balls.is_open {p : X} {B : Balls p} : IsOpen B.val := by
  apply open_iff_exists_ball_subset.mpr
  rcases B with ⟨B, ⟨⟨ε, εpos⟩, hB⟩⟩
  intro b binB
  simp only [Ball] at hB binB ⊢
  simp [hB] at binB
  set ε' := (ε - dist b p)/2 with ε'df
  have ε'pos : 0 < ε' := by linarith
  set ball' := Ball b ⟨ε', ε'pos⟩ with ball'df
  use ⟨ball', ⟨⟨ε', ε'pos⟩, ball'df.symm⟩⟩
  simp only [hB]
  intro b' b'inball'
  simp [ball'df, Ball, ε'df] at b'inball'
  field_simp at b'inball'
  have c1 : dist b' p ≤ dist b' b + dist b p := dist_triangle b' b p
  have c2 : dist b' b + dist b p < ε := by linarith
  exact Std.lt_of_le_of_lt c1 c2

theorem Ball0s.is_open {p : X} {B : Ball0s p} : IsOpen B.val := by
  apply open_iff_exists_ball_subset.mpr
  rcases B with ⟨B, ⟨⟨ε, εpos⟩, hB⟩⟩
  intro b binB
  simp only [Ball0] at hB binB ⊢
  simp only [hB, Ball, Set.mem_diff, Set.mem_setOf_eq, Set.mem_singleton_iff] at binB
  have dbp_pos : 0 < dist b p := by
    exact dist_pos.mpr binB.2
  set ε' := min ((ε - dist b p)/2) (dist b p / 2) with ε'df
  have ε'pos : 0 < ε' := by
    rw [ε'df]
    apply lt_min <;> linarith
  set ball' := Ball b ⟨ε', ε'pos⟩ with ball'df
  use ⟨ball', ⟨⟨ε', ε'pos⟩, ball'df.symm⟩⟩
  simp only [hB]
  intro b' hb'
  simp only [ball'df, Ball, ε'df, lt_inf_iff, Set.mem_setOf_eq] at hb'
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

structure OpenCover (E : Set X) where
  ι : Type w
  U : ι → Set X
  isOpen : ∀ i, IsOpen (U i)
  subset_iUnion : E ⊆ ⋃ i, U i

structure SubCover {E : Set X} (G : OpenCover E) where
  ι' : Type w
  idx : ι' → G.ι
  covers : E ⊆ ⋃ a, G.U (idx a)

def SubCover.toOpenCover {E : Set X} {G : OpenCover E} (S : SubCover G) : OpenCover E where
  ι := S.ι'
  U := G.U ∘ S.idx
  isOpen := fun a ↦ G.isOpen (S.idx a)
  subset_iUnion := S.covers

@[reducible]
def SubCover.val {E : Set X} {G : OpenCover E} (S : SubCover G) : OpenCover E :=
  S.toOpenCover
def IsFiniteCover {E : Set X} : OpenCover E -> Prop
  := λ G ↦ Finite G.ι

/-
  This exactly a definition (not a theorem) in Rudin's book,
    but now we need this to uniform the notion of compact property
      between book and mathlib.
  Skip it.
-/
open Classical in
theorem compact_iff_finite_subcover {E : Set X} : IsCompact E
  <-> ∀ G : OpenCover E, ∃ G' : SubCover G, IsFiniteCover G'.val := by
    constructor
    · intro hG G
      classical
      obtain ⟨t, ht⟩ := hG.elim_finite_subcover (fun i : G.ι => G.U i) G.isOpen G.subset_iUnion
      refine ⟨{ ι' := {i : G.ι // i ∈ t}, idx := fun a => a.1, covers := ?_ }, ?_⟩
      · simpa [Set.iUnion_subtype] using ht
      · change Finite {i : G.ι // i ∈ t}
        exact inferInstance
    · intro hG
      classical
      refine (isCompact_iff_finite_subcover.2 ?_)
      intro ι U hUo hsU
      let G : OpenCover E :=
        { ι := ι
          U := U
          isOpen := hUo
          subset_iUnion := hsU }
      rcases hG G with ⟨G', hfinite⟩
      letI : Finite G'.ι' := hfinite
      letI : Fintype G'.ι' := Fintype.ofFinite G'.ι'
      refine ⟨Finset.univ.image G'.idx, ?_⟩
      intro y hy
      rcases Set.mem_iUnion.mp (G'.covers hy) with ⟨α, hα⟩
      exact Set.mem_biUnion
        (s := ((Finset.univ.image G'.idx : Finset ι) : Set ι))
        (t := U) (x := G'.idx α)
        (Finset.mem_image.mpr ⟨α, Finset.mem_univ _, rfl⟩) hα

open Classical in
example (E : Set X) (finE : E.Finite)
  : ∀ G : OpenCover E, ∃ G' : SubCover G, IsFiniteCover G'.val := by
    intro G
    have := G.subset_iUnion
    choose f hf using this
    choose g hg using hf
    choose h hh using g
    set ι' := E.Elem with ι'df
    set idx : ι' -> G.ι
      := λ i ↦ h i.2
        with idx_df
    set G' : SubCover G := {
      ι',
      idx,
      covers := by
        intro e einE
        simp only [Set.mem_iUnion]
        set U' := f einE
          with U'df
        have feq := hh einE
        set i : E.Elem := ⟨e, einE⟩
          with idf
        use i
        simp only [idx_df, idf, feq]
        exact hg einE
    } with G'df
    have : IsFiniteCover G'.val := by
      simp only [SubCover.val, SubCover.toOpenCover]
      exact finE
    exact ⟨G', this⟩

end

section -- 2.33 --
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
end

section -- 2.37 --
variable {X : Type w} [MetricSpace X]

open Classical in
example (E K : Set X) (infE : Infinite E) (cmpK : IsCompact K) (EsubK : E ⊆ K) :
  ∃ p ∈ K, limit_point p E := by
    have cmpK := compact_iff_finite_subcover.mp cmpK
    by_contra hyp
    push Not at hyp
    have hK : ∀ p ∈ K, ∃ b : Ball0s p, ¬ (b.val ∩ E).Nonempty := by
      intro p hp
      simpa [limit_point] using hyp p hp
    choose k hk using hK
    set ε : K.Elem -> {r : ℝ // 0 < r}
      := λ i ↦ Classical.choose (k i.val i.property).property
      with εdf
    have hkBall0 : ∀ i : K.Elem, (k i.val i.property).val = Ball0 i.val (ε i) := by
      intro i
      exact Classical.choose_spec (k i.val i.property).property
    set U : K.Elem -> Set X := λ i ↦ Ball i.val (ε i)
      with Udf
    set G : OpenCover K := {
      ι := K,
      U,
      isOpen := by
        intro i
        rw [Udf]
        exact Balls.is_open (B := ⟨Ball i.val (ε i), ⟨ε i, rfl⟩⟩)
      subset_iUnion := by
        intro k' k'inK
        refine Set.mem_iUnion.mpr ⟨⟨k', k'inK⟩, ?_⟩
        rw [Udf]
        simp only [Ball, Set.mem_setOf_eq, dist_self]
        exact (ε ⟨k', k'inK⟩).property
    }
    specialize cmpK G
    rcases cmpK with ⟨G', hG'⟩
    letI : Finite G'.ι' := hG'
    have hsubset : E ⊆ Set.range (fun a : G'.ι' => (G'.idx a).val) := by
      intro x hxE
      rcases Set.mem_iUnion.mp (G'.covers (EsubK hxE)) with ⟨a, ha⟩
      change x ∈ U (G'.idx a) at ha
      rw [Udf] at ha
      have hs : (k (G'.idx a).val (G'.idx a).property).val = Ball0 (G'.idx a).val (ε (G'.idx a)) :=
        hkBall0 (G'.idx a)
      change x ∈ Ball (G'.idx a).val (ε (G'.idx a)) at ha
      by_cases hxeq : x = (G'.idx a).val
      · exact ⟨a, hxeq.symm⟩
      · have hxBall0 : x ∈ (k (G'.idx a).val (G'.idx a).property).val := by
          rw [hs]
          exact ⟨ha, by simpa using hxeq⟩
        have hxNE : ((k (G'.idx a).val (G'.idx a).property).val ∩ E).Nonempty := ⟨x, hxBall0, hxE⟩
        exact False.elim (hk (G'.idx a).val (G'.idx a).property hxNE)
    have hfin : (Set.range fun a : G'.ι' => (G'.idx a).val).Finite := Set.finite_range _
    exact infE.not_finite (hfin.subset hsubset)

end

end MetricSpaces
