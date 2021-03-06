theory Chap7ex
  imports Main Chap7_2 Chap7_3
begin

fun assigned :: "com \<Rightarrow> vname set" where
"assigned SKIP = {}"
| "assigned (v ::= va) = {v}"
| "assigned (v;; va) = assigned v \<union> assigned va"
| "assigned (IF v THEN va ELSE vb) = assigned va \<union> assigned vb"
| "assigned (WHILE v DO va) = assigned va"

lemma "\<lbrakk> (c, s) \<Rightarrow> t; x \<notin> assigned c \<rbrakk> \<Longrightarrow> s x = t x"
  apply (induct rule: big_step_induct)
  by auto

fun skip :: "com \<Rightarrow> bool" where
"skip SKIP = True"
| "skip (v ::= va) = (\<forall>s. s v = aval va s)"
| "skip (v;; va) = (skip v \<and> skip va)"
| "skip (IF v THEN va ELSE vb) = (skip va \<and> skip vb)"
| "skip (WHILE v DO va) = (\<forall>s. \<not>bval v s)"

lemma "skip c \<Longrightarrow> c \<sim> SKIP"
  apply (induct c rule: skip.induct)
      apply simp_all
  using assign_simp apply auto
   apply (metis Seq Skip)
  by (meson Skip big_step.IfFalse big_step.IfTrue)
  
