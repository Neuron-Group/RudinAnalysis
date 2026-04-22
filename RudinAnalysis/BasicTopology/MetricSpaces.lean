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
  ∀ b : Balls p, (b.val ∩ S).Nonempty

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

section -- 2.31 --
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
theorem compact_iff_finite_subcover (E : Set X) : IsCompact E
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
      unfold IsFiniteCover
      rw [G'df]
      simp only [SubCover.val, SubCover.toOpenCover]
      rw [ι'df]
      exact finE
    exact ⟨G', this⟩

end

end MetricSpaces
