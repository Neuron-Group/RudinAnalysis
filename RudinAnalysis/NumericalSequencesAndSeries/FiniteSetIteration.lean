import RudinAnalysis.NumericalSequencesAndSeries.Import
import Mathlib.Data.Finset.Powerset
import Mathlib.SetTheory.ZFC.PSet

set_option linter.style.lambdaSyntax false
set_option linter.style.emptyLine false

namespace FiniteSetIteration

open PSet

def fExact : ℕ → PSet := PSet.ofNat

def gExact (n : ℕ) : PSet := PSet.powerset (fExact n)

def hExact (n : ℕ) : PSet := fExact (n + 1)

def f (n : ℕ) : Finset ℕ := Finset.range n

def g (n : ℕ) : Finset (Finset ℕ) := (f n).powerset

def h (n : ℕ) : Finset (Finset ℕ) := (Finset.range (n + 1)).image f

@[simp] theorem mem_f {n a : ℕ} : a ∈ f n ↔ a < n := by
  simp [f]

@[simp] theorem card_f (n : ℕ) : (f n).card = n := by
  simp [f]

@[simp] theorem mem_g {n : ℕ} {A : Finset ℕ} : A ∈ g n ↔ A ⊆ f n := by
  simp [g]

theorem f_injective : Function.Injective f := by
  intro a b hab
  have := congrArg Finset.card hab
  simpa using this

@[simp] theorem mem_h {n : ℕ} {A : Finset ℕ} : A ∈ h n ↔ ∃ k ≤ n, A = f k := by
  constructor
  · intro hA
    simp [h] at hA
    rcases hA with ⟨k, hk, hkA⟩
    exact ⟨k, by simpa using hk, hkA.symm⟩
  · rintro ⟨k, hk, rfl⟩
    simp [h]
    exact ⟨k, by simpa using hk, rfl⟩

theorem card_h (n : ℕ) : (h n).card = n + 1 := by
  rw [h, Finset.card_image_of_injective _ f_injective]
  simp

theorem f_mem_h_iff {a b : ℕ} : f a ∈ h b ↔ a ≤ b := by
  constructor
  · intro ha
    rcases mem_h.mp ha with ⟨k, hk, hEq⟩
    have : a = k := f_injective hEq
    exact this ▸ hk
  · intro hab
    exact mem_h.mpr ⟨a, hab, rfl⟩

theorem optionA_false : ¬ ∀ a b : ℕ, a + b = 3 → (f a ∪ f b).card = 3 := by
  intro hA
  have h := hA 1 2 rfl
  simp [f] at h

theorem optionB_true : ∀ n : ℕ, (h n).card = (f n).card + 1 := by
  intro n
  simp [card_h, card_f]

theorem optionC_false : ¬ ∀ a b : ℕ, a < b ↔ f a ∈ h b := by
  intro hC
  have h00 : 0 < 0 ↔ f 0 ∈ h 0 := hC 0 0
  have : f 0 ∈ h 0 := mem_h.mpr ⟨0, le_rfl, rfl⟩
  exact Nat.lt_irrefl 0 (h00.mpr this)

/-- Option `D` is correct when `ℕ` is interpreted as positive naturals in the set-builder
notation `{f(n) | n ∈ ℕ}`. In our `0`-based Lean indexing, that set is `Set.range (fun n ↦ fExact (n+1))`. -/
theorem optionD_true_posIndex : Set.range (fun n ↦ fExact (n + 1)) = Set.range hExact := by
  ext x
  constructor <;> rintro ⟨n, rfl⟩ <;> exact ⟨n, rfl⟩

/-- If one instead interprets `{f(n) | n ∈ ℕ}` as a `0`-based range, then option `D` fails:
`fExact 0 = ∅` lies in the range of `fExact`, but not in the range of `hExact = fExact ∘ Nat.succ`. -/
theorem optionD_false_zeroBased : Set.range fExact ≠ Set.range hExact := by
  intro hEq
  have hmem : fExact 0 ∈ Set.range fExact := ⟨0, rfl⟩
  have : fExact 0 ∈ Set.range hExact := hEq ▸ hmem
  rcases this with ⟨n, hn⟩
  have hIn : fExact n ∈ hExact n := by
    rw [hExact, fExact, PSet.ofNat, PSet.mem_insert_iff]
    exact Or.inl PSet.Equiv.rfl
  rw [hn, fExact] at hIn
  simpa [PSet.ofNat] using hIn

end FiniteSetIteration