lemma skip_while_aux: "\<lbrakk> (WHILE b DO c, s) \<Rightarrow> s'; bval b s \<rbrakk> \<Longrightarrow> \<not>bval b s'"
  apply (induct "WHILE b DO c" s s' rule: big_step_induct)
  by blast+

lemma skip_while: "bval b s \<Longrightarrow> \<not>(WHILE b DO c \<sim> SKIP)"
text \<open>if the loop halts after n iterations, then @{term "(WHILE b DO c, s) \<Rightarrow> sn"} and since
@{term "bval b s \<noteq> bval b sn"}, @{term "s \<noteq> sn"}. otherwise, the loop never halts,
so for all t, @{term "(WHILE b DO c, s) \<Rightarrow> t"} does not hold.\<close> 
  using skip_while_aux by blast

lemma "WHILE b DO c \<sim> SKIP = skip (WHILE b DO c)"
  by (metis Chap7_2.SkipE Chap7_2.WhileE Skip WhileFalse skip.simps(5) skip_while_aux)

lemma "x ::= (V x) \<sim> SKIP"
  using assign_simp by auto

lemma "SKIP;; x ::= (V x) \<sim> SKIP"
  using assign_simp by auto

lemma
"let c1 = SKIP in
let c2 = x ::= Plus (V x) (N 1) in
IF (Bc True) THEN c1 ELSE c2 \<sim> SKIP"
  apply clarsimp
  by (metis Chap7_2.IfE big_step.IfTrue bval.simps(1)) 

lemma "c \<sim> SKIP \<Longrightarrow> skip c"
  apply (induction c)
      apply simp_all
     apply (metis Chap7_2.SkipE big_step.Assign fun_upd_idem_iff)
    prefer 3
    apply (meson Skip skip_while_aux)
  oops

fun skip' :: "com \<Rightarrow> bool" where
"skip' SKIP = True"
| "skip' (v ::= va) = False"
| "skip' (v;; va) = (skip' v \<and> skip' va)"
| "skip' (IF v THEN va ELSE vb) = (skip' va \<and> skip' vb)"
| "skip' (WHILE v DO va) = False"

lemma "skip' c \<Longrightarrow> c \<sim> SKIP"
  apply (induct c rule: skip'.induct)
      apply simp_all
  apply (metis Seq Skip imp_det)
  by (metis Chap7_2.IfE big_step.IfFalse big_step.IfTrue)

function (sequential) deskip :: "com \<Rightarrow> com" where
"deskip SKIP = SKIP"
| "deskip (v ::= a) = v ::= a"
| "deskip (SKIP;; p) = deskip p"
| "deskip (p;; SKIP) = deskip p"
| "deskip (p;; q) = (let (p', q') = (deskip p, deskip q) in 
if (p', q') = (p, q) then p;; q else deskip (p';; q'))"
| "deskip (IF b THEN p ELSE q) = IF b THEN deskip p ELSE deskip q"
| "deskip (WHILE b DO p) = WHILE b DO deskip p"
  by pat_completeness auto

lemma deskip_term_aux: "\<lbrakk> deskip_dom p; deskip p \<noteq> p \<rbrakk> \<Longrightarrow> size (deskip p) < size p"
  apply (induct rule: deskip.pinduct)
  apply (simp_all add: deskip.psimps)
  by force+

termination deskip
  apply (relation "measure size")
                      apply safe
                      apply (simp_all add: deskip.psimps)
                      apply (metis One_nat_def Suc_eq_plus1 com.size(8) deskip_term_aux)
  using deskip.psimps(24) deskip_term_aux apply fastforce
  using deskip.psimps(25) deskip_term_aux apply fastforce
                      apply (metis One_nat_def Suc_eq_plus1 com.size(8) deskip_term_aux)
                     apply (smt (verit, del_insts) Suc_eq_plus1 add.assoc add.commute add.left_commute add_0 add_strict_mono com.size(8) deskip_term_aux nat_add_left_cancel_less)
                    apply (smt (verit, del_insts) Suc_eq_plus1 add.assoc add.commute add_0 add_strict_mono com.size(8) deskip_term_aux nat_add_left_cancel_less)
                   apply (smt (z3) One_nat_def com.size(8) com.size(9) deskip.psimps(24) deskip_term_aux less_imp_of_nat_less of_nat_less_imp_less plus_1_eq_Suc zadd_int_left)
                  apply (smt (verit, ccfv_threshold) com.inject(3) com.size(8) com.size(9) deskip.psimps(24) deskip_term_aux int_ops(1) less_imp_of_nat_less of_nat_Suc of_nat_add of_nat_less_imp_less)
                 apply (smt (verit, ccfv_threshold) add.comm_neutral add.left_commute add_less_imp_less_right add_less_mono add_mono_thms_linordered_field(2) com.inject(4) com.size(10) com.size(8) deskip.psimps(25) deskip_term_aux less_SucI plus_1_eq_Suc)
                apply (metis One_nat_def Suc_eq_plus1 add.assoc add_strict_mono com.inject(4) com.size(10) com.size(8) deskip.psimps(25) deskip_term_aux nat_add_left_cancel_less plus_1_eq_Suc)
               apply (smt (verit, ccfv_threshold) Suc_eq_plus1 add.commute add.left_commute add_0 assigned.cases com.distinct(11) com.distinct(15) com.distinct(19) com.distinct(5) com.exhaust com.inject(3) com.size(8) com.size(9) deskip.psimps(24) deskip_term_aux nat_add_left_cancel_less)
              apply (smt (z3) One_nat_def com.inject(3) com.size(8) com.size(9) deskip.psimps(24) deskip_term_aux less_imp_of_nat_less of_nat_less_imp_less plus_1_eq_Suc zadd_int_left)
             apply (smt (z3) One_nat_def com.size(8) com.size(9) deskip.psimps(24) deskip_term_aux less_imp_of_nat_less of_nat_less_imp_less plus_1_eq_Suc zadd_int_left)
            apply (smt (verit, ccfv_SIG) add_diff_cancel_right' add_less_mono com.inject(3) com.size(9) deskip.psimps(24) deskip_term_aux less_diff_conv)
           apply (smt (verit, ccfv_threshold) add.comm_neutral add.left_commute add_le_cancel_left add_less_mono com.inject(3) com.size(9) deskip.psimps(24) deskip_term_aux linorder_not_less plus_1_eq_Suc)
          apply (smt (verit, ccfv_threshold) add_diff_cancel_right' add_less_mono com.inject(3) com.size(10) com.size(9) deskip.psimps(24) deskip.psimps(25) deskip_term_aux less_diff_conv)
         apply (smt (verit, ccfv_threshold) One_nat_def Suc_eq_plus1 add.assoc add_mono_thms_linordered_field(3) com.inject(4) com.size(10) com.size(9) deskip.psimps(24) deskip.psimps(25) deskip_term_aux nat_add_left_cancel_less not_less_eq order_less_imp_le plus_1_eq_Suc)
        apply (metis One_nat_def Suc_eq_plus1 Suc_less_eq com.inject(4) com.size(10) deskip.psimps(25) deskip_term_aux)
       apply (smt (verit, ccfv_threshold) One_nat_def Suc_eq_plus1 add_Suc_right add_diff_cancel_right' add_strict_mono com.inject(4) com.size(10) com.size(8) deskip.psimps(25) deskip_term_aux le_add2 less_diff_conv2)
      apply (smt (verit, ccfv_threshold) Suc_eq_plus1 add.assoc add.commute add_0 add_diff_cancel_right' add_strict_mono com.size(10) com.size(8) deskip.psimps(25) deskip_term_aux nat_add_left_cancel_less)
     apply (smt (z3) com.inject(4) com.size(10) com.size(9) deskip.psimps(24) deskip.psimps(25) deskip_term_aux less_imp_of_nat_less of_nat_less_imp_less zadd_int_left)
    apply (smt (verit, ccfv_threshold) add.commute add_diff_cancel_right' add_le_cancel_left add_less_mono com.inject(3) com.size(10) com.size(9) deskip.psimps(24) deskip.psimps(25) deskip_term_aux linorder_not_less)
   apply (smt (verit, del_insts) add_diff_cancel_right' add_less_mono com.inject(4) com.size(10) deskip.psimps(25) deskip_term_aux less_diff_conv)
  by (smt (verit, del_insts) add_less_imp_less_right add_mono_thms_linordered_field(2) add_mono_thms_linordered_field(5) com.inject(4) com.size(10) deskip.psimps(25) deskip_term_aux)

lemma "deskip (SKIP ;; WHILE b DO (x ::= a;; SKIP)) = WHILE b DO x ::= a"
  by simp

lemma "deskip ((SKIP;; SKIP);; (SKIP;; SKIP)) = SKIP"
  by simp

lemma "deskip c \<sim> c"
  apply (induction c rule: deskip.induct; clarsimp)
                      defer 8
                      defer 11
                      defer 20
                      prefer 19
                      apply (blast+)[14]
         apply ((meson Chap7_2.SeqE Seq)+)[7]
  using sim_while_cong by presburger

end