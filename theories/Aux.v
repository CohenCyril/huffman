(* This program is free software; you can redistribute it and/or      *)
(* modify it under the terms of the GNU Lesser General Public License *)
(* as published by the Free Software Foundation; either version 2.1   *)
(* of the License, or (at your option) any later version.             *)
(*                                                                    *)
(* This program is distributed in the hope that it will be useful,    *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of     *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the      *)
(* GNU Lesser General Public License for more details.                *)
(*                                                                    *)
(* You should have received a copy of the GNU Lesser General Public   *)
(* License along with this program; if not, write to the Free         *)
(* Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA *)
(* 02110-1301 USA                                                     *)

(**********************************************************************
    Proof of Huffman algorithm: Aux.v                                
                                                                     
    Auxillary functions & Theorems                                   
                                                                     
    Definitions:                                                     
      le_bool, map2, first_n, skip_n find_min find_max               
                                                                     
    Theorems: minus, map, app                                        
                                                                     
                                    Laurent.Thery@inria.fr (2003)    
 **********************************************************************)

Require Export List.
Export ListNotations.
Require Export Arith.
From Huffman Require Export sTactic.
Require Import Inverse_Image.
Require Import Wf_nat.

(* Some facts about the minus operator *)
Section Minus.
 
Theorem lt_minus_O : forall n m, m < n -> 0 < n - m.
Proof using.
intros n; elim n; simpl in |- *; auto.
intros m H1; Contradict H1; auto with arith.
intros n1 Rec m; case m; simpl in |- *; auto.
intros m1 H1; apply Rec; apply lt_S_n; auto.
Qed.
 
Theorem le_minus : forall a b : nat, a - b <= a.
Proof using.
intros a; elim a; simpl in |- *; auto.
intros n H b; case b; simpl in |- *; auto.
Qed.
 
Theorem minus_minus_simpl4 :
 forall a b c : nat, b <= c -> c <= a -> a - b - (a - c) = c - b.
Proof using.
intros a b c H H0.
apply plus_minus; auto with arith.
rewrite minus_plus_simpl_l_reverse with (p := b + c).
repeat rewrite plus_assoc_reverse.
rewrite <- le_plus_minus; auto with arith.
repeat rewrite plus_assoc.
rewrite (plus_comm b c).
repeat rewrite plus_assoc_reverse.
rewrite <- le_plus_minus; auto with arith.
repeat rewrite (fun x => plus_comm x a).
rewrite <- minus_plus_simpl_l_reverse; auto with arith.
apply le_trans with (1 := H); auto.
Qed.
 
Theorem plus_minus_simpl4 :
 forall a b c : nat, b <= a -> c <= b -> a - b + (b - c) = a - c.
Proof using.
intros a b c H H0.
apply plus_minus.
rewrite (fun x y => plus_comm (x - y)).
rewrite plus_assoc.
rewrite <- le_plus_minus; auto.
rewrite <- le_plus_minus; auto.
Qed.
 
End Minus.
Hint Resolve le_minus: arith.

(*A function to compare naturals *)
Section LeBool.
 
Fixpoint le_bool (a b : nat) {struct b} : bool :=
  match a, b with
  | O, _ => true
  | S a1, S b1 => le_bool a1 b1
  | _, _ => false
  end.
 
Theorem le_bool_correct1 : forall a b : nat, a <= b -> le_bool a b = true.
Proof using.
intros a; elim a; simpl in |- *; auto.
intros b; case b; simpl in |- *; auto.
intros n H b; case b; simpl in |- *.
intros H1; inversion H1.
intros n0 H0; apply H.
apply le_S_n; auto.
Qed.
 
Theorem le_bool_correct2 : forall a b : nat, b < a -> le_bool a b = false.
Proof using.
intros a; elim a; simpl in |- *; auto.
intros b H1; inversion H1.
intros n H b; case b; simpl in |- *; auto.
intros n0 H0; apply H.
apply lt_S_n; auto.
Qed.
 
