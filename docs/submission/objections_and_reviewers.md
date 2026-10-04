# 预判审稿人 5 条质疑与回复预案

## Q1「75% 达标=协议失败，为什么还值得发表？」
回复：预注册的≥90% 门禁**按计划**落在失败分支；失败形态本身就是贡献——14 个失败全部是阶数出窗（p 中位 1.45、max 4.52），GCI 上界 0 一次突破（max 0.65%）。协议压差中位≤0.18% 说明裸算与全协议在可完成域内几乎同值，"边界在阶数窗口而非网格收敛"是可操作的工程结论。V&V 文献的发表价值在可复现的边界刻画，非在通过率。

## Q2「fine 臂 20/30 超时，75% 是流失后条件率」
回复：承认且已写入 Threats（Internal）：超时不可估 GCI，属 wall-time 边界的实测部分；300 s 是先验预算而非事后挑选；流失模型在 arms.csv 保留 FAIL 记录（never dropped）。诚实扩展=预算扫描，已列为 future work。

## Q3「H2 是循环定义（flag≡!h1_pass）」
回复：按定义性陈述处理，摘要与 Discussion 均已限定 "holds by construction"；其非平凡内容=25% 的标记率与每面旗携带的具体越界判据（p 窗/GCI 阈），供工程侧按判据分流，而非作为经验假设检验。

## Q4「P1 一阶单元+静磁场，结论外推性弱」
回复：Scope 明确声明 bounds 属于该类（P1 一阶磁静+单引擎快照）；阶数出窗在一阶元上反而更易暴露（渐近窗窄），这是保守方向的证据；跨阶外推列入 future work，不越界主张。

## Q5「单引擎单机计时，runtime 结论可信度」
回复：计时非本文主张（协议的"价格"用 per-solve 预算达标率表述，非绝对耗时）；300 s 预算先验固定；复现包锁定全部环境，他人可在同口径下复核。

---

# 推荐审稿人 3 名（真实学者，邮箱投稿时于系统核实补全）

| 学者 | 机构 | 理由 | 邮箱来源 |
|---|---|---|---|
| C. Geuzaine | University of Liège | Gmsh 一作；网格与求解器视角审协议 | liege.u SpinNNerd 官网公开（投稿时核实） |
| M. Kaltenbacher | TU Wien / Alberich | qnmag2025 一作（本稿引用）；非线性求解与 V&V | TU Wien 公开页（投稿时核实） |
| J.A. Malagoli | UFU（Brazil） | stack2024 一作（Gmsh/GetDP 电机转矩直接先例） | 通讯作者邮箱见 doi:10.1002/2050-7038.12773（投稿时核实） |

回避列表：无竞争关系个人；EMSE 编辑部与本稿无关。

# 合规声明（投稿系统按 Elsevier 模板填写）

- Declaration of interest: 无
- Funding: 自筹，无基金
- Generative AI: 按 Elsevier 政策如实声明"写作辅助（语言润色与草稿组织）+ 数值全部由锁定环境脚本产出，AI 未生成任何报告数值"
- Data Availability: github.com/daheix/paper03-openstack-protocol（tag v0.2.0，随稿引用）
