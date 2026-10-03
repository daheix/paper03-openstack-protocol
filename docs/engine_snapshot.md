# 引擎快照清单（快照纪律③：原始工程零改动，副本独立演进）

- 来源: src/plugins/motor_workbench/ @ 主仓 commit `35ddd14e15ed829c4df004e5cecdb088f3bb6631`
- 快照时间: 2026-10-03T15:55:54Z
- 补充快照 (R10 修正): fem_check.py + solver.par (run_emag_getdp.py 延迟 import 闭包补齐)
- 补丁: generate_geo.py lc_air/lc_iron/lc_shaft 参数化（DEFAULTS+write_geo 2 处）+ constants/motor_design.json 白名单 3 键 —— 唯一与原始工程的差异，服务 Paper 3 网格协议臂 A1/A2/A3

| 文件 | sha256 |
|---|---|
| ./constants/materials.json | 5ed2c9f7d88b1a78… |
| ./constants/motor_design.json | 8a8d160d906146f9… |
| ./constants/operating_conditions.json | e3a08227f7d0a744… |
| ./constants/physics.json | a074238dc7a29a6a… |
| ./simulation/getdp/a_map.pos | 15830dd89c3abe5c… |
| ./simulation/getdp/generate_geo.py | 9528288e2897d3c6… |
| ./simulation/getdp/load_constants.py | 5bac7aaaa80bbd74… |
| ./simulation/getdp/motor_groups.pro | d4b7c4fd05088cfa… |
| ./simulation/getdp/motor_mag_data.pro | 878f43e3725c4bc6… |
| ./simulation/getdp/motor_mag.pro | ab2feeea643aa560… |
| ./simulation/getdp/__pycache__/load_constants.cpython-312.pyc | a579e0f9aed4997e… |
| ./simulation/getdp/run_emag_getdp.py | 659db8cd837bcf8d… |
| ./simulation/getdp/temp_spec.json | 32be44ffff19fff6… |
| ./simulation/getdp/temp_spec.py | 6459c5cfa247ad9b… |