Theorem le_bool_correct3 : forall a b : nat, le_bool a b = true -> a <= b.
Proof using.
intros a; elim a; simpl in |- *; auto.
intros b; case b; simpl in |- *; auto with arith.
intros n H b; case b; simpl in |- *; try (intros; discriminate);
 auto with arith.
Qed.
 
Theorem le_bool_correct4 : forall a b : nat, le_bool a b = false -> b <= a.
Proof using.
intros a; elim a; simpl in |- *; auto.
intros b; case b; simpl in |- *; try (intros; discriminate); auto with arith.
intros n H b; case b; simpl in |- *; try (intros; discriminate);
 auto with arith.
Qed.
 
End LeBool.

(* Properties of the fold operator *)
Section Fold.

Variables (A : Type) (B : Type).
Variable f : A -> B -> A.
Variable g : B -> A -> A.
Variable h : A -> A.
 
Theorem fold_left_eta :
 forall l a f1,
 (forall a b, In b l -> f a b = f1 a b) -> fold_left f l a = fold_left f1 l a.
Proof using.
intros l; elim l; simpl in |- *; auto.
intros a l0 H a0 f1 H0.
rewrite H0; auto.
Qed.
 
Theorem fold_left_map :
 forall (C : Type) a l (k : C -> B),
 fold_left f (map k l) a = fold_left (fun a b => f a (k b)) l a.
Proof using.
intros C a l k; generalize a; elim l; simpl in |- *; auto.
Qed.
 
Theorem fold_left_init :
 (forall (a : A) (b : B), h (f a b) = f (h a) b) ->
 forall (a : A) (l : list B), fold_left f l (h a) = h (fold_left f l a).
Proof using.
intros H a l; generalize a; elim l; clear l a; simpl in |- *; auto.
intros a l H0 a0.
rewrite <- H; auto.
Qed.
 
End Fold.

(* Some properties of list operators: app, map, ... *)
Section List.

Variables (A : Type) (B : Type) (C : Type).
Variable f : A -> B.

(* An induction theorem for list based on length *)
Theorem list_length_ind :
 forall P : list A -> Prop,
 (forall l1 : list A,
  (forall l2 : list A, length l2 < length l1 -> P l2) -> P l1) ->
 forall l : list A, P l.
Proof using.
intros P H l;
 apply well_founded_ind with (R := fun x y : list A => length x < length y);
 auto.
apply wf_inverse_image with (R := lt); auto.
apply lt_wf.
Qed.
 
Definition list_length_induction :
  forall P : list A -> Type,
  (forall l1 : list A,
   (forall l2 : list A, length l2 < length l1 -> P l2) -> P l1) ->
  forall l : list A, P l.
Proof.
intros P H l;
 apply
  well_founded_induction_type with (R := fun x y : list A => length x < length y);
 auto.
apply wf_inverse_image with (R := lt); auto.
apply lt_wf.
Defined.

Theorem in_ex_app :
 forall (a : A) (l : list A),
 In a l -> exists l1 : list A, (exists l2 : list A, l = l1 ++ a :: l2).
Proof using.
intros a l; elim l; clear l; simpl in |- *; auto.
intros H; case H.
intros a1 l H [H1| H1]; auto.
exists []; exists l; simpl in |- *; auto.
apply f_equal2 with (f := cons (A:=A)); auto.
case H; auto; intros l1 (l2, Hl2); exists (a1 :: l1); exists l2;
 simpl in |- *; auto.
apply f_equal2 with (f := cons (A:=A)); auto.
Qed.
 
Theorem app_inv_app :
 forall l1 l2 l3 l4 a,
 l1 ++ l2 = l3 ++ a :: l4 ->
 (exists l5 : list A, l1 = l3 ++ a :: l5) \/
 (exists l5, l2 = l5 ++ a :: l4).
Proof using.
intros l1; elim l1; simpl in |- *; auto.
intros l2 l3 l4 a H; right; exists l3; auto.
intros a l H l2 l3 l4 a0; case l3; simpl in |- *.
intros H0; left; exists l; apply f_equal2 with (f := cons (A:=A));
 injection H0; auto.
intros b l0 H0; case (H l2 l0 l4 a0); auto.
injection H0; auto.
intros (l5, H1).
left; exists l5; apply f_equal2 with (f := cons (A:=A)); injection H0; auto.
Qed.
 
