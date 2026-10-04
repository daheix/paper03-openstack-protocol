# Paper03 模拟审稿报告（S5）

- 稿件: manuscript/main.tex（draft v0.2，5 页，编译零 error 零未解析引用）
- 数字核验: scripts/verify_manuscript_numbers.py **47/47 PASS**（正文每个数字 vs summary30.csv/arms.csv/gci.csv/审计 note 重算断言）
- 审稿视角: V&V 方法学 + 电机工程 + 统计/复现性（体裁 #11 verification & validation study）
- 日期: 2026-10-04

## Major（处理记录）

| # | 审稿意见 | 处置 | 状态 |
|---|---|---|---|
| M1 | 56 配对来源未解释（30×6=180≠56） | RQ2 开头补固定链句：fine 完成 10 模型×6=60 候选，4 对因零臂无法估阶→56 | ✅ 已修 |
| M2 | fine 20/30 超时=样本流失，75.0% 是流失后条件率 | Threats/Internal 补充：流失是边界的一部分；诚实扩展是预算扫描而非放宽 | ✅ 已修 |
| M3 | H2 循环定义（flag 集≡p/GCI 证据集，同义反复不可证伪） | 摘要已写 "holds by construction"；Discussion/Construct 补限定：H2 是定义性陈述，内容是它标记的 25% 配对，价值在每面旗携带具体越界判据 | ✅ 已修 |

## Minor（处理记录）

| # | 审稿意见 | 处置 | 状态 |
|---|---|---|---|
| m1 | \date 仍 draft v0.1 | → v0.2 | ✅ 已修 |
| m2 | 引用仅 6 条，V&V 短文可接受但可加 GCI 跨域应用 | gate 文献表有 aerospace12100886(UQ4CFD)/jnm.3275(谐波平衡) 备选 | ⏳ S6 视刊补 |
| m3 | AI 使用声明/利益冲突/致谢缺 | article 类暂无该节；S6 按目标刊模板补 | ⏳ S6 |
| m4 | 捆绑求解器二进制 vs 技能标准"不拷二进制"表述 | engine snapshot 规范的一部分（自包含最小求解器），README 已说明；保持 | ✅ 记录性差异 |

## 结论

- Major 3 条全部真实修复（非措辞搪塞），修复后重编译+重核验均 PASS。
- 修订后判定：**模拟审稿通过（Major 清零）**，可进入 S6 投稿包。
