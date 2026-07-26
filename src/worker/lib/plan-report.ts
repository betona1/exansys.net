// 앱기획 진단 결과를 문서로 내보낸다.
//  - report: 사람이 읽는 진단 보고서 (Markdown)
//  - techspec: 구현용 기술 명세 (Markdown, 기능 ID 포함)
// 모든 문서에 엔진·정책·스키마 버전을 기록해 "무엇으로 만든 판단인가"를 되짚을 수 있게 한다.

import {
  DIMENSION_LABELS,
  EVIDENCE_TYPE_LABELS,
  PIVOT_LABELS,
  type AnalysisResult,
  type EvidenceItem,
} from "./plan-engine";

function bullets(items: string[], empty = "_(없음)_"): string {
  if (!items.length) return empty;
  return items.map((i) => `- ${i}`).join("\n");
}

function fieldOr(value: string | null | undefined, fallback = "_(미입력)_"): string {
  return value && value.trim() ? value.trim() : fallback;
}

function metaFooter(result: AnalysisResult): string {
  const m = result.meta;
  return [
    "---",
    "",
    `> 판정 주체: **${m.engine} ${m.engineVersion}** · 정책 ${m.policyVersion} · 스키마 ${m.schemaVersion}`,
    `> 생성 시각: ${m.createdAt}`,
    m.modelName
      ? `> 구조화 초안 보조: ${m.modelProvider} / ${m.modelName} — 점수·신뢰도·피벗 판정에는 관여하지 않았습니다.`
      : "> 구조화 초안 보조: 사용하지 않음",
  ].join("\n");
}