Theorem app_inv_app2 :
 forall l1 l2 l3 l4 a b,
 l1 ++ l2 = l3 ++ a :: b :: l4 ->
 (exists l5 : list A, l1 = l3 ++ a :: b :: l5) \/
 (exists l5, l2 = l5 ++ a :: b :: l4) \/
 l1 = l3 ++ a :: [] /\ l2 = b :: l4.
Proof using.
intros l1; elim l1; simpl in |- *; auto.
intros l2 l3 l4 a b H; right; left; exists l3; auto.
intros a l H l2 l3 l4 a0 b; case l3; simpl in |- *.
case l; simpl in |- *.
intros H0; right; right; injection H0; split; auto.
apply f_equal2 with (f := cons (A:=A)); auto.
intros b0 l0 H0; left; exists l0; injection H0; intros;
 repeat apply f_equal2 with (f := cons (A:=A)); auto.
intros b0 l0 H0; case (H l2 l0 l4 a0 b); auto.
injection H0; auto.
intros (l5, HH1); left; exists l5; apply f_equal2 with (f := cons (A:=A));
 auto; injection H0; auto.
intros [H1| (H1, H2)]; auto.
right; right; split; auto; apply f_equal2 with (f := cons (A:=A)); auto;
 injection H0; auto.
Qed.
 
Theorem same_length_ex :
 forall (a : A) l1 l2 l3,
 length (l1 ++ a :: l2) = length l3 ->
 exists l4,
   (exists l5,
      (exists b : B,
         length l1 = length l4 /\ length l2 = length l5 /\ l3 = l4 ++ b :: l5)).
Proof using.
intros a l1; elim l1; simpl in |- *; auto.
intros l2 l3; case l3; simpl in |- *; try (intros; discriminate).
intros b l H; exists []; exists l; exists b; repeat (split; auto).
intros a0 l H l2 l3; case l3; simpl in |- *; try (intros; discriminate).
intros b l0 H0.
case (H l2 l0); auto.
intros l4 (l5, (b1, (HH1, (HH2, HH3)))).
exists (b :: l4); exists l5; exists b1; repeat (simpl in |- *; split; auto).
apply f_equal2 with (f := cons (A:=B)); auto.
Qed.

(* Properties of map *)
Theorem in_map_inv :
 forall (b : B) (l : list A),
 In b (map f l) -> exists a : A, In a l /\ b = f a.
Proof using.
intros b l; elim l; simpl in |- *; auto.
intros tmp; case tmp.
intros a0 l0 H [H1| H1]; auto.
exists a0; auto.
case (H H1); intros a1 (H2, H3); exists a1; auto.
Qed.
 
Theorem in_map_fst_inv :
 forall a (l : list (B * C)),
 In a (map (fst (B:=_)) l) -> exists c, In (a, c) l.
Proof using.
intros a l; elim l; simpl in |- *; auto.
intros H; case H.
intros a0 l0 H [H0| H0]; auto.
exists (snd a0); left; rewrite <- H0; case a0; simpl in |- *; auto.
case H; auto; intros l1 Hl1; exists l1; auto.
Qed.

(* Properties of flat_map *)
Theorem in_flat_map_in :
 forall (l : list B) (f : B -> list C) a b,
 In a (f b) -> In b l -> In a (flat_map f l).
Proof using.
intros; apply in_flat_map; exists b; split; auto.
Qed.
 
Theorem in_flat_map_ex :
 forall (l : list B) (f : B -> list C) a,
 In a (flat_map f l) -> exists b, In b l /\ In a (f b).
Proof using.
intros; apply in_flat_map; auto.
Qed.
 
End List.

(* Definition of a map2 *)
Section map2.
Variables (A : Type) (B : Type) (C : Type).
Variable f : A -> B -> C.
 
Fixpoint map2 (l1 : list A) : list B -> list C :=
  fun l2 =>
  match l1 with
  | [] => []
  | a :: l3 =>
      match l2 with
      | [] => []
      | b :: l4 => f a b :: map2 l3 l4
      end
  end.
 
