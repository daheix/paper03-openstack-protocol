# Changelog

## v0.1.1 — 2026-10-03
- Deterministic stratified sampler (scripts/sample_models.py, --lib runtime
  arg) + data/sample30.json: population 1,700 files (1,523 regular / 177
  eccentric), 96 slot×pole strata, 27 regular + 3 eccentric picked.

## v0.1.0 — 2026-10-03
- Repo skeleton: README (Series · Paper 3), frozen experiment plan
  (30-model stratified × 4-arm ablation, seed 20261003), gap evidence,
  CITATION.cff. No measurements yet.

## [v0.2.0-rc1+] — 2026-10-04
### Added
- 引擎快照闭包 `engine/`（来源 35ddd14e1 + SHA-256 清单）；出图脚本 `gen_figures.py`；数据字典 `docs/RESULTS_SCHEMA.md`
- 手稿静态骨架（数值 PENDING）；Calibration-vs-standard-chain 审计节
### Fixed
- 驱动器健壮性：CalledProcessError 捕获记 FAIL；GCI 段 3 解门槛；CSV 列=全行键并集
### Changed
- **Amendment 1**：抽样健康分层（q=n_slots/(3·pole_pairs) 整数判据；v1 之 40% 分数槽构造退化；sample30_v2.json seed 不变；v1 留档审计）
### Data
- v1 退化案例释放：gen130-12s10p（Bg1 −20% vs 库标定）、gen42-12s12p-hb1（λm=0）
