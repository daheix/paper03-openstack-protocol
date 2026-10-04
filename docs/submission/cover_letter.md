# Cover Letter — Paper 03（主投 Advances in Engineering Software）

> 三段式。日期投稿时填；随投稿系统 Comments 粘贴。

Dear Editors,

Open-source finite-element stacks are increasingly used for engineering
analysis, yet the precision actually achievable by a specific
Gmsh/GetDP combination on realistic electric-machine geometries has
been reported only anecdotally. We submitted 30 open-source motor
models (stratified across slot/pole combinations, loadings and
eccentricity holdouts) to a preregistered four-arm protocol --- bare
solve, then progressively adding a three-level mesh ladder, a
three-grid Richardson GCI gate, and an independent torque-metric
arbitration --- and measured both the accuracy gained and the runtime
paid at every step.

The preregistered 90% asymptotic-window gate is met by 75.0% of the 56
rated (model, metric) pairs; every failure is an out-of-window
observed convergence order, never a broken GCI bound (max 0.65%), and
the metric split localises the boundary precisely (flux linkages pass
10/10; harmonic-content THD 4/10). The arbitration step reconciles the
slope-ladder and sinusoidal-revolve torque pipelines on 8/8 models
where both complete. The paper therefore delivers what we believe is
the first quantified protocol-vs-bare offset map for this stack
(median |A1_fine−A0|/A0 <= 0.18% across four output metrics), together
with an honest attrition boundary: the fine arm completes within the
300 s per-solve budget for only 10 of 30 models, which is itself a
reported result rather than a silent exclusion. All numbers trace to
released CSVs, a locked reproduction package (Dockerfile,
requirements.lock, make build/run/verify, and a <=1% six-metric
acceptance gate) ships in the repository, and the protocol, sample and
gates were preregistered before the matrix ran.

This work fits the scope of Advances in Engineering Software as a
quantitative engineering-software methodology study with immediate
practical value to anyone reporting simulation numbers from open FE
stacks. The manuscript is original, has not been published and is not
under consideration elsewhere; all authors have approved the
submission. Suggested reviewers are listed in the submission system;
we have no conflicts of interest to declare.

Sincerely,
Shouchun Wu (Independent Researcher, daheix@163.com, ORCID 0009-0007-3577-2552)