Theorem map2_app :
 forall l1 l2 l3 l4,
 length l1 = length l2 ->
 map2 (l1 ++ l3) (l2 ++ l4) = map2 l1 l2 ++ map2 l3 l4.
Proof using.
intros l1; elim l1; auto.
intros l2; case l2; simpl in |- *; auto; intros; discriminate.
intros a l H l2 l3 l4; case l2.
simpl in |- *; intros; discriminate.
intros b l0 H0.
apply trans_equal with (f a b :: map2 (l ++ l3) (l0 ++ l4)).
simpl in |- *; auto.
rewrite H; auto.
Qed.
 
End map2.
Arguments map2 [A B C].

(* Definitions of the first and skip function *)
Section First.
Variable A : Type.

(* Properties of first_n *)
Theorem firstn_le_app1 :
 forall (n : nat) (l1 l2 : list A),
 length l1 <= n -> firstn n (l1 ++ l2) = l1 ++ firstn (n - length l1) l2.
Proof using.
intros n; elim n; simpl in |- *; auto.
intros l1; case l1; simpl in |- *; auto.
intros b l l2 H; contradict H; auto with arith.
intros n0 H l1; case l1; simpl in |- *; auto with arith.
intros b l l2 H0; rewrite H; auto with arith.
Qed.
 
Theorem firstn_le_app2 :
 forall (n : nat) (l1 l2 : list A),
 n <= length l1 -> firstn n (l1 ++ l2) = firstn n l1.
Proof using.
intros n; elim n; simpl in |- *; auto.
intros n0 H l1 l2; case l1; simpl in |- *.
intros H1; contradict H1; auto with arith.
intros a l H0; (apply f_equal2 with (f := cons (A:=A)); auto).
apply H; apply le_S_n; auto.
Qed.

Theorem firstn_le_length_eq :
 forall (n : nat) (l1 : list A), n <= length l1 -> length (firstn n l1) = n.
Proof using.
intros n l1; generalize n; elim l1; clear n l1; simpl in |- *; auto.
intros n; case n; simpl in |- *; auto.
intros n1 H1; contradict H1; auto with arith.
intros a l H n; case n; simpl in |- *; auto with arith.
Qed.

Theorem skipn_le_app1 :
 forall (n : nat) (l1 l2 : list A),
 length l1 <= n -> skipn n (l1 ++ l2) = skipn (n - length l1) l2.
Proof using.
intros n; elim n; simpl in |- *; auto.
intros l1; case l1; simpl in |- *; auto.
intros b l l2 H; Contradict H; auto with arith.
intros n0 H l1; case l1; simpl in |- *; auto with arith.
Qed.
 
Theorem skipn_le_app2 :
 forall (n : nat) (l1 l2 : list A),
 n <= length l1 -> skipn n (l1 ++ l2) = skipn n l1 ++ l2.
Proof using.
intros n; elim n; simpl in |- *; auto.
intros n0 H l1; case l1; simpl in |- *; auto with arith.
intros l2 H1; Contradict H1; auto with arith.
Qed.

(* skipn_length in >= 8.10 *)
Theorem length_skipn :
 forall (n : nat) (l1 : list A), length (skipn n l1) = length l1 - n.
Proof using.
intros n; elim n; simpl in |- *; auto with arith.
intros n0 H l1; case l1; simpl in |- *; auto.
Qed.

(* skipn_all in >= 8.10 *)
Theorem skipn_length_all :
 forall l : list A, skipn (length l) l = [].
Proof using.
intros l; elim l; simpl in |- *; auto.
Qed.

End First.

(* Existence of a first max *)
Section FirstMax.
 
Theorem exist_first_max :
 forall l : list nat,
 l <> [] ->
 exists a : nat,
   (exists l1 : list nat,
      (exists l2 : list nat,
         l = l1 ++ a :: l2 /\
         (forall n1, In n1 l1 -> n1 < a) /\ (forall n1, In n1 l2 -> n1 <= a))).
