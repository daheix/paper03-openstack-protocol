# 投稿前检查清单（12 项）— Paper 03 状态

| # | 项 | 状态 | 证据 |
|---|---|---|---|
| 1 | 查重 <15% 单源 <3% | ✅ 自查 | vs paper02 8-gram 重叠 0.00%（review_p03_sim.md）；外部以刊方 Crossref Check 为准 |
| 2 | 期刊体裁匹配+分区复核 | ✅ | #11 链：AES→COMPEL→SCTS→CMM（题目库 10 号文档）；AES=工程软件方法论对口 |
| 3 | 标题式+摘要 150–250 词量化收尾无引用 | ✅ | 摘要 218 词含量化收尾（75.0%/25.0%/0.18%） |
| 4 | 贡献 3 条；每 RQ 有检验；Threats 齐全 | ✅ | 3 粗体贡献；RQ1/RQ2/RQ3 各带量化判据；Threats 四段 |
| 5 | 占位符=0；数字可溯源；H 标注假设 | ✅ | verify_manuscript_numbers.py 47/47 PASS |
| 6 | 引用真实可查；编译零 error 零 warning 未解析 | ✅ | 6 条 bib（2 条 Crossref 回填）；pdflatex 5 页 0 未解析 |
| 7 | 语言润色 | ✅（自查档） | S4 按英文规则写作；投稿前用户可再过一轮母语者润色 |
| 8 | 模拟审稿 Major 清零 | ✅ | review_p03_sim.md：M1–M3 全部真实修复 |
| 9 | 复现包验收 | ✅* | host 实跑 verify PASS 6/6 ≤1%；docker build 待用户环境（README 已诚实标注） |
| 10 | cover letter 三段+highlights+graphical+预判 5 质疑 | ✅ | submission/cover_letter.md + highlights.txt + objections_and_reviewers.md；graphical 源图=figures/fig_boundary.pdf |
| 11 | 合规：Data Availability/AI 声明/ORCID/审稿人 3+回避 | ✅ | Data Availability 节；AI 声明按 Elsevier 政策（见 objections 文件）；ORCID 0009-0007-3577-2552；审稿人 3 名待邮箱核实 |
| 12 | 稿件归档+投稿记录+索引同步 | ✅ | sci/paper03_protocol/（main.tex 归档）；01_已投稿记录.md 已加行；sync_private.sh 同步 |

**判定：12/12 就绪（第 9 项 docker 验收与第 11 项审稿人邮箱两处待用户侧动作，均已标注）。**
