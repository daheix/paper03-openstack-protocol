# Frozen Experiment Plan — Paper 3 (T2 protocolized gap)

Frozen 2026-10-03 (goal R8) **before any measurement**. Changes only via
commit + CHANGELOG.

## Model population

- Source library: `src/plugins/motor_workbench/models/library/` (1,690 files;
  1,621 valid per AGENTS.md 2026-10 calibration note; 69 excluded as invalid).
- Families: slot × pole matrix, 16 slot-families × 6 pole-counts, plus an
  eccentric fault family (ecc < air gap enforced).
- Solve chain: `run_emag_getdp.py --params --workdir` (Gmsh 4.15.2 meshing,
  GetDP 4.0.0 magnetostatics, P1), metrics: Bg1, THD, λm, torque, self-energies.

## Stratified sample (30)

- Strata = 16 slot-families; within stratum pick models spanning the pole
  range; oversample the eccentric family (3 models) for fault-relevant
  gradients: **27 regular + 3 eccentric**.
- Selection is deterministic: sort candidates by model id, take every
  ⌈N_stratum/allow⌉-th; seed 20261003 recorded; sampling script
  `scripts/sample_models.py` writes `data/sample30.json`.

## Ablation arms (each model, each metric of interest)

| Arm | Name | What runs | Output |
|---|---|---|---|
| A0 | bare | single default-mesh solve | metric value only |
| A1 | +mesh protocol | lc-air × {2.0, 1.0, 0.5} (3 levels) | 3 values + ratio table |
| A2 | +GCI | A1 + Richardson/GCI (3-point) | GCI%, observed order p, asymptotic flag |
| A3 | full protocol | A2 + Paper-2 arbitration (integral trio C1; ring band C2 where applicable) | verdict PASS/FAIL per metric |

- Mesh levels match the Paper-2 frozen sequence (lc_air 0.0020/0.001/0.0005
  for A1..A3 unless a model's default differs; default lc recorded per model).
- Wall time budget: ≤ 20 s/solve typical (2-core); per-model cap 300 s
  (timeout → record FAIL, never silently drop).

## Predictable-bound claim (to be tested, not assumed)

- H1: with A2, ≥ 90% of (model, metric) pairs reach the asymptotic regime
  (0.5 < p < 2.5 for P1) with GCI ≤ 5%.
- H2: full protocol A3 flags ≥ 95% of unreliable values (cross-checked
  against analytic anchors and Paper-2's eccentric family behaviour).
- Failure of H1/H2 is itself a publishable result (protocol boundary map).

## Analytic anchors (external, from Paper 2, same P1 kernel)

- A1 anchor: current-loaded disc, max err 0.917% (threshold 1%).
- A2 anchor: transversely magnetised cylinder, max err 0.66% (threshold 3%).
- Re-run at v0.2.0 to bind the anchor to this repo's environment.

## Threats to validity (pre-registered)

- No commercial-tool reference: claims are verification-grade (bounds, not
  truth); literature values used only as side evidence.
- Solver = one code path (P1); conclusions scoped to P1 linear magnetostatics.
- 30-model sample: family-level (not per-model) conclusions; stratification
  recorded to let readers reweight.

## Data release

`data/` receives per-arm CSVs (`results_arm{A0..A3}.csv`), the merged matrix
(`results_matrix.csv`), and `sample30.json`. Analysis scripts read CSVs only.


## 口径注记（2026-10-04）

样本于库=1,700 文件（1,523 常规/177 偏心）口径下抽取并冻结（v0.1.1，测量前）；上游库其后扩至 1,710（新增分数槽集中绕组族）。**冻结样本不变**——预注册纪律以抽样时刻快照为准，扩容模型不入本轮（记录于 engine_snapshot/CHANGELOG，供复现者对齐）。


## Amendment 1（2026-10-04 01:1x，测量早期）

**变更**：抽样健康分层——样本 v1 → sample30_v2.json（seed 不变 20261003）。
**判据（构造性，非结果性）**：q = n_slots/(3×pole_pairs) 须为整数。v1 中 12/30
（40%）为分数槽模型，P1 扇区口径下构造性退化（λm=0、T=0、Bg1 低一个量级，
实例：gen130-12s10p q=0.80、gen42-12s12p-hb1 q=0.67）——进入 GCI 统计将以构造
污染预注册门判定。健康池 1,262 模型按槽数族（6s…96s）轮转重抽 27 常规；
偏心 3 个本就健康，保持不变。
**正当性**：①修订发生在测量极早期（v1 完成仅 2/30，且 2 个均为退化族）；
②判据来自链的公开扇区约束，非任何测量结果挑选；③v1 样本与其 2 个退化模型
的全部数据保留并升格为论文"口径审计"节证据；④本节与 v1 采样同文件入档，
可复现脚本 data/sample30_v2.json 头部 rule 字段。
**影响**：H1/H2 门与全部分析协议不变，仅样本实现更换。

## Amendment 2（2026-10-04 01:2x，测量早期 <3/30 完成）

**变更**：v2 内替换 2 模型——gen107-90s12p、gen92-96s-rso44 → gen143-36s6p-hb8-rsi31、
gen101-ls8-so46（seed 家族延续 20261003+1）。
**判据（构造性）**：齿宽约束 2×slot_half_deg < 360°/n_slots——来自主项目已入档的
注记 11（上游 1750 口径批量改判 145 病态同源）。两模型齿宽恰好≥槽距整份，几何退化。
**正当性**：同 Amendment 1——早期、构造判据、非结果挑选、v2 前版与本节同档可溯。
**影响**：门与分析协议不变。

## 观察注记 O3（2026-10-04 02:4x，矩阵推进中）：第三病型

gen132-8p-hb2-sd15（48s8p, q=4）、gen136-rsi30-fix（36s8p, q=3）：**Bg1 健康**（0.888-0.910T，
与库标定逐位一致）但 T_avg/λm/λ₁ 全零。链执行正确（mid 臂与库 reference_metrics 位级一致）；
库仅标定 Bg1 → 该族机电转换失效从未被库 QC 发现。构造性（模型设计域问题，非协议误杀），
暂不改协议不换样本：30 模型跑完后统计病型3规模，若占比影响 H1 判定再启 Amendment 3
（候选处置：病型3模型从 H1 分母剔除，单列"Bg1-only calibration blind spot"节=论文核心证据）。
病型谱：①分数槽扇区退化（Bg1 也崩）②齿宽退化（几何）③Bg1-only 盲区（转换链零）。