Proof using.
intros l; elim l; simpl in |- *; auto.
intros H; case H; auto.
intros a l0; case l0.
intros H H0; exists a; exists []; exists [];
 repeat (split; simpl in |- *; auto with datatypes).
intros n1 H1; case H1.
intros n1 H1; case H1.
intros n l1 H H0; case H; clear H; auto.
red in |- *; intros H1; discriminate; auto.
intros a1 (l2, (l3, (HH1, (HH2, HH3)))).
case (le_or_lt a1 a); intros HH4; auto.
exists a; exists []; exists (n :: l1);
 repeat (split; auto with datatypes).
intros n1 H1; case H1.
rewrite HH1.
intros n1 H1; apply le_trans with (2 := HH4); case in_app_or with (1 := H1);
 auto with arith.
intros H2; apply lt_le_weak; auto.
simpl in |- *; intros [H2| H2]; [ rewrite H2 | idtac ]; auto.
exists a1; exists (a :: l2); exists l3;
 repeat (split; simpl in |- *; auto with datatypes).
apply f_equal2 with (f := cons (A:=nat)); auto.
intros n1 [H2| H2]; [ rewrite <- H2 | idtac ]; auto.
Qed.
 
End FirstMax.

(* Find the minimum and the maximun in a list *)
Section FindMin.
Variable A : Type.
Variable f : A -> nat.

(* Search in the list for the min with respect to a valuation function f *)
Fixpoint find_min (l : list A) : option (nat * A) :=
  match l with
  | [] => None
  | a :: l1 =>
      match find_min l1 with
      | None => Some (f a, a)
      | Some (n1, b) =>
          let n2 := f a in
          match le_lt_dec n1 n2 with
          | left _ => Some (n1, b)
          | right _ => Some (n2, a)
          end
      end
  end.

Theorem find_min_correct :
 forall l : list A,
 match find_min l with
 | None => l = []
 | Some (a, b) => (In b l /\ a = f b) /\ (forall c : A, In c l -> f b <= f c)
 end.
Proof using.
intros l; elim l; simpl in |- *; auto.
intros a l0; case (find_min l0); simpl in |- *.
intros p; case p; simpl in |- *.
intros n b ((H1, H2), H3); case (le_lt_dec n (f a)); simpl in |- *.
intros H4; split; auto.
intros c [H5| H5]; auto.
rewrite <- H2; rewrite <- H5; auto.
intros H4; split; auto.
intros c [H5| H5]; auto.
rewrite <- H5; auto.
apply le_trans with (f b); auto.
rewrite <- H2; auto with arith.
intros H; rewrite H; split; simpl in |- *; auto.
intros c [H1| H1]; rewrite H1 || case H1; auto.
Qed.

(* Search in the list for the max with respect to a valuation function f *)
Fixpoint find_max (l : list A) : option (nat * A) :=
  match l with
  | [] => None
  | a :: l1 =>
      match find_max l1 with
      | None => Some (f a, a)
      | Some (n1, b) =>
          let n2 := f a in
          match le_lt_dec n1 n2 with
          | right _ => Some (n1, b)
          | left _ => Some (n2, a)
          end
      end
  end.
 
Theorem find_max_correct :
 forall l : list A,
 match find_max l with
 | None => l = []
 | Some (a, b) => (In b l /\ a = f b) /\ (forall c : A, In c l -> f c <= f b)
 end.
Proof using.
intros l; elim l; simpl in |- *; auto.
intros a l0; case (find_max l0); simpl in |- *.
intros p; case p; simpl in |- *.
intros n b ((H1, H2), H3); case (le_lt_dec n (f a)); simpl in |- *.
intros H4; split; auto.
intros c [H5| H5]; auto.
rewrite <- H5; auto.
apply le_trans with (f b); auto.
rewrite <- H2; auto with arith.
intros H4; split; auto.
intros c [H5| H5]; auto.
rewrite <- H5; auto.
apply le_trans with (f b); auto.
rewrite <- H2; auto with arith.
intros H; rewrite H; split; simpl in |- *; auto.
intros c [H1| H1]; rewrite H1 || case H1; auto.
Qed.
 
End FindMin.
Arguments find_min [A].
Arguments find_max [A].