/** 진단 보고서 (Markdown) */
export function buildReportMarkdown(result: AnalysisResult, evidence: EvidenceItem[] = []): string {
  const { idea, diagnosis, targets, mvp, pivot } = result;
  const lines: string[] = [];

  lines.push(`# ${fieldOr(idea.appName, "(이름 없는 아이디어)")} — 앱기획 진단 보고서`, "");

  // 결론 먼저
  lines.push("## 1. 결론", "");
  lines.push(`- **판단**: ${PIVOT_LABELS[pivot.decision]} (\`${pivot.decision}\`)`);
  if (pivot.wouldBeDecision) {
    lines.push(
      `- **근거가 충분했다면**: ${PIVOT_LABELS[pivot.wouldBeDecision]} (\`${pivot.wouldBeDecision}\`)`,
    );
  }
  lines.push(`- **총점**: ${diagnosis.totalScore.toFixed(1)} / 100`);
  lines.push(`- **근거 신뢰도**: ${(diagnosis.overallConfidence * 100).toFixed(0)}%`);
  lines.push("", `> ${pivot.rationale}`, "");
  lines.push(
    "이 판단은 규칙 엔진이 계산한 것이며 자동으로 적용되지 않습니다. 사람이 승인하거나 거절해야 합니다.",
    "",
  );

  // 지금 할 일
  lines.push("## 2. 지금 할 일", "", bullets(result.nextActions), "");

  // 치명 위험
  if (diagnosis.criticalRisks.length) {
    lines.push("## 3. 먼저 해소할 치명 위험", "", bullets(diagnosis.criticalRisks), "");
  }

  // 항목별 점수
  lines.push("## 4. 평가 항목", "");
  lines.push("| 항목 | 점수 | 가중치 | 환산 | 신뢰도 |");
  lines.push("|---|---:|---:|---:|---:|");
  for (const d of diagnosis.dimensions) {
    lines.push(
      `| ${d.code} ${d.label} | ${d.rawScore}/5 | ${d.weight} | ${d.normalizedScore.toFixed(1)} | ${(d.confidence * 100).toFixed(0)}% |`,
    );
  }
  lines.push("");
  for (const d of diagnosis.dimensions) {
    lines.push(`### ${d.code} ${d.label} — ${d.rawScore}/5`);
    lines.push(`- 산정 근거: ${d.reason}`);
    lines.push(`- 권장 행동: ${d.recommendedAction}`);
    if (d.missingEvidence.length) lines.push(`- 부족한 근거: ${d.missingEvidence.join(", ")}`);
    lines.push("");
  }

  // 경고
  lines.push("## 5. 경고", "");
  if (!diagnosis.warnings.length) {
    lines.push("_(발견된 경고 없음)_", "");
  } else {
    for (const w of diagnosis.warnings) {
      lines.push(
        `- **[${w.severity}] ${w.code}**${w.field ? ` (\`${w.field}\`)` : ""} — ${w.message}`,
      );
      if (w.recommendedAction) lines.push(`  - 권장: ${w.recommendedAction}`);
    }
    lines.push("");
  }

  // 유지 / 변경 / 삭제
  lines.push("## 6. 유지 · 변경 · 삭제", "");
  lines.push("### 유지", bullets(pivot.keep), "");
  lines.push("### 변경", bullets(pivot.change), "");
  lines.push("### 삭제", bullets(pivot.remove), "");

  // 타깃 후보
  lines.push("## 7. 타깃 후보", "", `> ${targets.recommendationReason}`, "");
  targets.candidates.forEach((c, i) => {
    const mark = targets.recommendedCandidateIndex === i ? " ⭐추천" : "";
    lines.push(`### 후보 ${i + 1}. ${c.name}${mark}`);
    lines.push(`- 사용자: ${fieldOr(c.user)}`);
    lines.push(`- 구매자: ${fieldOr(c.payer)}`);
    lines.push(`- 영향자: ${fieldOr(c.influencer)}`);
    lines.push(`- 발생 상황: ${fieldOr(c.triggerSituation)}`);
    lines.push(`- 문제: ${fieldOr(c.problem)}`);
    lines.push(`- 현재 대체 방법: ${fieldOr(c.currentAlternative)}`);
    lines.push(`- 기대 이유: ${c.whyPromising.join(" / ")}`);
    lines.push(`- 위험: ${c.risks.join(" / ")}`);
    lines.push(`- 검증 질문: ${c.validationQuestions.join(" / ")}`);
    lines.push(`- 권장 실험: ${c.recommendedExperiment}`);
    lines.push("");
  });

  // MVP
  lines.push("## 8. MVP 범위", "");
  lines.push(`- 핵심 가설: ${mvp.coreHypothesis}`);
  lines.push(`- 문제 가설: ${mvp.problemHypothesis}`);
  lines.push(`- 행동 가설: ${mvp.behaviorHypothesis}`);
  lines.push(`- 가치 가설: ${mvp.valueHypothesis}`);
  lines.push(`- 재방문 가설: ${mvp.retentionHypothesis}`);
  if (mvp.revenueHypothesis) lines.push(`- 수익 가설: ${mvp.revenueHypothesis}`);
  lines.push("", "### P0 (반드시)", bullets(mvp.p0Features), "");
  lines.push("### P1 (최소한만)", bullets(mvp.p1Features), "");
  lines.push("### 이번엔 제외", bullets(mvp.excludedFeatures), "");
  lines.push(`### 첫 성공 경험`, "", mvp.firstSuccessExperience, "");
  lines.push("### 핵심 사용자 흐름", "", mvp.coreUserFlow.map((s, i) => `${i + 1}. ${s}`).join("\n"), "");
  lines.push("### 측정 이벤트", "", bullets(mvp.metrics), "");

  // 근거
  lines.push("## 9. 등록된 근거", "");
  if (!evidence.length) {
    lines.push(
      "_(등록된 근거 없음 — 근거가 없으면 모든 항목의 신뢰도가 상한에 묶입니다.)_",
      "",
    );
  } else {
    lines.push("| 유형 | 제목 | 표본 | 지지 | 반박 |");
    lines.push("|---|---|---:|---|---|");
    for (const e of evidence) {
      lines.push(
        `| ${EVIDENCE_TYPE_LABELS[e.evidenceType]} | ${e.title} | ${e.sampleSize ?? "—"} | ${e.supports.join(", ") || "—"} | ${e.contradicts.join(", ") || "—"} |`,
      );
    }
    lines.push("");
  }

  // 언노운
  lines.push("## 10. 아직 모르는 것", "", bullets(diagnosis.unknowns), "");

  lines.push(metaFooter(result));
  return lines.join("\n");
}

/** 구현용 기술 명세 (Markdown) — 기능마다 ID를 붙여 개발 티켓으로 바로 쓸 수 있게 한다. */
export function buildTechspecMarkdown(result: AnalysisResult): string {
  const { idea, diagnosis, mvp, pivot } = result;
  const lines: string[] = [];

  const name = fieldOr(idea.appName, "(이름 없는 앱)");
  lines.push(`# TECHSPEC — ${name}`, "");
  lines.push(
    `> 이 문서는 진단 결과에서 자동 생성되었습니다. 판단 상태는 **${PIVOT_LABELS[pivot.decision]}** 이며,`,
    `> 총점 ${diagnosis.totalScore.toFixed(1)} / 근거 신뢰도 ${(diagnosis.overallConfidence * 100).toFixed(0)}% 기준입니다.`,
    "",
  );

  if (pivot.decision === "HOLD" || diagnosis.criticalRisks.length > 0) {
    lines.push("## ⚠️ 착수 전 확인", "");
    lines.push(
      pivot.decision === "HOLD"
        ? "- 근거 신뢰도가 기준 미만입니다. 이 명세대로 구현하기 전에 근거를 먼저 확보하세요."
        : "- 치명 위험이 남아 있습니다. 아래 항목을 먼저 해소하세요.",
    );
    lines.push(bullets(diagnosis.criticalRisks, "- (치명 위험 없음)"), "");
  }

  lines.push("## 1. 제품 정의", "");
  lines.push(`- 앱 이름: ${name}`);
  lines.push(`- 사용자: ${fieldOr(idea.targetUser)}`);
  lines.push(`- 구매자: ${fieldOr(idea.payer)}`);
  lines.push(`- 영향자: ${fieldOr(idea.influencer)}`);
  lines.push(`- 문제 상황: ${fieldOr(idea.problemSituation)}`);
  lines.push(`- 현재 대체 방법: ${fieldOr(idea.currentSolution)}`);
  lines.push(`- 대체 방법의 한계: ${fieldOr(idea.currentSolutionProblem)}`);
  lines.push(`- 핵심 행동: ${fieldOr(idea.coreAction)}`);
  lines.push(`- 기대 결과: ${fieldOr(idea.expectedResult)}`);
  lines.push(`- 유입 경로: ${fieldOr(idea.distributionChannel)}`);
  lines.push(`- 수익 모델: ${fieldOr(idea.revenueModel)}`, "");

  lines.push("## 2. 검증할 가설", "");
  lines.push(`- H-CORE: ${mvp.coreHypothesis}`);
  lines.push(`- H-PROBLEM: ${mvp.problemHypothesis}`);
  lines.push(`- H-BEHAVIOR: ${mvp.behaviorHypothesis}`);
  lines.push(`- H-VALUE: ${mvp.valueHypothesis}`);
  lines.push(`- H-RETENTION: ${mvp.retentionHypothesis}`);
  if (mvp.revenueHypothesis) lines.push(`- H-REVENUE: ${mvp.revenueHypothesis}`);
  lines.push("");

  lines.push("## 3. 기능 목록", "");
  lines.push("| ID | 우선순위 | 기능 | 완료 조건 |");
  lines.push("|---|---|---|---|");
  mvp.p0Features.forEach((f, i) => {
    lines.push(
      `| F-P0-${String(i + 1).padStart(2, "0")} | P0 | ${f} | 측정 이벤트가 기록되고 사용자가 끝까지 완료 |`,
    );
  });
  mvp.p1Features.forEach((f, i) => {
    lines.push(
      `| F-P1-${String(i + 1).padStart(2, "0")} | P1 | ${f} | 화면이 존재하고 실패 상태를 처리 |`,
    );
  });
  lines.push("");
  lines.push("### 이번 범위에서 제외", "", bullets(mvp.excludedFeatures), "");

  lines.push("## 4. 핵심 사용자 흐름", "");
  lines.push(mvp.coreUserFlow.map((s, i) => `${i + 1}. ${s}`).join("\n"), "");

  lines.push("## 5. 활성화 기준 (첫 성공 경험)", "", mvp.firstSuccessExperience, "");

  lines.push("## 6. 측정 이벤트", "");
  lines.push("| 이벤트 | 언제 기록 |");
  lines.push("|---|---|");
  lines.push("| `activation_complete` | 첫 성공 경험에 도달한 순간 |");
  lines.push("| `core_action_complete` | 핵심 행동을 끝까지 마친 순간 |");
  lines.push("| `day1_return` | 최초 진입 다음 날 재방문 |");
  lines.push("");
  lines.push("> 측정 이벤트가 연결되지 않은 기능은 이번 범위에 넣지 않습니다.", "");

  lines.push("## 7. 남은 위험과 언노운", "");
  lines.push("### 위험", bullets(mvp.risks, "- (치명 위험 없음)"), "");
  lines.push("### 아직 모르는 것", bullets(diagnosis.unknowns), "");

  lines.push(metaFooter(result));
  return lines.join("\n");
}
