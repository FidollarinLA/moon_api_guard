from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "output" / "pdf"
OUT_FILE = OUT_DIR / "OSC2026_moon_api_guard_项目申报书.pdf"


def p(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text.replace("\n", "<br/>"), style)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    base = "STHeitiLight"
    pdfmetrics.registerFont(TTFont(base, "/System/Library/Fonts/STHeiti Light.ttc"))
    pdfmetrics.registerFontFamily(
        base,
        normal=base,
        bold=base,
        italic=base,
        boldItalic=base,
    )

    styles = getSampleStyleSheet()
    title = ParagraphStyle(
        "TitleCN",
        parent=styles["Title"],
        fontName=base,
        fontSize=18,
        leading=22,
        spaceAfter=5,
        textColor=colors.HexColor("#1f2937"),
    )
    h2 = ParagraphStyle(
        "HeadingCN",
        parent=styles["Heading2"],
        fontName=base,
        fontSize=11,
        leading=13,
        spaceBefore=5,
        spaceAfter=2,
        textColor=colors.HexColor("#111827"),
    )
    body = ParagraphStyle(
        "BodyCN",
        parent=styles["BodyText"],
        fontName=base,
        fontSize=8.6,
        leading=11.2,
        spaceAfter=2,
        textColor=colors.HexColor("#1f2937"),
    )
    bullet = ParagraphStyle(
        "BulletCN",
        parent=body,
        leftIndent=10,
        firstLineIndent=-7,
        bulletIndent=0,
        spaceAfter=1,
    )

    doc = SimpleDocTemplate(
        str(OUT_FILE),
        pagesize=A4,
        rightMargin=13 * mm,
        leftMargin=13 * mm,
        topMargin=12 * mm,
        bottomMargin=12 * mm,
        title="moon_api_guard 项目申报书",
        author="OSC 2026 Applicant",
    )

    story = [
        p("moon_api_guard 项目申报书", title),
        p("<b>基本信息</b>", h2),
        p("项目名称：moon_api_guard：MoonBit API 兼容性守卫工具", body),
        p("参赛者：待填写　　联系方式：待填写", body),
        p("GitHub 仓库链接：待填写", body),
        p("GitLink 仓库链接：待填写", body),
        p("项目方向：MoonBit 工程基础设施 / API 兼容性与发布守卫工具", body),
        p("项目类型：原创项目，参考通用 API 兼容性检查思想，不直接移植特定开源项目。", body),
        p("<b>项目简介</b>", h2),
        p(
            "moon_api_guard 计划为 MoonBit 生态提供一个公共 API 兼容性守卫工具，基于 moon info 生成的 .mbti 接口描述，"
            "对比旧版和新版公开接口，识别删除 API、函数签名变化、类型 / trait / alias 变化等破坏性变更，"
            "区分兼容新增，并给出 SemVer 升级建议。项目服务于 mooncakes.io 发布前检查、PR API 审查、团队 CI 守卫和 OSC 项目验收前自查。",
            body,
        ),
        p("<b>核心功能范围</b>", h2),
    ]

    bullets = [
        "提供 ApiItem、ApiChange、ApiReport 等核心数据结构；",
        "解析和规范化 pkg.generated.mbti 中的函数、类型、结构体、枚举、trait、impl 和 alias；",
        "检测 API 删除、参数或返回类型变化、公开性收紧等破坏性变更；",
        "检测新增 public API 等兼容变更，并给出 major / minor / patch 的 SemVer 建议；",
        "输出终端摘要、Markdown 报告和 JSON 报告；",
        "提供 moon_api_guard check old.mbti new.mbti 命令和 GitHub Actions / GitLink CI 示例；",
        "提供 README 示例、可运行示例、核心测试，并在后续发布到 mooncakes.io。",
    ]
    for item in bullets:
        story.append(Paragraph(item, bullet, bulletText="-"))

    story.extend(
        [
            p("<b>实现计划</b>", h2),
            p(
                "2026-07-12：仓库改名、MoonBit 项目骨架、README、LICENSE、基础 API diff 数据结构和第一批测试；"
                "2026-07-13：完成 .mbti 轻量解析、函数 / 类型 / 结构体 / 枚举 / trait / alias 的基础差异分类；"
                "2026-07-14：完成 SemVer 建议、终端摘要、Markdown / JSON 报告；"
                "2026-07-15：补充 CLI、示例项目、GitHub Actions / GitLink CI 模板；"
                "2026-07-16 至 2026-07-17：按验收反馈补充测试、发布 mooncakes.io、完善 README 和工程质量。",
                body,
            ),
            p("<b>开源与合规说明</b>", h2),
            p(
                "本项目采用 Apache-2.0 License。项目为原创 MoonBit 实现，不复制第三方项目源码；概念上参考 Rust cargo-semver-checks、"
                "Java japicmp / revapi 等 API 兼容性检查工具，但输入格式、规则分类、CI 集成和发布流程面向 MoonBit .mbti 与 mooncakes.io 重新设计。"
                "当前公开查重未发现成熟同名或高度相似的 MoonBit 专用 API 兼容性守卫工具，但不能绝对排除未公开项目。",
                body,
            ),
            Spacer(1, 3),
            p("备注：提交前需将“待填写”替换为真实个人信息及 GitHub / GitLink 仓库链接。", body),
        ]
    )

    doc.build(story)
    print(OUT_FILE)


if __name__ == "__main__":
    main()
